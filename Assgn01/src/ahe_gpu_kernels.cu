// Author: Amandeep Kaur (2018014)
// As part of assignment 1 in CSE:560 GPU computing course
// Code adapted from given code file ahe_cpu.cpp provided by Prof. Ojaswa Sharma

#include <stdio.h>
#include <iostream>
#include <time.h>

#define TILE_SIZE_X 1024
#define TILE_SIZE_Y 1024

__constant__ unsigned char const_mappings[65536];

__global__ void findEqualizationMappings(unsigned char* img_in, int width, int height, unsigned char *mappings, int *pdf, int *cdf)
{
	int ntiles_x = (width / TILE_SIZE_X);

	int ty = threadIdx.y;
	int tx = threadIdx.x;
	int by = blockIdx.y;
	int bx = blockIdx.x;

	int row = by * blockDim.y + ty;
    int col = bx * blockDim.x + tx;
    
    if (row<height && col<width){
		int tile_i = (col)/TILE_SIZE_X; //0-indexed
		int tile_j = (row)/TILE_SIZE_Y;
		int offset = 256*(tile_i + tile_j * ntiles_x);
		atomicAdd(&pdf[offset + img_in[col+row*width]],1);
		__syncthreads();

		if ((row+1)%TILE_SIZE_Y==0 && (col + 1)%TILE_SIZE_X==0){ //one thread from each block
			int cdf_min = TILE_SIZE_X*TILE_SIZE_Y+1; // minimum non-zero value 
			cdf[offset]=pdf[offset];
			for(int i=1; i< 256; i++)
				cdf[offset+i] = cdf[offset+i-1] + pdf[offset+i];
			for(int i=0; i<256; i++)
				if(cdf[offset+i] != 0) {cdf_min = cdf[offset+i]; break;}
		
			for (int i=0;i<256;i++){
				mappings[i + offset] = (unsigned char)round(255.0 * float(cdf[offset+i] - cdf_min)/float(TILE_SIZE_X*TILE_SIZE_Y - cdf_min));
				}
			}
	}
}

__global__ void performAdaptiveEqualization(unsigned char* img_in, unsigned char* img_out, int width, int height){

	int ntiles_x = (width / TILE_SIZE_X);
	int ntiles_y = (height / TILE_SIZE_Y);

	int ty = threadIdx.y;
	int tx = threadIdx.x;
	int by = blockIdx.y;
	int bx = blockIdx.x;

	int row = by * blockDim.y + ty;
    int col = bx * blockDim.x + tx;

    if (row<height && col<width){

		// FINDING TILE CENTERS FOR INTERPOLATION
		int tile_i0, tile_j0, tile_i1, tile_j1;
		tile_i0 = (col - TILE_SIZE_X/2) / TILE_SIZE_X;
		if(tile_i0 < 0) tile_i0 = 0;
		tile_j0 = (row - TILE_SIZE_Y/2) / TILE_SIZE_Y;
		if(tile_j0 < 0) tile_j0 = 0;
		tile_i1 = (col + TILE_SIZE_X/2) / TILE_SIZE_X;
		if(tile_i1 >= ntiles_x) tile_i1 = ntiles_x - 1;
		tile_j1 = (row + TILE_SIZE_Y/2) / TILE_SIZE_Y;
		if(tile_j1 >= ntiles_y) tile_j1 = ntiles_y - 1;

		// OFFSETS IN INTERMEDIATE ARRAYS CORRESPONDING TO TILE CENTERS
		int offset00 = 256*(tile_i0 + tile_j0*ntiles_x);
		int offset01 = 256*(tile_i0 + tile_j1*ntiles_x);
		int offset10 = 256*(tile_i1 + tile_j0*ntiles_x);
		int offset11 = 256*(tile_i1 + tile_j1*ntiles_x);

	    unsigned char v00, v01, v10, v11;
		v00 = const_mappings[img_in[col+row*width] + offset00];
		v01 = const_mappings[img_in[col+row*width] + offset01];
		v10 = const_mappings[img_in[col+row*width] + offset10];
		v11 = const_mappings[img_in[col+row*width] + offset11];

		float x_frac = float(col - tile_i0*TILE_SIZE_X - TILE_SIZE_X/2)/float(TILE_SIZE_X);
		float y_frac = float(row - tile_j0*TILE_SIZE_Y - TILE_SIZE_Y/2)/float(TILE_SIZE_Y);
		
		//PERFORMING BILINEAR INTERPOLATION
	  	float v0 = v00*(1 - x_frac) + v10*x_frac;
		float v1 = v01*(1 - x_frac) + v11*x_frac;
	    float v= v0*(1 - y_frac) + v1*y_frac;

		if (v < 0) v = 0;
		if (v > 255) v = 255;

	    img_out[col+row*width] = (unsigned char)(v);
	}
}

