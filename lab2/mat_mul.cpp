#include<bits/stdc++.h>

#define w 1000
//#define colA 1
//#define rowB 1
//#define colB 4

using namespace std;

void mat_mul(int(*a)[w], int(*b)[w], int(*c)[w]){
	for (int i=0;i<w;i++){
		for (int j=0;j<w;j++){
			for (int k=0;k<w;k++){
				c[i][j] += (a[i][k] * b[k][j]);
			}
		}
	}
}

int main(){
	int (*a)[w];
	int (*b)[w];
	int (*c)[w];
	
	struct timespec begin, end;
	
	a=(int(*)[w])malloc(w*w*sizeof(int));
	b=(int(*)[w])malloc(w*w*sizeof(int));
	c=(int(*)[w])malloc(w*w*sizeof(int));
	
	for (int i=0;i<w;i++){
		for (int j=0;j<w;j++){
			a[i][j]=i;
			b[i][j]=i;
		}	
	}


	clock_gettime(CLOCK_REALTIME, &begin);
	mat_mul(a,b,c);
	clock_gettime(CLOCK_REALTIME, &end);
	
	long s = end.tv_sec - begin.tv_sec;
	long ns = end.tv_nsec - begin.tv_nsec;
	double elapsed = s + ns*(1e-9);

	//for (int i=0;i<w;i++){
	//	for (int j=0;j<w;j++){
	//		cout<<c[i][j]<<"   ";	
	//	}
	//	cout<<endl;
	//}
	printf("Time measured: %.6f seconds.\n",elapsed);

}
