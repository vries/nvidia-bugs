#!/bin/bash

tmp="core a.out"
rm -f $tmp

src=src.cu
#flags="-Wno-deprecated-gpu-targets"

# BAD ARCH: kepler, maxwell, pascal
# OK ARCH: turing
#
# CONFIRMED BAD CUDA: 11.0.3
# CONFIRMED BAD CUDA: 11.1.0
# CONFIRMED OK CUDA: 11.4.3
#
# CONFIRMED OK DRIVER: 510.47.03
# CONFIRMED OK DRIVER: 470.103.01
# CONFIRMED BAD DRIVER: 390.147.  Looks like nvidia is not going to fix this
# legacy branch.

# Bad.
#nvcc=~/cuda/11.0.3/bin/nvcc

# OK.
#nvcc=~/cuda/11.4.3/bin/nvcc

# Old enough to work with 390.x.
nvcc=~/cuda/9.0.176/bin/nvcc

opts="-O0 -O1"
#opts="-O0"
#opts="-O1"

gens="nvcc driver"
#gens="nvcc"
#gens="driver"

#sm=35
#sm=50
sm=61
#sm=75

for opt in $opts; do
    for gen in $gens; do
	case $gen in
	    driver)
		echo DRIVER SASS, ptxas=$opt:
		rm -f $tmp
		genflags=-arch=compute_$sm
		(
		    set -x
		    $nvcc $src $flags $genflags -Xptxas $opt
		    ./a.out
		)
		;;
	    nvcc)
		echo NVCC SASS, ptxas=$opt:
		rm -f $tmp
		genflags="-arch=compute_$sm -code=sm_$sm"
		(
		    set -x
		    $nvcc $src $flags $genflags -Xptxas $opt
		    ./a.out
		)
		;;
	esac
    done
done

rm -f $tmp
