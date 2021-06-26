#include <stdio.h>
#include <iostream>
#include <float.h>

#define tile 4096

__global__ void sdt_gpu(unsigned char * bitmap,int sz_edge, int* edge_pixels, float *sdt, int width, int height)
{
  __shared__ int s[tile];
  int tx = threadIdx.x;
  int bx = blockIdx.x;
  int bdx = blockDim.x;
  int global_idx = bx * bdx + tx;

  int iter_on_edge_pixels = (sz_edge + tile - 1)/tile;
  float min_dist, dist2;
  float _x, _y;
  float sign;
  float dx, dy;
  int x, y, k;

  min_dist = FLT_MAX;

  for (int p=0;p<iter_on_edge_pixels;p++){
    int base = p*tile;
    //to handle iterations on shared memory
    //if sz_edge is smaller; iterate till sz_edge
    //else tile
    int end = tile;
    if (sz_edge<base+end){
      end=sz_edge%tile;
    }

    // if sz_edge is smaller
    // if (tx<sz_edge) s[tx] = edge_pixels[base+tx];
    for (int i=0;i<tile;i+=bdx){

      if (base+i+tx<sz_edge) s[i+tx] = edge_pixels[base+i+tx];
    }
    __syncthreads();

    if (global_idx<height*width){
      x = global_idx%width;
      y = global_idx/width;
      for (k=0;k<end;k++){
        int q = s[k]; //bank conflicts but same data is fetched
        _x = q%width;
        _y = q/width;
        dx = _x-x;
        dy =_y-y;
        dist2 = dx*dx + dy*dy;
        if (dist2<min_dist) min_dist=dist2; 
      }
    }
    __syncthreads();
  }
  sign = (bitmap[global_idx] >= 127)? 1.0f : -1.0f;
  sdt[global_idx] = sign * sqrtf(min_dist);

}


extern "C" void run_sampleKernel(unsigned char * bitmap, float *sdt, int width, int height)
{
  unsigned char * d_bitmap;
  float * d_sdt;
  int *d_edge;

  cudaMalloc((void**)&d_bitmap, height*width*sizeof(unsigned char));
  cudaMalloc((void**)&d_sdt, height*width*sizeof(float));

  cudaMemcpy(d_bitmap,bitmap, height*width*sizeof(unsigned char),cudaMemcpyHostToDevice);

  // INITIALIZING OUTPUT IMAGE SPACE IN DEVICE MEMORY

  int sz = width*height;
  int sz_edge = 0;
  for(int i = 0; i<sz; i++) if(bitmap[i] == 255) sz_edge++;
  int *edge_pixels = new int[sz_edge];
  for(int i = 0, j = 0; i<sz; i++) if(bitmap[i] == 255) edge_pixels[j++] = i;
  std::cout<< "\t"<<sz_edge << " edge pixels in the image of size " << width << " x " << height << "\n"<<std::flush;
  cudaMalloc((void**)&d_edge,sz_edge*sizeof(int));
  cudaMemcpy(d_edge, edge_pixels, sz_edge*sizeof(int), cudaMemcpyHostToDevice);
  std::cout<<"Calling kernel"<<std::endl;


  cudaEvent_t start_gpu, end_gpu;
  float msecs_gpu;
  cudaEventCreate(&start_gpu);
  cudaEventCreate(&end_gpu);
  cudaEventRecord(start_gpu, 0);


  sdt_gpu<<<(sz+1024-1)/1024, 1024>>>(d_bitmap,sz_edge, d_edge, d_sdt,width,height);

  cudaDeviceSynchronize();


  cudaEventRecord(end_gpu, 0);
  cudaEventSynchronize(end_gpu);
  cudaEventElapsedTime(&msecs_gpu, start_gpu, end_gpu);
  cudaEventDestroy(start_gpu);
  cudaEventDestroy(end_gpu);
  std::cout<<"\tComputation took "<<msecs_gpu<<" milliseconds.\n";
  cudaMemcpy(sdt, d_sdt, sz*sizeof(float),cudaMemcpyDeviceToHost);
  cudaFree(d_sdt);
  cudaFree(d_edge);
  cudaFree(d_bitmap);
  free(edge_pixels);
}