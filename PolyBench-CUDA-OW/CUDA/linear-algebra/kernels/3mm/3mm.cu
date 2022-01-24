/**
 * 3mm.cu: This file is part of the PolyBench/GPU 1.0 test suite.
 *
 *
 * Contact: Scott Grauer-Gray <sgrauerg@gmail.com>
 * Will Killian <killian@udel.edu>
 * Louis-Noel Pouchet <pouchet@cse.ohio-state.edu>
 * Web address: http://www.cse.ohio-state.edu/~pouchet/software/polybench/GPU
 */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <assert.h>
#include <unistd.h>
#include <sys/time.h>
#include <cuda.h>
#include <pthread.h>

#define POLYBENCH_TIME 1

#include "3mm.cuh"
#include <polybench.h>
#include <polybenchUtilFuncts.h>

#define GPU_DEVICE 0

//define the error threshold for the results "not matching"
#define PERCENT_DIFF_ERROR_THRESHOLD 0.05

//#define RUN_ON_CPU

// hdi=host_data_init, kdi=kernel-related_data_init gset=gpu_set, 
clock_t start, end;
double t_hdi, t_gset, t_malloc, t_write, t_kdi, t_kernel, t_read, t_clear;


void init_array(int ni, int nj, int nk, int nl, int nm, DATA_TYPE POLYBENCH_2D(A, NI, NK, ni, nk), DATA_TYPE POLYBENCH_2D(B, NK, NJ, nk, nj), 
		DATA_TYPE POLYBENCH_2D(C, NJ, NM, nj, nm), DATA_TYPE POLYBENCH_2D(D, NM, NL, nm, nl))
{
	int i, j;

	for (i = 0; i < ni; i++)
	{
		for (j = 0; j < nk; j++)
		{
			A[i][j] = ((DATA_TYPE) i*j) / ni;
		}
	}
  
	for (i = 0; i < nk; i++)
	{
		for (j = 0; j < nj; j++)
		{
			B[i][j] = ((DATA_TYPE) i*(j+1)) / nj;
		}
	}
  
	for (i = 0; i < nj; i++)
	{
		for (j = 0; j < nm; j++)
		{
			C[i][j] = ((DATA_TYPE) i*(j+3)) / nl;
		}
	}
  
	for (i = 0; i < nm; i++)
	{
		for (j = 0; j < nl; j++)
		{
			D[i][j] = ((DATA_TYPE) i*(j+2)) / nk;
		}
	}
}


void compareResults(int ni, int nl, DATA_TYPE POLYBENCH_2D(G, NI, NL, ni, nl), DATA_TYPE POLYBENCH_2D(G_outputFromGpu, NI, NL, ni, nl))
{
	int i,j,fail;
	fail = 0;

	for (i=0; i < ni; i++)
	{
		for (j=0; j < nl; j++)
		{
			if (percentDiff(G[i][j], G_outputFromGpu[i][j]) > PERCENT_DIFF_ERROR_THRESHOLD)
			{
				fail++;				
			}
		}
	}
	
	// print results
	printf("Non-Matching CPU-GPU Outputs Beyond Error Threshold of %4.2f Percent: %d\n", PERCENT_DIFF_ERROR_THRESHOLD, fail);
}


void GPU_argv_init()
{
	cudaDeviceProp deviceProp;
	cudaGetDeviceProperties(&deviceProp, GPU_DEVICE);
	//printf("setting device %d with name %s\n",GPU_DEVICE,deviceProp.name);
	cudaSetDevice( GPU_DEVICE );
}

	
__global__ void mm3_kernel1(int ni, int nj, int nk, int nl, int nm, DATA_TYPE *A, DATA_TYPE *B, DATA_TYPE *E)
{
	int j = blockIdx.x * blockDim.x + threadIdx.x;
	int i = blockIdx.y * blockDim.y + threadIdx.y;

	if ((i < _PB_NI) && (j < _PB_NJ))
	{
		E[i * NJ + j] = 0;
		int k;
		for(k=0; k < _PB_NK; k++)
		{
			E[i * NJ + j] += A[i * NK + k] * B[k * NJ + j];
		}
	}
}

	
__global__ void mm3_kernel2(int ni, int nj, int nk, int nl, int nm, DATA_TYPE *C, DATA_TYPE *D, DATA_TYPE *F)
{
	int j = blockIdx.x * blockDim.x + threadIdx.x;
	int i = blockIdx.y * blockDim.y + threadIdx.y;

	if ((i < _PB_NJ) && (j < _PB_NL))
	{
		F[i * NL + j] = 0;
		int k;
		for(k=0; k < _PB_NM; k++)
		{
			F[i * NL + j] += C[i * NM + k] * D[k * NL +j];
		}
	}
}

	
__global__ void mm3_kernel3(int ni, int nj, int nk, int nl, int nm, DATA_TYPE *E, DATA_TYPE *F, DATA_TYPE *G)
{
	int j = blockIdx.x * blockDim.x + threadIdx.x;
	int i = blockIdx.y * blockDim.y + threadIdx.y;

	if ((i < _PB_NI) && (j < _PB_NL))
	{
		G[i * NL + j] = 0;
		int k;
		for(k=0; k < _PB_NJ; k++)
		{
			G[i * NL + j] += E[i * NJ + k] * F[k * NL + j];
		}
	}
}