extern "C" void run_sampleKernel(unsigned char* img_in, unsigned char* img_out, int width, int height)
{
  int ntiles_x = (width / TILE_SIZE_X);
  int ntiles_y = (height / TILE_SIZE_Y);
  int ntiles = (ntiles_x * ntiles_y);

// INITIALIZING REQUIREMENTS
  int *dpdf;
  int *dcdf;
  cudaMalloc((void**)&dpdf, 256*ntiles*sizeof(int));
  cudaMalloc((void**)&dcdf, 256*ntiles*sizeof(int));
  cudaMemset(dpdf, 0, 256*ntiles*sizeof(int));
  unsigned char *dmappings;
  cudaMalloc((void**)&dmappings, 256*ntiles*sizeof(unsigned char));

// WRITING INPUT IMAGE TO DEVICE MEMORY
  unsigned char * dimg_in;
  cudaMalloc((void**)&dimg_in, height*width*sizeof(unsigned char));
  cudaMemcpy(dimg_in,img_in, height*width*sizeof(unsigned char),cudaMemcpyHostToDevice);
  
// INITIALIZING OUTPUT IMAGE SPACE IN DEVICE MEMORY
  unsigned char * dimg_out;
  cudaMalloc((void**)&dimg_out, height*width*sizeof(unsigned char));

// SETTING UP LAUNCH CONFIGURATION
  dim3 grid,block;
  block.x = 32;
  block.y = 32;
  int req = (height*width)/(32*32);
  grid.x = pow(req,0.5);
  grid.y = pow(req,0.5);

// TIMER
cudaEvent_t start, stop;
cudaEventCreate(&start);
cudaEventCreate(&stop);
cudaEventRecord(start);

  //STEP 1
  findEqualizationMappings<<<grid,block>>>(dimg_in, width, height, dmappings, dpdf, dcdf);
  
 // cudaDeviceSynchronize();
 
 // COPYING MAPPINGS TO CONST_MAPPINGS (TO USE CONSTANT MEMORY)
 int *mappings;
 mappings = (int *)malloc(256*ntiles*sizeof(unsigned char));
 cudaMemcpy(mappings, dmappings, 256*ntiles*sizeof(unsigned char),cudaMemcpyDeviceToHost);
 cudaMemcpyToSymbol(const_mappings, mappings, ntiles*256*sizeof(unsigned char));

//STEP 2
  performAdaptiveEqualization<<<grid,block>>>(dimg_in, dimg_out, width, height);

cudaDeviceSynchronize();
cudaEventRecord(stop);

// WRITING OUTPUT IMAGE TO HOST MEMORY  
  cudaMemcpy(img_out, dimg_out, height*width*sizeof(unsigned char),cudaMemcpyDeviceToHost);

cudaEventSynchronize(stop);
float milliseconds = 0;
cudaEventElapsedTime(&milliseconds, start, stop);
std::cout  << "Time taken : " << milliseconds << std::endl;

// CLEANUP
  cudaFree(dpdf);
  cudaFree(dcdf);
  cudaFree(dmappings);
  cudaFree(dimg_out);
  cudaFree(dimg_in);
  cudaFree(const_mappings);
}
