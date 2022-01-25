#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

/* gpuErrchk / gpuAssert copied from:
   https://stackoverflow.com/questions/14038589/what-is-the-canonical-way-to-check-for-errors-using-the-cuda-runtime-api .  */

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
hello ()
{
  asm volatile ("{"

  ".shared .align 8 .u8 __oacc_bcast[144];"

  ".local .align 16 .b8 %frame_ar[24];"
  ".reg .u64 %frame;"
  "cvta.local.u64 %frame,%frame_ar;"

  ".reg .u32 %r22;"
  ".reg .u32 %r23;"
  ".reg .u32 %r24;"
  ".reg .u32 %r25;"
  ".reg .u32 %r28;"
  ".reg .u32 %r29;"
  ".reg .u32 %r30;"
  ".reg .u32 %r31;"
  ".reg .u32 %r34;"
  ".reg .u32 %r35;"
  ".reg .u32 %r36;"
  ".reg .u32 %r37;"
  ".reg .u32 %r38;"
  ".reg .u32 %r39;"
  ".reg .u64 %r40;"
  ".reg .u64 %r43;"
  ".reg .pred %r44;"
  ".reg .pred %r45;"
  ".reg .u32 %r46;"
  ".reg .u32 %r47;"
  ".reg .u32 %r48;"
  ".reg .u64 %r49;"
  ".reg .u64 %r50;"
  ".reg .u64 %r51;"
  ".reg .u64 %r52;"
  ".reg .u32 %r53;"
  ".reg .pred %r54;"
  ".reg .pred %r55;"
  ".reg .u32 %r56;"
  ".reg .pred %r57;"
  ".reg .pred %r58;"
  ".reg .u32 %r59;"
  ".reg .u64 %r60;"
  ".reg .u64 %r61;"
  ".reg .u64 %r62;"
  ".reg .u32 %r63;"
  ".reg .pred %r64;"
  ".reg .u64 %r65;"
  ".reg .u64 %r66;"
  ".reg .u32 %r67;"
  ".reg .u64 %r68;"
  ".reg .u64 %r69;"
  ".reg .u64 %r70;"
  ".reg .u32 %r71;"
  ".reg .pred %r72;"
  ".reg .u64 %r73;"
  ".reg .u64 %r74;"
  ".reg .u64 %r75;"
  ".reg .u64 %r76;"
  ".reg .u32 %r77;"
  ".reg .pred %r78;"
  ".reg .u64 %r79;"
  ".reg .u64 %r80;"
  ".reg .u64 %r81;"
  ".reg .u64 %r82;"
  ".reg .u32 %r83;"
  ".reg .pred %r84;"
  ".reg .u64 %r85;"
  ".reg .pred %r86;"
  ".reg .u32 %r87;"
  ".reg .u32 %r88;"
  ".reg .u32 %r89;"
  ".reg .u32 %r90;"
  ".reg .u32 %r91;"
  ".reg .u32 %r92;"
  ".reg .pred %r93;"

  "{"
   ".reg .u32 %y;"
   " mov.u32 %y,%tid.y;"
   " setp.ne.u32 %r93,%y,0;"
  "}"

  "{"
    ".reg .u32 %x;"
    "mov.u32 %x,%tid.x;"
    "setp.ne.u32 %r86,%x,0;"
  "}"

  "{"
    ".reg .u32 %tidy;"
    ".reg .u64 %t_bcast;"
    ".reg .u64 %y64;"
    "mov.u32 %tidy,%tid.y;"
    "cvt.u64.u32 %y64,%tidy;"
    "add.u64 %y64,%y64,1;"
    // vector ID
    "cvta.shared.u64 %t_bcast,__oacc_bcast;"
    "mad.lo.u64 %r66,%y64,48,%t_bcast;"
    // vector broadcast offset
    "add.u32 %r67,%tidy,1;"
    // vector synchronization barrier
  "}"

  "@ %r93 bra.uni $L18;"
  "@ %r86 bra $L19;"
  "st.u64 [%frame],0;"
  // fork 2;"
  "cvta.shared.u64 %r85,__oacc_bcast;"
  "mov.u64 %r82,%frame;"
  "mov.u32 %r83,1;"
 "$L11:"
  "sub.u32 %r83,%r83,1;"
  "ld.u64 %r81,[%r82];"
  "st.u64 [%r85],%r81;"
  "add.u64 %r85,%r85,8;"
  "setp.ne.u32 %r84,%r83,0;"
  "add.u64 %r82,%r82,8;"
  "@ %r84 bra $L11;"
 "$L19:"
 "$L18:"

  "barrier.sync.aligned 0;"

  "@ %r86 bra $L12;"
  "cvta.shared.u64 %r79,__oacc_bcast;"
  "mov.u64 %r76,%frame;"
  "mov.u32 %r77,1;"
 "$L10:"
  "sub.u32 %r77,%r77,1;"
  "ld.u64 %r75,[%r79];"
  "add.u64 %r79,%r79,8;"
  "st.u64 [%r76],%r75;"
  "setp.ne.u32 %r78,%r77,0;"
  "add.u64 %r76,%r76,8;"
  "@ %r78 bra $L10;"
 "$L12:"

 "$L7:"

  "@ %r86 bra $L13;"
  "st.u32 [%r66],0;"
 "$L13:"

  "barrier.sync %r67,64;"

  "@ %r86 bra $L16;"
  "st.u32 [%r66],0;"
 "$L16:"

  "barrier.sync %r67,64;"

  "ld.u32 %r92,[%r66];"
  "setp.ne.u32 %r58,%r92,0;"

  "barrier.sync %r67,64;"

  "@ %r58 bra.uni $L7;"

  "}" : :);
}

int
main (void)
{
  #define WARP_SIZE 32
  dim3 dimBlock (WARP_SIZE * 2, 2);
  dim3 dimGrid (1, 1);

  hello<<<dimGrid, dimBlock>>> ();

  gpuErrchk (cudaDeviceSynchronize ());

  return 0;
}
