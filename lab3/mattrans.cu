// Author: Amandeep Kaur (2018014)
// As part of Lab3 in CSE:560 GPU computing course

#include<bits/stdc++.h>
using namespace std;

#define size 10000
#define bs 16
#define mem_row 8

__global__ void trans(int* mat, int* transmat){
	int row = blockDim.y * blockIdx.y + threadIdx.y;
	int col = blockDim.x * blockIdx.x + threadIdx.x;
	if (row<size && col<size){
		// for (int i=0;i<bs;i+=mem_row){
			transmat[(row) + size*(col)] = mat[(row)*size + col];
		// }
	}
}

int main(){
	cudaEvent_t start_gpu, end_gpu;
	float msecs_gpu;
	cudaEventCreate(&start_gpu);
	cudaEventCreate(&end_gpu);
	cudaEventRecord(start_gpu, 0);

	int *mat;
	cudaError_t status = cudaMallocHost((void**)&mat, size*size*sizeof(int));
	// mat = (int*)malloc(size*size*sizeof(int));
	if (status!=cudaSuccess){
		cout<<"Error occured in pinned memory"<<endl;
		return 0;
	}
	for (int i=0;i<size;i++){
		for (int j=0;j<size;j++){
			mat[i*size+j]=j;
		}
	}
	int *dmat;
	cudaMalloc((void**)&dmat, size*size*sizeof(int));
	cudaMemcpy(dmat, mat,size*size*sizeof(int), cudaMemcpyHostToDevice );
	// size_t pitch;
	// status = cudaMallocPitch((void**)&dmat, &pitch, size*sizeof(int),size);
	// if (status!=cudaSuccess){
	// 	cout<<"Error occured in PITCH initialise"<<endl;
	// 	return 0;
	// }
	// status = cudaMemcpy2D(dmat,pitch, mat,size*sizeof(int), pitch, size, cudaMemcpyHostToDevice);
	// if (status!=cudaSuccess){
	// 	cout<<"Error occured in PITCH copy"<<endl;
	// 	cout<<cudaGetErrorString(status)<<endl;
	// 	return 0;
	// }


	int *transmat;
	// transmat = (int*)malloc(size*size*sizeof(int));
	status = cudaMallocHost((void**)&transmat, size*size*sizeof(int));
	if (status!=cudaSuccess){
		cout<<"Error occured in pinned memory"<<endl;
		return 0;
	}

	int *dtransmat;
	cudaMalloc((void**)&dtransmat, size*size*sizeof(int));


	dim3 grid,block;
	block.x = bs;
	block.y = bs;
	grid.x = ((int)size/bs)+1;
	grid.y = ((int)size/bs)+1;
	cout<<"Safely reached"<<endl;
	cudaEvent_t start, end;
	float msecs;
	cudaEventCreate(&start);
	cudaEventCreate(&end);
	cudaEventRecord(start, 0);

	trans<<<grid,block>>>(dmat, dtransmat);

	cudaEventRecord(end, 0);
	cudaEventSynchronize(end);
	cudaEventElapsedTime(&msecs, start, end);
	cudaEventDestroy(start);
	cudaEventDestroy(end);
	cout<<"kernel done in "<<msecs<<" milliseconds.\n";

	cudaMemcpy(transmat, dtransmat, size*size*sizeof(int), cudaMemcpyDeviceToHost);

	cudaEventRecord(end_gpu, 0);
	cudaEventSynchronize(end_gpu);
	cudaEventElapsedTime(&msecs_gpu, start_gpu, end_gpu);
	cudaEventDestroy(start_gpu);
	cudaEventDestroy(end_gpu);
	cout<<"done in "<<msecs_gpu<<" milliseconds.\n";

	// for (int i=size-5;i<size;i++){
	// 	for (int j=0;j<size;j++){
	// 		cout<<transmat[i*size+j]<<"  ";
	// 	}
	// 	cout<<endl;
	// }

	cudaFree(dmat);
	cudaFreeHost(mat);
	cudaFree(dtransmat);
	cudaFreeHost(transmat);
	return 0;
}