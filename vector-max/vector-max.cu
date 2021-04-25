#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

__global__ void
hello (unsigned int *output)
{
  asm volatile ("{"

  ".reg .u32 r27;"
  ".reg .u64 rp;"
  ".reg .u32 r31;"
  ".reg .u32 r34;"
  ".reg .u32 r35;"
  ".reg .u32 r38;"
  ".reg .u32 r39;"
  ".reg .u32 r42;"
  ".reg .u32 r43;"
  ".reg .u32 r46;"
  ".reg .u32 r47;"
  ".reg .u32 r50;"
  ".reg .u32 r51;"
  ".reg .pred r63;"
  ".reg .pred r66;"
  ".reg .u32 r71;"
  ".reg .pred r77;"
  ".reg .pred r80;"
  ".reg .u32 r81;"
  ".reg .pred r82;"
  ".reg .u32 r83;"

  ".reg .u32 %x;"
  "mov.u32 %x,%tid.x;"
  "setp.ne.u32 r77,%x,0;"

  "mov.u64 rp, %0;"

  "@ r77 bra $L17;"
  "mov.u32 r71,1;"
 "$L17:"

  "bra $L4;"

 "$L7:"
  // Unreachable.
  "trap;"

 "$L4:"
  "@ r77 bra $L16;"
  "mov.u32 r27,r71;"
 "$L16:"

  "bra $L2;"

 "$L6:"
  // Unreachable.
  "trap;"
  
 "$L2:"
  "shfl.sync.idx.b32 r27,r27,0,31,0xffffffff;"
  "shfl.sync.idx.b32 r71,r71,0,31,0xffffffff;"

  "mov.u32 r31,%tid.x;"

  "shfl.sync.down.b32 r34,r31,16,31,0xffffffff;"
  "max.s32 r35,r34,r31;"

  "shfl.sync.down.b32 r38,r35,8,31,0xffffffff;"
  "max.s32 r39,r38,r35;"

  "shfl.sync.down.b32 r42,r39,4,31,0xffffffff;"
  "max.s32 r43,r42,r39;"

  "shfl.sync.down.b32 r46,r43,2,31,0xffffffff;"
  "max.s32 r47,r46,r43;"

  "shfl.sync.down.b32 r50,r47,1,31,0xffffffff;"

  "setp.eq.u32 r82,1,0;"

  "@ r77 bra $L14;"
  "setp.ne.u32 r63,r27,1;"
  "mov.pred r82,r63;"
 "$L14:"
  
  "mov.pred r63,r82;"
  "selp.u32 r83,1,0,r63;"
  "shfl.sync.idx.b32 r83,r83,0,31,0xffffffff;"
  "setp.ne.u32 r63,r83,0;"
  "@ r63 bra.uni $L6;"

  "setp.eq.u32 r80,1,0;"

  "@ r77 bra $L13;"
  "max.s32 r51,r50,r47;"
 "$L13:"

  "mov.pred r66,r80;"
  "selp.u32 r81,1,0,r66;"
  "shfl.sync.idx.b32 r81,r81,0,31,0xffffffff;"
  "setp.ne.u32 r66,r81,0;"
  "@ r66 bra.uni $L7;"

  "@ r77 bra $L100;"
  "st.u32 [rp], r51;"
 "$L100:"

  "}" : : "l"(output));
}

#define BSIZE 1
unsigned int a[BSIZE];

int
main (void)
{
  cudaError_t res;

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
  res = cudaMalloc ((void**)&p, BSIZE * sizeof(int)); 
  if (res != cudaSuccess)
    abort ();

  /* Copy to device.  */
  res = cudaMemcpy (p, &a[0], BSIZE * sizeof (int), cudaMemcpyHostToDevice); 
  if (res != cudaSuccess)
    abort ();

  /* Execute kernel.  */
  hello<<<dimGrid, dimBlock>>> (p);

  /* Copy back to host.  */
  res = cudaMemcpy (&a[0], p, BSIZE * sizeof (int), cudaMemcpyDeviceToHost);
  if (res != cudaSuccess)
    abort ();

  /* Print output.  */
  for (int i = 0; i < BSIZE; ++i)
    printf ("a[%d]: %u\n", i, a[i]);

  if (a[0] != 31)
    __builtin_abort ();  

  return 0;
}
