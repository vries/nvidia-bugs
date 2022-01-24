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
hello (unsigned int *output)
{
  asm volatile ("{"

  ".reg .u64 rp;"
  "mov.u64 rp, %0;"

  ".reg .u32 r22;"
  ".reg .u32 r24;"
  ".reg .u32 r27;"
  ".reg .u32 r30;"
  ".reg .u32 r31;"
  ".reg .u32 r34;"
  ".reg .u32 r35;"
  ".reg .u32 r38;"
  ".reg .u32 r39;"
  ".reg .u32 r42;"
  ".reg .u32 r43;"
  ".reg .u32 r46;"
  ".reg .u64 r48;"
  ".reg .pred r49;"
  ".reg .u32 r51;"
  ".reg .pred r52;"
  ".reg .u64 r53;"
  ".reg .pred r59;"
  ".reg .pred r60;"
  ".reg .u32 r61;"
  ".reg .pred r62;"
  ".reg .u32 r63;"

  "{"
    ".reg .u32 %x;"
    "mov.u32 %x,%tid.x;"
    "setp.ne.u32 r59,%x,0;"
  "}"

  "@ r59 bra $L15;"
  "mov.u32 r22,2;" // Initialize outer loop counter.
 "$L15:"
  
  "bra $L3;" // Goto inner loop start.

 "$L6:" // Outer loop backedge target.

  "@ r59 bra $L10;"
  "mov.u32 r22,1;" // Increment outer loop counter.
 "$L10:"

 "$L3:" // Inner loop start.

  "@ r59 bra $L14;"
  "mov.u32 r24,2;" // Initialize inner loop counter.
 "$L14:"

  "bra $L2;"

 "$L7:" // Inner loop backedge target.

  "@ r59 bra $L13;"
  "mov.u32 r24,1;" // Increment inner loop counter.
 "$L13:"

  // Loop body.
 "$L2:"
  "mov.u32 r27,%tid.x;"
  "shfl.down.b32 r30,r27,16,31;"
  "max.s32 r31,r30,r27;"
  "shfl.down.b32 r34,r31,8,31;"
  "max.s32 r35,r34,r31;"
  "shfl.down.b32 r38,r35,4,31;"
  "max.s32 r39,r38,r35;"
  "shfl.down.b32 r42,r39,2,31;"
  "max.s32 r43,r42,r39;"
  "shfl.down.b32 r46,r43,1,31;"
  "max.s32 r51,r46,r43;"
  // Assert: r51 == 31.

  "setp.eq.u32 r62,1,0;" // Initialize predicate for all lanes.

  "@ r59 bra $L12;"
  "st.u32 [rp],r51;" // Result store.
  "setp.ne.u32 r62,r24,1;" // Calculate inner loop condition.
 "$L12:"

  "mov.pred r52,r62;"
  "selp.u32 r63,1,0,r52;"
  "shfl.idx.b32 r63,r63,0,31;" // Broadcast inner loop condition.
  "setp.ne.u32 r52,r63,0;"

  "@ r52 bra.uni $L7;" // Continue inner loop.

  "setp.eq.u32 r60,1,0;" // Initialize predicate for all lanes.

  "@ r59 bra $L11;"
  "setp.ne.u32 r60,r22,1;" // Calculate outer loop condition.
 "$L11:"

  "mov.pred r49,r60;"
  "selp.u32 r61,1,0,r49;"
  "shfl.idx.b32 r61,r61,0,31;" // Broadcast outer loop condition.
  "setp.ne.u32 r49,r61,0;"
  "@ r49 bra.uni $L6;" // Continue outer loop.

  "}" : : "l"(output));
}

#define BSIZE 1
unsigned int a[BSIZE];

int
main (void)
{
  /* Dimensions: just one warp.  */
  #define WARP_SIZE 32
  #define NR_WARPS 1
  dim3 dimBlock (WARP_SIZE, NR_WARPS);
  dim3 dimGrid (1, 1);

  /* Initialize a.  */
  for (int i = 0; i < BSIZE; ++i)
    a[i] = 0;

  /* Allocate device copy of a.  */
  unsigned int *p;
  gpuErrchk ((cudaMalloc ((void**)&p, BSIZE * sizeof(int))));

  /* Copy to device.  */
  gpuErrchk ((cudaMemcpy (p, &a[0], BSIZE * sizeof (int), cudaMemcpyHostToDevice)));

  /* Execute kernel.  */
  hello<<<dimGrid, dimBlock>>> (p);

  /* Copy back to host.  */
  gpuErrchk ((cudaMemcpy (&a[0], p, BSIZE * sizeof (int), cudaMemcpyDeviceToHost)));

  /* Print output.  */
  for (int i = 0; i < BSIZE; ++i)
    printf ("a[%d]: %u\n", i, a[i]);

  if (a[0] != 31)
    __builtin_abort ();  

  return 0;
}
