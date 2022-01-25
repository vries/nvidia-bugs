#!/bin/bash

src=vector-length-64.cu
flags=

# Latest cuda release to work with driver version 470.94.
nvcc_sass_driver=~/cuda/11.4.3/bin/nvcc

# Latest cuda release.
nvcc_sass_nvcc=~/cuda/11.5.1/bin/nvcc

opts="-O0 -O1"
#opts="-O0"
#opts="-O1"

#gens="nvcc driver"
gens="nvcc"
#gens="driver"

sm=75

for opt in $opts; do
    for gen in $gens; do
	case $gen in
	    driver)
		nvcc=$nvcc_sass_driver;
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
		nvcc=$nvcc_sass_nvcc;
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
