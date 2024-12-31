#!/bin/bash

HOME=`pwd`
DIR1="PolyBench-ACC/CUDA/linear-algebra/kernels"
DIR2="PolyBench-ACC/CUDA/stencils"
KER="
2mm
3mm
atax
bicg
doitgen
gemm
gemver
gesummv
mvt
syr2k
syrk
"
STN="
adi
2DConvolution
3DConvolution
fdtd2d
jacobi1D
jacobi2D
"

for bench in ${KER}
do
	cd $HOME/$DIR1

	cd $bench

	./${bench}.exe
done

for bench in ${STN}
do
	cd $HOME/$DIR2

	cd $bench

	./${bench}.exe
done


