#include <cuda_runtime.h>
#include <iostream>

#include "sdt_gpu.h"

extern "C" void run_sampleKernel(unsigned char * bitmap, float *sdt, int width, int height);

void computeSDT_GPU(unsigned char * bitmap, float *sdt, int width, int height)
{
  run_sampleKernel(bitmap, sdt, width, height); // Remove me!
}

