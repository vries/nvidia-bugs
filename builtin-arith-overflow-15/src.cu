#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

#define gpuErrchk(ans)				\
  do {						\
    gpuAssert((ans), __FILE__, __LINE__);	\
  } while (0)

inline void
gpuAssert (cudaError_t code, const char *file, int line, bool do_abort=true)
{
  if (code != cudaSuccess)
    {
      fprintf (stderr,"GPUassert: %s %s %d\n",
	       cudaGetErrorString (code), file, line);

      if (do_abort)
	abort ();
    }
}

__global__ void
hello (unsigned int *output)
{
  asm volatile (
    "{"

    ".reg .u64 rp;"
    "mov.u64 rp, %0;"

    ".local .u16 frame_var;"

    ".reg .u16 r22;"
    ".reg .u16 r32;"
    ".reg .u16 r33;"
    ".reg .u32 r35;"

    "mov.u16 r22, 0x0080;"

    "st.local.u16 [frame_var],r22;"
    "ld.local.u16 r32,[frame_var];"
    //"mov.u16 r32,0x0080;"

    "sub.u16 r33,0x0000,r32;"
    //"mov.u16 r33,0xff80;"

    "cvt.u32.u16 r35,r33;"
    //"mov.u32 r35, 0x0000ff80;"

    "st.u32 [rp], r35;"
  "}" : : "l"(output));
}

#define BSIZE 1
unsigned int a[BSIZE];

int
main (void)
{
  /* Dimensions: just one thread.  */
  dim3 dimBlock (1, 1);
  dim3 dimGrid (1, 1);

  /* Initialize a.  */
  for (int i = 0; i < BSIZE; ++i)
    a[i] = 0;

  /* Allocate device copy of a.	 */
  unsigned int *p;
  gpuErrchk ((cudaMalloc ((void**)&p, BSIZE * sizeof(int))));

  /* Copy to device.  */
  gpuErrchk ((cudaMemcpy (p, &a[0], BSIZE * sizeof (int),
			  cudaMemcpyHostToDevice)));

  /* Execute kernel.  */
  hello<<<dimGrid, dimBlock>>> (p);

  /* Copy back to host.	 */
  gpuErrchk ((cudaMemcpy (&a[0], p, BSIZE * sizeof (int),
			  cudaMemcpyDeviceToHost)));

  /* Print output.  */
  for (int i = 0; i < BSIZE; ++i)
    printf ("a[%d]: %x\n", i, a[i]);

  if (a[0] != 0x0000ff80)
    __builtin_abort ();

  return 0;
}
