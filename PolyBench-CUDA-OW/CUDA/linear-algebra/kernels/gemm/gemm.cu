/**
 * gemm.cu: This file is part of the PolyBench/GPU 1.0 test suite.
 *
 *
 * Contact: Scott Grauer-Gray <sgrauerg@gmail.com>
 * Will Killian <killian@udel.edu>
 * Louis-Noel Pouchet <pouchet@cse.ohio-state.edu>
 * Web address: http://www.cse.ohio-state.edu/~pouchet/software/polybench/GPU
 */

#include <unistd.h>
#include <stdio.h>
#include <time.h>
#include <sys/time.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <cuda.h>
#include <pthread.h>

#define POLYBENCH_TIME 1

#include "gemm.cuh"
#include <polybench.h>
#include <polybenchUtilFuncts.h>

#define GPU_DEVICE 0

//define the error threshold for the results "not matching"
#define PERCENT_DIFF_ERROR_THRESHOLD 0.05

//#define RUN_ON_CPU

// hdi=host_data_init, kdi=kernel-related_data_init gset=gpu_set, 
clock_t start, end;
double t_hdi, t_gset, t_malloc, t_write, t_kdi, t_kernel, t_read, t_clear;


void gemm(int ni, int nj, int nk, DATA_TYPE alpha, DATA_TYPE beta, DATA_TYPE POLYBENCH_2D(A,NI,NK,ni,nk), 
	 DATA_TYPE POLYBENCH_2D(B,NK,NJ,nk,nj), DATA_TYPE POLYBENCH_2D(C,NI,NJ,ni,nj))
{
	int i,j,k;
	
	for (i = 0; i < _PB_NI; i++)
	{
    		for (j = 0; j < _PB_NJ; j++)
    		{
			C[i][j] *= beta;
	
			for (k = 0; k < _PB_NK; ++k)
			{
	  			C[i][j] += alpha * A[i][k] * B[k][j];
			}
      		}
	}
}


void init(int ni, int nj, int nk, DATA_TYPE* alpha, DATA_TYPE* beta, DATA_TYPE POLYBENCH_2D(A,NI,NK,ni,nk), 
	DATA_TYPE POLYBENCH_2D(B,NK,NJ,nk,nj), DATA_TYPE POLYBENCH_2D(C,NI,NJ,ni,nj))
{
	int i, j;

	*alpha = 32412;
	*beta = 2123;

  	for (i = 0; i < ni; i++)
	{
    		for (j = 0; j < nk; j++)
		{
      			A[i][j] = ((DATA_TYPE) i*j) / NI;
		}
	}

  	for (i = 0; i < nk; i++)
	{
    		for (j = 0; j < nj; j++)
		{
      			B[i][j] = ((DATA_TYPE) i*j) / NI;
		}
	}

  	for (i = 0; i < ni; i++)
	{
    		for (j = 0; j < nj; j++)
		{
      			C[i][j] = ((DATA_TYPE) i*j) / NI;
		}
	}
}


void compareResults(int ni, int nj, DATA_TYPE POLYBENCH_2D(C,NI,NJ,ni,nj), DATA_TYPE POLYBENCH_2D(C_outputFromGpu,NI,NJ,ni,nj))
{
	int i, j, fail;
	fail = 0;
	
	// Compare CPU and GPU outputs
	for (i=0; i < ni; i++) 
	{
		for (j=0; j < nj; j++) 
		{
			if (percentDiff(C[i][j], C_outputFromGpu[i][j]) > PERCENT_DIFF_ERROR_THRESHOLD) 
			{
				fail++;
			}
		}
	}
	
	// Print results
	printf("Non-Matching CPU-GPU Outputs Beyond Error Threshold of %4.2f Percent: %d\n", PERCENT_DIFF_ERROR_THRESHOLD, fail);
}


void GPU_argv_init()
{
	cudaDeviceProp deviceProp;
	cudaGetDeviceProperties(&deviceProp, GPU_DEVICE);
	//printf("setting device %d with name %s\n",GPU_DEVICE,deviceProp.name);
	cudaSetDevice( GPU_DEVICE );
}


__global__ void gemm_kernel(int ni, int nj, int nk, DATA_TYPE alpha, DATA_TYPE beta, DATA_TYPE *a, DATA_TYPE *b, DATA_TYPE *c)
{
	int j = blockIdx.x * blockDim.x + threadIdx.x;
	int i = blockIdx.y * blockDim.y + threadIdx.y;

	if ((i < _PB_NI) && (j < _PB_NJ))
	{	
		c[i * NJ + j] *= beta;
		int k;
		for(k=0; k < _PB_NK; k++)
		{
			c[i * NJ + j] += alpha * a[i * NK + k] * b[k * NJ +j];
		}
	}
}


