#define DEBUG 1

#include <assert.h>
#if DEBUG
#include <stdio.h>
#endif

#define gpuErrchk(ans)				\
  do {						\
    gpuAssert ((ans), __FILE__, __LINE__);	\
  } while (0)

inline void
gpuAssert (cudaError_t code, const char *file, int line)
{
  if (code != cudaSuccess)
    {
#if DEBUG
      fprintf (stderr, "GPUassert: %s %s %d\n", cudaGetErrorString (code),
	       file, line);
#endif
    }

  assert (code == cudaSuccess);
}

__device__ int
foo (int n)
{
  int res;
  
  asm volatile ("{"

		".reg .u32 r25;"
		".reg .u64 r26;"
		".reg .u32 r27;"
		".reg .u32 r28;"
		".reg .u32 r31;"

		"mov.u32 r27, %1;"

		"mov.u32 r28,-2147483648;"

		"mul.wide.s32 r26,r27,r28;"

		"set.eq.u32.u64 r31,r26,2147483648;"

		"neg.s32 r25,r31;"

		"mov.u32 %0, r25;"

		"}"

		: "=r"(res) : "r"(n));

  return res;
}

__global__  void
hello (int *p)
{
  *p = foo (*p);
}

int
main (void)
{
  dim3 dimBlock (1, 1);
  dim3 dimGrid (1, 1);

  int *p;
  int n = -1;

  gpuErrchk ( cudaMalloc ((void**)&p, sizeof(int)) );
  gpuErrchk ( cudaMemcpy (p, &n, sizeof (int), cudaMemcpyHostToDevice) );

  hello<<<dimGrid, dimBlock>>> (p);
  gpuErrchk( cudaPeekAtLastError() );
  gpuErrchk( cudaDeviceSynchronize() );

  gpuErrchk ( cudaMemcpy (&n, p, sizeof (int), cudaMemcpyDeviceToHost) );

#if DEBUG
  if (n == 1)
    printf ("n: %d (GOOD)\n", n);
  else
    printf ("n: %d (BAD)\n", n);  
#endif

  assert (n == 1);

  return 0;
}
