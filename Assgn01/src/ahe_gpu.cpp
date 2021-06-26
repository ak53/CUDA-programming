#include "ahe_gpu.h"
#include <cuda_runtime.h>

#include <iostream>

extern "C" void run_sampleKernel(unsigned char* img_in, unsigned char* img_out, int width, int height);

void adaptiveEqualizationGPU(unsigned char* img_in, unsigned char* img_out, int width, int height)
{
  run_sampleKernel(img_in, img_out, width, height); // Remove me!
}