void gemmCuda(int ni, int nj, int nk, DATA_TYPE alpha, DATA_TYPE beta, DATA_TYPE POLYBENCH_2D(A,NI,NK,ni,nk), 
	DATA_TYPE POLYBENCH_2D(B,NK,NJ,nk,nj), DATA_TYPE POLYBENCH_2D(C,NI,NJ,ni,nj), DATA_TYPE POLYBENCH_2D(C_outputFromGpu,NI,NJ,ni,nj))
{
	DATA_TYPE *A_gpu;
	DATA_TYPE *B_gpu;
	DATA_TYPE *C_gpu;

	start = clock();
	cudaMalloc((void **)&A_gpu, sizeof(DATA_TYPE) * NI * NK);
	cudaMalloc((void **)&B_gpu, sizeof(DATA_TYPE) * NK * NJ);
	cudaMalloc((void **)&C_gpu, sizeof(DATA_TYPE) * NI * NJ);
	end = clock();
	t_malloc = (double)(end-start) / CLOCKS_PER_SEC;

	start = clock();
	cudaMemcpy(A_gpu, A, sizeof(DATA_TYPE) * NI * NK, cudaMemcpyHostToDevice);
	cudaMemcpy(B_gpu, B, sizeof(DATA_TYPE) * NK * NJ, cudaMemcpyHostToDevice);
	cudaMemcpy(C_gpu, C, sizeof(DATA_TYPE) * NI * NJ, cudaMemcpyHostToDevice);
	end = clock();
	t_write = (double)(end-start) / CLOCKS_PER_SEC;
		
	start = clock();
	dim3 block(DIM_THREAD_BLOCK_X, DIM_THREAD_BLOCK_Y);
	dim3 grid((size_t)(ceil( ((float)NI)/ ((float)block.x) )),(size_t)(ceil( ((float)NJ)/ ((float)block.y) )));
	end = clock();
	t_kdi = (double)(end-start) / CLOCKS_PER_SEC;

	/* Start timer. */
  	//polybench_start_instruments;
	start = clock();

	gemm_kernel<<< grid, block >>>(ni, nj, nk, alpha, beta, A_gpu, B_gpu, C_gpu);
	cudaThreadSynchronize();

	/* Stop and print timer. */
	//printf("GPU Time in seconds:\n");
  	//polybench_stop_instruments;
 	//polybench_print_instruments;
	end = clock();
	t_kernel = (double)(end-start) / CLOCKS_PER_SEC;

	start = clock();
	cudaMemcpy(C_outputFromGpu, C_gpu, sizeof(DATA_TYPE) * NI * NJ, cudaMemcpyDeviceToHost);    
	end = clock();
	t_read = (double)(end-start) / CLOCKS_PER_SEC;
	
	start = clock();
	cudaFree(A_gpu);
	cudaFree(B_gpu);
	cudaFree(C_gpu);
	end = clock();
	t_clear = (double)(end-start) / CLOCKS_PER_SEC;
}


/* DCE code. Must scan the entire live-out data.
   Can be used also to check the correctness of the output. */
static
void print_array(int ni, int nj,
		 DATA_TYPE POLYBENCH_2D(C,NI,NJ,ni,nj))
{
  int i, j;

  for (i = 0; i < ni; i++)
    for (j = 0; j < nj; j++) {
	fprintf (stderr, DATA_PRINTF_MODIFIER, C[i][j]);
	if ((i * ni + j) % 20 == 0) fprintf (stderr, "\n");
    }
  fprintf (stderr, "\n");
}


void *poly_main(void *x)
{
	start = clock();
	/* Retrieve problem size. */
	int ni = NI;
	int nj = NJ;
	int nk = NK;

	/* Variable declaration/allocation. */
	DATA_TYPE alpha;
	DATA_TYPE beta;
	POLYBENCH_2D_ARRAY_DECL(A,DATA_TYPE,NI,NK,ni,nk);
	POLYBENCH_2D_ARRAY_DECL(B,DATA_TYPE,NK,NJ,nk,nj);
	POLYBENCH_2D_ARRAY_DECL(C,DATA_TYPE,NI,NJ,ni,nj);
	POLYBENCH_2D_ARRAY_DECL(C_outputFromGpu,DATA_TYPE,NI,NJ,ni,nj);

	init(ni, nj, nk, &alpha, &beta, POLYBENCH_ARRAY(A), POLYBENCH_ARRAY(B), POLYBENCH_ARRAY(C));

	end = clock();
	t_hdi += (double)(end-start) / CLOCKS_PER_SEC;

	start = clock();
	
	GPU_argv_init();

	end = clock();
	t_gset += (double)(end-start) / CLOCKS_PER_SEC;
	
	gemmCuda(ni, nj, nk, alpha, beta, POLYBENCH_ARRAY(A), POLYBENCH_ARRAY(B), POLYBENCH_ARRAY(C), POLYBENCH_ARRAY(C_outputFromGpu));


	#ifdef RUN_ON_CPU

		/* Start timer. */
	  	polybench_start_instruments;

		gemm(ni, nj, nk, alpha, beta, POLYBENCH_ARRAY(A), POLYBENCH_ARRAY(B), POLYBENCH_ARRAY(C));
		
		/* Stop and print timer. */
		printf("CPU Time in seconds:\n");
  		polybench_stop_instruments;
	 	polybench_print_instruments;
	
		compareResults(ni, nj, POLYBENCH_ARRAY(C), POLYBENCH_ARRAY(C_outputFromGpu));

	#else //prevent dead code elimination

		//polybench_prevent_dce(print_array(ni, nj, POLYBENCH_ARRAY(C_outputFromGpu)));

	#endif //RUN_ON_CPU

	start = clock();

	POLYBENCH_FREE_ARRAY(A);
	POLYBENCH_FREE_ARRAY(B);  
	POLYBENCH_FREE_ARRAY(C);  
	POLYBENCH_FREE_ARRAY(C_outputFromGpu);

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