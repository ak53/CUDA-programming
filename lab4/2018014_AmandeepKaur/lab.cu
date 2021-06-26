#include <iostream>
#include <stdio.h>
#include <time.h>

#define LENGTH 256
using namespace std;

struct SoA 
{ 
   int x[LENGTH];
   int y[LENGTH];
   int z[LENGTH]; 
};

struct S 
{ 
   int x;
   int y;
   int z; 
};

__global__ void add_soa(SoA* a, SoA* b, SoA* c){
    int i = threadIdx.x ;
	 if  (i < LENGTH){
	    c->x[i] = a->x[i] + b->x[i]; 
	    c->y[i] = a->y[i] + b->y[i]; 
	    c->z[i] = a->z[i] + b->z[i]; 
	}
}

__global__ void add_aos(S* a, S* b, S* c){
    int i = threadIdx.x ;
	 if  (i < LENGTH){
	    c[i].x = a[i].x + b[i].x; 
	    c[i].y = a[i].y + b[i].y; 
	    c[i].z = a[i].z + b[i].z; 
	}
}

int main(){

	SoA* a;
	SoA* b;
	SoA* c;

	S* d;
	S* e;
	S* f;

	a = (SoA*)malloc(sizeof(SoA));
	b = (SoA*)malloc(sizeof(SoA));
	c = (SoA*)malloc(sizeof(SoA));
	d = (S*)malloc(LENGTH*sizeof(S));
	e = (S*)malloc(LENGTH*sizeof(S));
	f = (S*)malloc(LENGTH*sizeof(S));

	for(int i=0 ; i< LENGTH; i++){
		a->x[i] = i;
		a->y[i] = i-1;
		a->z[i] = i-2;
		b->x[i] = i;
		b->y[i] = i-1;
		b->z[i] = i-2;
		d[i].x = i;
		d[i].y = i-1;
		d[i].z = i-2;
		e[i].x = i;
		e[i].y = i-1;
		e[i].z = i-2;
	}

	SoA* d_a;
	SoA* d_b;
	SoA* d_c;

	S* d_d;
	S* d_e;
	S* d_f;

	cudaMalloc((void**)&d_a,sizeof(SoA));
	cudaMalloc((void**)&d_b,sizeof(SoA));
	cudaMalloc((void**)&d_c,sizeof(SoA));

	cudaMalloc((void**)&d_d,LENGTH*sizeof(S));
	cudaMalloc((void**)&d_e,LENGTH*sizeof(S));
	cudaMalloc((void**)&d_f,LENGTH*sizeof(S));


	cudaMemcpy(d_a,a,sizeof(SoA), cudaMemcpyHostToDevice);
	cudaMemcpy(d_b,b,sizeof(SoA), cudaMemcpyHostToDevice);

	cudaMemcpy(d_d,d,LENGTH*sizeof(S), cudaMemcpyHostToDevice);
	cudaMemcpy(d_e,e,LENGTH*sizeof(S), cudaMemcpyHostToDevice);

	// add_soa<<<1, LENGTH>>>(d_a,d_b,d_c); 
	add_aos<<<1, LENGTH>>>(d_d,d_e,d_f); 

	cudaMemcpy(c,d_c,sizeof(SoA), cudaMemcpyDeviceToHost);
	cudaMemcpy(f,d_f,LENGTH*sizeof(S), cudaMemcpyDeviceToHost);

	// for(int i=0 ; i< LENGTH; i++){
	// 	std::cout<<c->x[i]<<"  "<<c->y[i]<<"  "<<c->z[i]<<'\n'<<std::flush;
	// 	std::cout<<f[i].x<<"  "<<f[i].y<<"  "<<f[i].z<<'\n'<<std::flush;

	// }	

	cudaFree(d_a);
	cudaFree(d_b);
	cudaFree(d_c);
	free(a);
	free(b);
	free(c);
	cudaFree(d_d);
	cudaFree(d_e);
	cudaFree(d_f);
	free(d);
	free(e);
	free(f);
}

