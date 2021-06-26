#include <iostream>
#include <stdio.h>
#include <time.h>
#include <unistd.h>

#define LENGTH 10000000
using namespace std;

__global__ void vector_add(float *a, float *b, float *c){
	int index = threadIdx.x + blockDim.x * blockIdx.x; 
	if (index<LENGTH){
		c[index] = a[index] + b[index];
	}
}

void myCpu(){
	unsigned int microseconds = 10000000;
	usleep(microseconds);
}

int main(){

	float *a_vec, *b_vec, *c_vec;

	a_vec = (float*)malloc(LENGTH*sizeof(float));
	b_vec = (float*)malloc(LENGTH*sizeof(float));

	c_vec = (float*)malloc(LENGTH*sizeof(float)); //cpu device -> host

	for(int i=0 ; i< LENGTH; i++){
		a_vec[i] = i;
		b_vec[i] = i;
	}

	float *d_a, *d_b, *d_c;

	cudaMalloc((void**)&d_a, LENGTH*sizeof(float));
	cudaMalloc((void**)&d_b, LENGTH*sizeof(float));
	cudaMalloc((void**)&d_c, LENGTH*sizeof(float)); // host -> device

	cudaMemcpy(d_a, a_vec, LENGTH*sizeof(float), cudaMemcpyHostToDevice);
	cudaMemcpy(d_b, b_vec, LENGTH*sizeof(float), cudaMemcpyHostToDevice);
	
	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	cudaEventRecord(start);

	vector_add<<<(int)ceil((float)LENGTH/1024),1024>>>(d_a, d_b, d_c); //what happens if no of threads becomes decimal
	myCpu();
	// cudaDeviceSynchronize();
	cudaEventRecord(stop);

	cudaMemcpy(c_vec, d_c, LENGTH*sizeof(float), cudaMemcpyDeviceToHost);
	
	cudaEventSynchronize(stop);

	float milliseconds = 0;
	cudaEventElapsedTime(&milliseconds, start, stop);

	std::cout  << "Time taken : " << milliseconds << std::endl;
	std::cout<<"First 3 elements are "<<c_vec[0]<<"  "<<c_vec[1]<<"  "<<c_vec[2]<<'\n';
	free(a_vec);
	free(b_vec);
	free(c_vec);

	// for(int i=0; i<LENGTH ;i++){
	// 	cout << c_vec[i] << endl;
	// }
}
