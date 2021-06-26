#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-function"
#pragma GCC diagnostic ignored "-Wcast-qual"
#define __NV_CUBIN_HANDLE_STORAGE__ static
#if !defined(__CUDA_INCLUDE_COMPILER_INTERNAL_HEADERS__)
#define __CUDA_INCLUDE_COMPILER_INTERNAL_HEADERS__
#endif
#include "crt/host_runtime.h"
#include "ahe_gpu_kernels.fatbin.c"
extern void __device_stub__Z24findEqualizationMappingsPhiiS_PiS0_(unsigned char *, int, int, unsigned char *, int *, int *);
extern void __device_stub__Z27performAdaptiveEqualizationPhS_ii(unsigned char *, unsigned char *, int, int);
static void __nv_cudaEntityRegisterCallback(void **);
static void __sti____cudaRegisterAll(void) __attribute__((__constructor__));
void __device_stub__Z24findEqualizationMappingsPhiiS_PiS0_(unsigned char *__par0, int __par1, int __par2, unsigned char *__par3, int *__par4, int *__par5){__cudaLaunchPrologue(6);__cudaSetupArgSimple(__par0, 0UL);__cudaSetupArgSimple(__par1, 8UL);__cudaSetupArgSimple(__par2, 12UL);__cudaSetupArgSimple(__par3, 16UL);__cudaSetupArgSimple(__par4, 24UL);__cudaSetupArgSimple(__par5, 32UL);__cudaLaunch(((char *)((void ( *)(unsigned char *, int, int, unsigned char *, int *, int *))findEqualizationMappings)));}
# 14 "/home/CSE560/amandeep18014/samples/Assgn01/src/ahe_gpu_kernels.cu"
void findEqualizationMappings( unsigned char *__cuda_0,int __cuda_1,int __cuda_2,unsigned char *__cuda_3,int *__cuda_4,int *__cuda_5)
# 15 "/home/CSE560/amandeep18014/samples/Assgn01/src/ahe_gpu_kernels.cu"
{__device_stub__Z24findEqualizationMappingsPhiiS_PiS0_( __cuda_0,__cuda_1,__cuda_2,__cuda_3,__cuda_4,__cuda_5);
# 46 "/home/CSE560/amandeep18014/samples/Assgn01/src/ahe_gpu_kernels.cu"
}
# 1 "ahe_gpu_kernels.cudafe1.stub.c"
void __device_stub__Z27performAdaptiveEqualizationPhS_ii( unsigned char *__par0,  unsigned char *__par1,  int __par2,  int __par3) {  __cudaLaunchPrologue(4); __cudaSetupArgSimple(__par0, 0UL); __cudaSetupArgSimple(__par1, 8UL); __cudaSetupArgSimple(__par2, 16UL); __cudaSetupArgSimple(__par3, 20UL); __cudaLaunch(((char *)((void ( *)(unsigned char *, unsigned char *, int, int))performAdaptiveEqualization))); }
# 48 "/home/CSE560/amandeep18014/samples/Assgn01/src/ahe_gpu_kernels.cu"
void performAdaptiveEqualization( unsigned char *__cuda_0,unsigned char *__cuda_1,int __cuda_2,int __cuda_3)
# 48 "/home/CSE560/amandeep18014/samples/Assgn01/src/ahe_gpu_kernels.cu"
{__device_stub__Z27performAdaptiveEqualizationPhS_ii( __cuda_0,__cuda_1,__cuda_2,__cuda_3);
# 99 "/home/CSE560/amandeep18014/samples/Assgn01/src/ahe_gpu_kernels.cu"
}
# 1 "ahe_gpu_kernels.cudafe1.stub.c"
static void __nv_cudaEntityRegisterCallback( void **__T1) {  __nv_dummy_param_ref(__T1); __nv_save_fatbinhandle_for_managed_rt(__T1); __cudaRegisterEntry(__T1, ((void ( *)(unsigned char *, unsigned char *, int, int))performAdaptiveEqualization), _Z27performAdaptiveEqualizationPhS_ii, (-1)); __cudaRegisterEntry(__T1, ((void ( *)(unsigned char *, int, int, unsigned char *, int *, int *))findEqualizationMappings), _Z24findEqualizationMappingsPhiiS_PiS0_, (-1)); __cudaRegisterVariable(__T1, __shadow_var(const_mappings,::const_mappings), 0, 65536UL, 1, 0); }
static void __sti____cudaRegisterAll(void) {  __cudaRegisterBinary(__nv_cudaEntityRegisterCallback);  }

#pragma GCC diagnostic pop
