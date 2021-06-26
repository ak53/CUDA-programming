# Adaptive histogram equalization

Includes code files for performing adaptive histogram equaliation on images using CPU as well as GPU. The runner files also contain code to compare runtimes between CPU and GPU. Caution: The provided code output for GPU gives a good MSE error when comapred with outputs to CPU impling some errors in the GPU code.

## Features
1) Uses shared memory tiling for finding mappings for each pixel.
2) Copies the above output to constant memory for faster access.
3) Then performs adaptive equalization using mappings in constant memory.
