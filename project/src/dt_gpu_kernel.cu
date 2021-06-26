#include <float.h>
#include <stdio.h>
#include <vector>
#include <iostream>
#include <fstream>
#include <thrust/scan.h>
#include "helper.h"

using std::ofstream;

__global__ void translateAndMapPixels(int* map, int num_pixel, float* points, int n_points, float minX, float minY, int cols)
{
	int idx = blockIdx.x*blockDim.x+threadIdx.x;
	if (idx < n_points){
		int x = (int)(points[2*idx]-minX+1.0);
		int y = (int)(points[2*idx+1]-minY+1.0);
		if (x<0 || y<0)
			printf("(%i,%i) Point outside grid\n",x,y);
		else if (y*cols+x < num_pixel){
			map[y*cols+x] = idx;
		}
	}
}

__global__ void voronoiDiagram(int* map, int rows, int cols, float* points, int n_points, int stepsize)
{
	int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
	int idx = 0;
    if (x<cols && y<rows){
    	int dx[] = {-1,0,1};
    	int dy[] = {-1,0,1};
    	idx = map[y*cols+x];
    	for (int i=0; i<3; ++i){
    		for (int j=0; j<3; ++j){
    			if (i==0 && j==0)
    				continue;	
				int nx = x+dx[i]*stepsize, ny = y+dy[j]*stepsize;
				if (nx>=cols || nx<0 || ny>=rows || ny<0)
					continue;
				int nIdx = map[ny*cols+nx];
				if (nIdx == -1)
					continue;
				if (idx == -1)
					idx = nIdx;
				else{
					int xd2 = points[2*nIdx]-x, yd2 = points[2*nIdx+1]-y;
					int xd1 = points[2*idx]-x, yd1 = points[2*idx+1]-y;
					if (xd2*xd2+yd2*yd2 <= xd1*xd1+yd1*yd1)
						idx = nIdx;
				}
    		}
    	}
    }
	__syncthreads();
	if (x<cols && y<rows)
		map[y*cols+x] = idx;
}

__global__ void count_triangles(int* map, int rows, int cols, int* count){
	int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    if (x<cols-1 && y<rows-1){
    	int a = map[y*cols+x], b = map[y*cols+x+1], c = map[(y+1)*cols+x], d = map[(y+1)*cols+x+1], val=0;
    	if (a!=b && b!=c && a!=c && a!=d && b!=d && c!=d)
			val = 2;	
		else if ((a!=b && b!=c && a!=c)||(a!=d && d!=c && a!=c)||(b!=d && d!=c && b!=c))
			val = 1;
		count[y*cols+x] = val;
    }
}

__global__ void triangulate(int* map, int* count, int* total_cnt, int rows, int cols, int* triangles, int n_triangles){
	int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    if (x<cols-1 && y<rows-1){
    	int val = count[y*cols+x];
    	if (val > 0){
	    	int id = total_cnt[y*cols+x];
	    	int a=map[y*cols+x], b=map[y*cols+x+1], c=map[(y+1)*cols+x], d=map[(y+1)*cols+x+1];
	    	if (val == 1){
	    		if (a==b)	b=c;
				if (b==c)	c=d;
	    		triangles[3*id] = a;
	    		triangles[3*id+1] = b;
	    		triangles[3*id+2] = c;
	    	}
	    	else if (val == 2){
	    		triangles[3*id] = a;
	    		triangles[3*id+1] = b;
	    		triangles[3*id+2] = c;
	    		triangles[3*id+3] = b;
	    		triangles[3*id+4] = c;
	    		triangles[3*id+5] = d;
	    	}
    	}
    }
}

void computeDT_GPU_(float* points, int n_points, float* bounds, int* triangles, int &n_triangles)
{
	int threads = 32;
	float minX = bounds[0], minY = bounds[1], maxX = bounds[2], maxY = bounds[3];

	int rows = (int)(maxY-minY+2);
	int cols = (int)(maxX-minX+2);

	int *d_map, *tri_count, *total_cnt, *d_triangles;
	float *d_points;

	cudaEvent_t start_1, stop_1;
	cudaEventCreate(&start_1);
	cudaEventCreate(&stop_1);
	cudaMalloc((void**)&d_map, rows*cols*sizeof(int));
	cudaMalloc((void**)&d_points, 2*n_points*sizeof(float));

	cudaMemcpy(d_points, points, 2*n_points*sizeof(float), cudaMemcpyHostToDevice);
	cudaMemset(d_map, -1, rows*cols*sizeof(int));

	translateAndMapPixels<<<(n_points+threads-1)/threads, threads>>>(d_map, rows*cols, d_points, n_points, minX, minY, cols);
	cudaDeviceSynchronize();
	

	dim3 blockDim(threads,threads);
	dim3 gridDim((cols+threads-1)/threads,(rows+threads-1)/threads);

	int stepsize = np2(min(rows,cols))/2;
	cudaEventRecord(start_1);
	while (stepsize >= 1){
		voronoiDiagram<<<gridDim, blockDim>>>(d_map, rows, cols, d_points, n_points, stepsize);
		cudaDeviceSynchronize();
		stepsize /= 2;
	}
	cudaEventRecord(stop_1);

	int *map = (int*)malloc(sizeof(int)*rows*cols);
	cudaMemcpy(map, d_map, sizeof(int)*rows*cols, cudaMemcpyDeviceToHost);
	ofstream outdata; // outdata is like cin
	outdata.open("gpu.txt"); // opens the file
	if( !outdata ) { // file couldn't be opened
		std::cerr << "Error: file could not be opened" << endl;
		exit(1);
	}
	else{
		for (int i = 0; i < rows; ++i){
			for (int j = 0; j < cols; ++j)
				outdata << map[i*cols+j] <<",";
			outdata << "\n";
		}
		outdata.close();
	}

	cudaMalloc((void**)&tri_count, rows*cols*sizeof(int));
	count_triangles<<<gridDim, blockDim>>>(d_map, rows, cols, tri_count);
	cudaDeviceSynchronize();
	

	cudaMalloc((void**)&total_cnt, rows*cols*sizeof(int));
	thrust::inclusive_scan(thrust::device, tri_count, tri_count + rows*cols, total_cnt);
	cudaDeviceSynchronize();
	cudaMemcpy(&n_triangles, &total_cnt[rows*cols-1], sizeof(int), cudaMemcpyDeviceToHost);

	cudaEventSynchronize(stop_1);


	cudaMalloc((void**)&d_triangles, 3*n_triangles*sizeof(int));
	triangles = (int*)malloc(3*n_triangles*sizeof(int));
	
	triangulate<<<gridDim, blockDim>>>(d_map, tri_count, total_cnt, rows, cols, d_triangles, n_triangles);
	cudaDeviceSynchronize();
	cudaMemcpy(triangles, d_triangles, 3*n_triangles*sizeof(int), cudaMemcpyDeviceToHost);

	float ms_1 = 0;
	cudaEventElapsedTime(&ms_1, start_1, stop_1);
	printf("Computation took %f milliseconds on GPU.\n",ms_1);

	cudaFree(d_points);	
	cudaFree(d_map);
	cudaFree(tri_count);
	cudaFree(total_cnt);
	cudaFree(d_triangles);
}