/* Main computational kernel on CPU */
void mm3_cpu(int ni, int nj, int nk, int nl, int nm,
		DATA_TYPE POLYBENCH_2D(E,NI,NJ,ni,nj),
		DATA_TYPE POLYBENCH_2D(A,NI,NK,ni,nk),
		DATA_TYPE POLYBENCH_2D(B,NK,NJ,nk,nj),
		DATA_TYPE POLYBENCH_2D(F,NJ,NL,nj,nl),
		DATA_TYPE POLYBENCH_2D(C,NJ,NM,nj,nm),
		DATA_TYPE POLYBENCH_2D(D,NM,NL,nm,nl),
		DATA_TYPE POLYBENCH_2D(G,NI,NL,ni,nl))
{
	int i, j, k;

	/* E := A*B */
	for (i = 0; i < _PB_NI; i++)
	{
		for (j = 0; j < _PB_NJ; j++)
		{
			E[i][j] = 0;
			for (k = 0; k < _PB_NK; ++k)
			{
				E[i][j] += A[i][k] * B[k][j];
			}
		}
	}

	/* F := C*D */
	for (i = 0; i < _PB_NJ; i++)
	{
		for (j = 0; j < _PB_NL; j++)
		{
			F[i][j] = 0;
			for (k = 0; k < _PB_NM; ++k)
			{
				F[i][j] += C[i][k] * D[k][j];
			}
		}
	}

	/* G := E*F */
	for (i = 0; i < _PB_NI; i++)
	{
		for (j = 0; j < _PB_NL; j++)
		{
			G[i][j] = 0;
			for (k = 0; k < _PB_NJ; ++k)
			{
				G[i][j] += E[i][k] * F[k][j];
			}
		}
	}
}


