#include<bits/stdc++.h>
using namespace std;

#define size 1000

void trans(int* mat, int* transmat){
	for (int i=0;i<size;i++){
		for (int j=0;j<size;j++){
			transmat[j*size+i] = mat[i*size+j];
		}
	}
}

int main(){
	struct timespec begin,end;
	clock_gettime(CLOCK_REALTIME, &begin);

	int *mat;
	mat = (int*)malloc(size*size*sizeof(int));
	for (int i=0;i<size;i++){
		for (int j=0;j<size;j++){
			mat[i*size+j]=j;
		}
	}

	int *transmat;
	transmat = (int*)malloc(size*size*sizeof(int));

	trans(mat,transmat);
	clock_gettime(CLOCK_REALTIME, &end);
	long s = end.tv_sec - begin.tv_sec;
	long ns = end.tv_nsec - begin.tv_nsec;
	double elapsed = s + ns*(1e-9);
	printf("Time taken %.6f seconds\n", elapsed);

	for (int i=0;i<size;i++){
		for (int j=0;j<size;j++){
			cout<<transmat[i*size+j]<<"  ";
		}
		cout<<endl;
	}

}