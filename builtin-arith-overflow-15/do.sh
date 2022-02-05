#!/bin/bash

tmp="core a.out"
rm -f $tmp

src=src.cu
#flags="-Wno-deprecated-gpu-targets"

nvcc=~/cuda/11.6.0/bin/nvcc

opts="-O0 -O1"
#opts="-O0"
#opts="-O1"

gens="nvcc driver"
#gens="nvcc"
#gens="driver"

#sm=35
#sm=50
#sm=61
sm=75

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