void mm3Cuda(int ni, int nj, int nk, int nl, int nm,
		DATA_TYPE POLYBENCH_2D(E,NI,NJ,ni,nj),
		DATA_TYPE POLYBENCH_2D(A,NI,NK,ni,nk),
		DATA_TYPE POLYBENCH_2D(B,NK,NJ,nk,nj),
		DATA_TYPE POLYBENCH_2D(F,NJ,NL,nj,nl),
		DATA_TYPE POLYBENCH_2D(C,NJ,NM,nj,nm),
		DATA_TYPE POLYBENCH_2D(D,NM,NL,nm,nl),
		DATA_TYPE POLYBENCH_2D(G,NI,NL,ni,nl),
		DATA_TYPE POLYBENCH_2D(G_outputFromGpu,NI,NL,ni,nl))
{
	DATA_TYPE *A_gpu;
	DATA_TYPE *B_gpu;
	DATA_TYPE *C_gpu;
	DATA_TYPE *D_gpu;
	DATA_TYPE *E_gpu;
	DATA_TYPE *F_gpu;
	DATA_TYPE *G_gpu;
	
	start = clock();
	cudaMalloc((void **)&A_gpu, sizeof(DATA_TYPE) * NI * NK);
	cudaMalloc((void **)&B_gpu, sizeof(DATA_TYPE) * NK * NJ);
	cudaMalloc((void **)&C_gpu, sizeof(DATA_TYPE) * NJ * NM);
	cudaMalloc((void **)&D_gpu, sizeof(DATA_TYPE) * NM * NL);
	cudaMalloc((void **)&E_gpu, sizeof(DATA_TYPE) * NI * NJ);
	cudaMalloc((void **)&F_gpu, sizeof(DATA_TYPE) * NJ * NL);
	cudaMalloc((void **)&G_gpu, sizeof(DATA_TYPE) * NI * NL);
	end = clock();
	t_malloc = (double)(end-start) / CLOCKS_PER_SEC;

	start = clock();
	cudaMemcpy(A_gpu, A, sizeof(DATA_TYPE) * NI * NK, cudaMemcpyHostToDevice);
	cudaMemcpy(B_gpu, B, sizeof(DATA_TYPE) * NK * NJ, cudaMemcpyHostToDevice);
	cudaMemcpy(C_gpu, C, sizeof(DATA_TYPE) * NJ * NM, cudaMemcpyHostToDevice);
	cudaMemcpy(D_gpu, D, sizeof(DATA_TYPE) * NM * NL, cudaMemcpyHostToDevice);
	cudaMemcpy(E_gpu, E, sizeof(DATA_TYPE) * NI * NJ, cudaMemcpyHostToDevice);
	cudaMemcpy(F_gpu, F, sizeof(DATA_TYPE) * NJ * NL, cudaMemcpyHostToDevice);
	cudaMemcpy(G_gpu, G, sizeof(DATA_TYPE) * NI * NL, cudaMemcpyHostToDevice);
	end = clock();
	t_write = (double)(end-start) / CLOCKS_PER_SEC;
		
	start = clock();	
	dim3 block(DIM_THREAD_BLOCK_X, DIM_THREAD_BLOCK_Y);
	dim3 grid1((size_t)(ceil( ((float)NJ) / ((float)DIM_THREAD_BLOCK_X) )),(size_t)(ceil((float)NI/ ((float)DIM_THREAD_BLOCK_Y) )));
	dim3 grid2((size_t)(ceil( ((float)NL) / ((float)DIM_THREAD_BLOCK_X) )),(size_t)(ceil((float)NJ/ ((float)DIM_THREAD_BLOCK_Y) )));
	dim3 grid3((size_t)(ceil( ((float)NL) / ((float)DIM_THREAD_BLOCK_X) )),(size_t)(ceil((float)NI/ ((float)DIM_THREAD_BLOCK_Y) )));
	end = clock();
	t_kdi = (double)(end-start) / CLOCKS_PER_SEC;

	/* Start timer. */
  	//polybench_start_instruments;
	start = clock();

	mm3_kernel1<<<grid1,block>>>(ni, nj, nk, nl, nm, A_gpu, B_gpu, E_gpu);
	cudaThreadSynchronize();
	mm3_kernel2<<<grid2,block>>>(ni, nj, nk, nl, nm, C_gpu, D_gpu, F_gpu);
	cudaThreadSynchronize();
	mm3_kernel3<<<grid3,block>>>(ni, nj, nk, nl, nm, E_gpu, F_gpu, G_gpu);
	cudaThreadSynchronize();

	/* Stop and print timer. */
	//printf("GPU Time in seconds:\n");
  	//polybench_stop_instruments;
 	//polybench_print_instruments;
	end = clock();
	t_kernel = (double)(end-start) / CLOCKS_PER_SEC;

	start = clock();
	cudaMemcpy(G_outputFromGpu, G_gpu, sizeof(DATA_TYPE) * NI * NL, cudaMemcpyDeviceToHost);
	end = clock();
	t_read = (double)(end-start) / CLOCKS_PER_SEC;
	
	start = clock();
	
	cudaFree(A_gpu);
	cudaFree(B_gpu);
	cudaFree(C_gpu);
	cudaFree(D_gpu);
	cudaFree(E_gpu);
	cudaFree(F_gpu);
	cudaFree(G_gpu);
	end = clock();
	t_clear = (double)(end-start) / CLOCKS_PER_SEC;
}


/* DCE code. Must scan the entire live-out data.
   Can be used also to check the correctness of the output. */
static
void print_array(int ni, int nl,
		 DATA_TYPE POLYBENCH_2D(G,NI,NL,ni,nl))
{
  int i, j;

  for (i = 0; i < ni; i++)
    for (j = 0; j < nl; j++) {
	fprintf (stderr, DATA_PRINTF_MODIFIER, G[i][j]);
	if ((i * ni + j) % 20 == 0) fprintf (stderr, "\n");
    }
  fprintf (stderr, "\n");
}


