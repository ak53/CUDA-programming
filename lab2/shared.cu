#include <iostream>
#include <stdio.h>
#include <time.h>


//#define LENGTH 100
//#define rowA 4
//#define colA 1
//#define rowB 1
//#define colB 4
#define w 100
#define tw 10
//#define TILE_BLOCKS 10
//#define TILE_WIDTH 100

using namespace std;

__global__ void mat_mult_simple(int (*a)[w], int (*b)[w], int (*c)[w]){
        int row = blockIdx.y * blockDim.y + threadIdx.y;
        int col = blockIdx.x * blockDim.x + threadIdx.x;

        int result = 0;

        for (int i=0;i<w;i++){
                result += (a[row][i] * b[i][col]);
        }

        c[row][col] = result;
}

__global__ void mat_mult_shared(int (*a)[w], int (*b)[w], int (*c)[w]){
    __shared__ int s_a[tw][tw];
	__shared__ int s_b[tw][tw];
	
	int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;
	
	int ty = threadIdx.y;
	int tx = threadIdx.x;

    int result = 0;
	
	for (int p=0;p<w/tw;p++){
		s_a[ty][tx] = a[row][p*tw+tx];
		s_b[ty][tx] = b[p*tw+ty][col];
		__syncthreads();

		for (int k=0;k<tw;k++){
			result += s_a[ty][k] * s_b[k][tx]; 
			__syncthreads();
		}	
	c[row][col] = result;
	}
}

int main(){

        int (*a)[w];
        int (*b)[w];
        int (*c)[w];

        int (*d_a)[w], (*d_b)[w], (*d_c)[w];
        //int *h_c;

        //int a_mat[rowA][colA] = {{0},{1},{2},{3}};
        //int b_mat[rowB][colB] = {0,1,2,3};
        //int c_mat[rowA][colB] = {};

        a = (int(*)[w])malloc(w * w *sizeof(int));
        b = (int(*)[w])malloc(w * w *sizeof(int));
        //h_c = (int*)malloc(rowA * colB * sizeof(int));



        for(int i=0 ; i< w; i++){
                for (int j=0;j<w;j++){
                        a[i][j] = 1;
                        b[i][j] = 1;
                }
        }


        cudaMalloc((void**)&d_a, w*w*sizeof(int));
        cudaMalloc((void**)&d_b, w*w*sizeof(int));
        cudaMalloc((void**)&d_c, w*w*sizeof(int)); // host -> device

        c = (int(*)[w])malloc(w*w*sizeof(int)); //cpu device -> host

        cudaMemcpy(d_a, a, w*w*sizeof(int), cudaMemcpyHostToDevice);
        cudaMemcpy(d_b, b, w*w*sizeof(int), cudaMemcpyHostToDevice);

        cudaEvent_t start, stop;
        cudaEventCreate(&start);
        cudaEventCreate(&stop);

        
        dim3 grid;
        grid.x = w/tw;
        grid.y = w/tw;
        dim3 block;
	block.x = tw;
        block.y = tw;
        cudaEventRecord(start);
	//mat_mult_simple<<<grid,block>>>(d_a, d_b, d_c);
	mat_mult_shared<<<grid,block>>>(d_a, d_b, d_c);

        cudaDeviceSynchronize();

        cudaEventRecord(stop);


        cudaMemcpy(c, d_c, w*w*sizeof(int), cudaMemcpyDeviceToHost);

        cudaEventSynchronize(stop);

        float milliseconds = 0;
        cudaEventElapsedTime(&milliseconds, start, stop);


        for(int i=0; i<w ;i++){
        //        for (int j=0;j<w;j++){
       	                std::cout << c[99][i]<<"   ";
        //         }
                std::cout<<std::endl;
        }

        std::cout  << "Time taken : " << milliseconds << std::endl;
}


