#!/bin/bash

src=vector-max.cu
flags="-Wno-deprecated-gpu-targets"

# Still OK.
#nvcc=~/cuda/11.0.3/bin/nvcc

# Not OK.
#nvcc=~/cuda/11.1.0/bin/nvcc

# OK again.
#nvcc=~/cuda/11.4.3/bin/nvcc

# Too new for current driver version 470.86.
#nvcc=~/cuda/11.5.1/bin/nvcc

nvcc=~/cuda/11.4.3/bin/nvcc

opts="-O0 -O1"
#opts="-O0"
#opts="-O1"

#gens="nvcc driver"
#gens="nvcc"
gens="driver"

sm=35
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
