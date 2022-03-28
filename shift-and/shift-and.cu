#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

#define gpuErrchk(ans)				\
  do {						\
    gpuAssert((ans), __FILE__, __LINE__);	\
  } while (0)

inline void
gpuAssert (cudaError_t code, const char *file, int line)
{
  if (code != cudaSuccess)
    {
      fprintf (stderr,"GPUassert: %s %s %d\n",
	       cudaGetErrorString (code), file, line);

      abort ();
    }
}

__global__ void
hello (unsigned long long d0, unsigned long long int *output)
{
  asm volatile
    (
     ".reg .u64 ar0;"
     "mov.u64 ar0, %0;"

     ".reg .u64 rp;"
     "mov.u64 rp, %1;"

     ".local .align 8 .b8 stack_ar[16];"
     ".reg .u64 stack;"
     "cvta.local.u64 stack,stack_ar;"

     ".reg .u64 r24;"
     ".reg .u64 r27;"
     ".reg .u64 r28;"
     ".reg .pred r29;"
     ".reg .u32 r30;"
     ".reg .u64 r31;"
     ".reg .u64 r32;"
     ".reg .pred r33;"
     ".reg .pred r34;"

     "mov.u64 r27,ar0;"
     "shr.u64 r28,r27,56;"
     "setp.ne.u64 r29,r28,0;"
     "@ r29 bra $L5;"

     "mov.u64 r24,56;"
     "bra $L3;"

     "$L4:"
     "cvt.u32.u64 r30,r24;"
     "shr.u64 r31,r27,r30;"
     "and.b64 r32,r31,255;"
     "setp.ne.u64 r33,r32,0;"
     "@ r33 bra $L2;"

     "$L3:"
     "add.u64 r24,r24,-8;"
     "setp.ne.u64 r34,r24,0;"
     "@ r34 bra $L4;"
     "bra $L2;"

     "$L5:"
     "mov.u64 r24,56;"

     "$L2:"
     "st.u64 [stack],r24;"
     "ld.u64 r24,[stack];"
     "st.u64 [rp],r24;"
     ::"l"(d0), "l"(output));
}

#define BSIZE 1
unsigned long long int a[BSIZE];

int
main (void)
{
  dim3 dimBlock (1, 1);
  dim3 dimGrid (1, 1);

  /* Initialize a.  */
  for (int i = 0; i < BSIZE; ++i)
    a[i] = 0;

  /* Allocate device copy of a.  */
  unsigned long long int *p;
  gpuErrchk ((cudaMalloc ((void**)&p, BSIZE * sizeof(*a))));

  /* Copy to device.  */
  gpuErrchk ((cudaMemcpy (p, &a[0], BSIZE * sizeof (*a), cudaMemcpyHostToDevice)));

  /* Execute kernel.  */
  hello<<<dimGrid, dimBlock>>> (1, p);

  /* Copy back to host.  */
  gpuErrchk ((cudaMemcpy (&a[0], p, BSIZE * sizeof (*a), cudaMemcpyDeviceToHost)));

  /* Print output.  */
  for (int i = 0; i < BSIZE; ++i)
    printf ("a[%d]: %llx\n", i, a[i]);

  return 0;
}
