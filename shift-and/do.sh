#!/bin/bash

src=shift-and.cu
#flags="-Wno-deprecated-gpu-targets"

nvcc=~/cuda/9.1.85/bin/nvcc

opts="-O1 -O2"
#opts="-O0"
#opts="-O1"

#gens="nvcc driver"
#gens="nvcc"
gens="driver"

sm=30
#sm=35
#sm=50
#sm=75

for opt in $opts; do
    for gen in $gens; do
	case $gen in
	    driver)
		echo DRIVER SASS, ptxas=$opt:
		rm -f a.out
		genflags=-arch=compute_$sm
		(
		    set -x
		    $nvcc $src $flags $genflags -Xptxas $opt
		    ./a.out
		)
		;;
	    nvcc)
		echo NVCC SASS, ptxas=$opt:
		rm -f a.out
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
