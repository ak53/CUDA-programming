#include <cuda_runtime.h>
#include <iostream>
#include <vector>
#include <fstream>

using std::cerr;
using std::ofstream;
#include "helper.h"
#include "dt_gpu.h"

extern "C++" void computeDT_GPU_(float* points, int n_points, float* shapeBounds, int* triangles, int &n_triangles);

void computeDT_GPU(std::vector<std::vector<Point*> > shapePoints, std::vector<float*> shapeBounds, std::vector<std::vector<int> > triangles)
{
	int n_shapes = shapeBounds.size();
	float *pts;
	int *tri;
	for (int i = 0; i < n_shapes; ++i){
		int n_tri=0, n_points=shapePoints[i].size();

		pts = (float*)malloc(n_points*2*sizeof(float));
		for (int j=0; j<n_points; ++j){
		 	pts[2*j] = (float)shapePoints[i][j]->x;
		 	pts[2*j+1] = (float)shapePoints[i][j]->y;
		}
		
		computeDT_GPU_(pts, n_points, shapeBounds[i], tri, n_tri);
		free(pts);

		std::vector<int> new_triangles;
		for (int j=0; j<n_tri; ++j){
			new_triangles.push_back(tri[3*j]);
			new_triangles.push_back(tri[3*j+1]);
			new_triangles.push_back(tri[3*j+2]);
		}

		triangles.push_back(new_triangles);
		break;
	}
}