void *poly_main(void *x)
{
	start = clock();

	int ni = NI;
	int nj = NJ;
	int nk = NK;
	int nl = NL;
	int nm = NM;

	/* Variable declaration/allocation. */
	POLYBENCH_2D_ARRAY_DECL(E, DATA_TYPE, NI, NJ, ni, nj);
	POLYBENCH_2D_ARRAY_DECL(A, DATA_TYPE, NI, NK, ni, nk);
	POLYBENCH_2D_ARRAY_DECL(B, DATA_TYPE, NK, NJ, nk, nj);
	POLYBENCH_2D_ARRAY_DECL(F, DATA_TYPE, NJ, NL, nj, nl);
	POLYBENCH_2D_ARRAY_DECL(C, DATA_TYPE, NJ, NM, nj, nm);
	POLYBENCH_2D_ARRAY_DECL(D, DATA_TYPE, NM, NL, nm, nl);
	POLYBENCH_2D_ARRAY_DECL(G, DATA_TYPE, NI, NL, ni, nl);
	POLYBENCH_2D_ARRAY_DECL(G_outputFromGpu, DATA_TYPE, NI, NL, ni, nl);

	init_array(ni, nj, nk, nl, nm, POLYBENCH_ARRAY(A), POLYBENCH_ARRAY(B), POLYBENCH_ARRAY(C), POLYBENCH_ARRAY(D));

	end = clock();
	t_hdi += (double)(end-start) / CLOCKS_PER_SEC;

	start = clock();

	GPU_argv_init();

	end = clock();
	t_gset += (double)(end-start) / CLOCKS_PER_SEC;

	mm3Cuda(ni, nj, nk, nl, nm, POLYBENCH_ARRAY(A), POLYBENCH_ARRAY(B), POLYBENCH_ARRAY(C), POLYBENCH_ARRAY(D), POLYBENCH_ARRAY(E), 
		POLYBENCH_ARRAY(F), POLYBENCH_ARRAY(G), POLYBENCH_ARRAY(G_outputFromGpu));

	#ifdef RUN_ON_CPU

		/* Start timer. */
	  	polybench_start_instruments;

		mm3_cpu(ni, nj, nk, nl, nm, POLYBENCH_ARRAY(A), POLYBENCH_ARRAY(B), POLYBENCH_ARRAY(C), POLYBENCH_ARRAY(D), POLYBENCH_ARRAY(E), 
			POLYBENCH_ARRAY(F), POLYBENCH_ARRAY(G));
	
		/* Stop and print timer. */
		printf("CPU Time in seconds:\n");
	  	polybench_stop_instruments;
	 	polybench_print_instruments;

		compareResults(ni, nl, POLYBENCH_ARRAY(G), POLYBENCH_ARRAY(G_outputFromGpu));

	#else //prevent dead code elimination

		//polybench_prevent_dce(print_array(ni, nl, POLYBENCH_ARRAY(G_outputFromGpu)));

	#endif //RUN_ON_CPU

	start = clock();

	POLYBENCH_FREE_ARRAY(A);
	POLYBENCH_FREE_ARRAY(B);
	POLYBENCH_FREE_ARRAY(C);
	POLYBENCH_FREE_ARRAY(D);
	POLYBENCH_FREE_ARRAY(E);
	POLYBENCH_FREE_ARRAY(F);
	POLYBENCH_FREE_ARRAY(G);
	POLYBENCH_FREE_ARRAY(G_outputFromGpu);

	end = clock();
	t_clear += (double)(end-start) / CLOCKS_PER_SEC;

	printf("{\"hdi\": %lf, \"gset\": %lf, \"malloc\": %lf, \"write\": %lf, \"kdi\": %lf, \"kernel\": %lf, \"read\": %lf, \"clear\": %lf}",
		t_hdi, t_gset, t_malloc, t_write, t_kdi, t_kernel, t_read, t_clear);

	return 0;
}

int main()
{
	int tid, status;
	int *init_mem = 0;
	pthread_t thread_id;

	//start = clock();
	cudaSetDevice(0);
	cudaMalloc((void**)&init_mem, 4096 * sizeof(int));
	//end = clock();
	//printf("Master overhead: %lf\n",(double)(end-start) / CLOCKS_PER_SEC);

	tid = pthread_create(&thread_id, NULL, poly_main, NULL);
	pthread_join(thread_id, (void**)&status);

	cudaFree(init_mem);

	return 0;
}

#include <polybench.c>