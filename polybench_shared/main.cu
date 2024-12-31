#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <dlfcn.h>

int main(void)
{
	int *temp = 0;
	clock_t start, end;

	void *handle_2mm;
	void *handle_3mm;
	void *handle_atax;
	void *handle_bicg;
	void *handle_doitgen;
	void *handle_gemm;
	void *handle_gemver;
	void *handle_gesummv;
	void *handle_mvt;
	void *handle_syr2k;
	void *handle_syrk;
	void *handle_adi;
	void *handle_conv2d;
	void *handle_conv3d;
	void *handle_fdtd;
	void *handle_jacobi1d;
	void *handle_jacobi2d;

	int (*test_2mm)(int);
	int (*test_3mm)(int);
	int (*test_atax)(int);
	int (*test_bicg)(int);
	int (*test_doitgen)(int);
	int (*test_gemm)(int);
	int (*test_gemver)(int);
	int (*test_gesummv)(int);
	int (*test_mvt)(int);
	int (*test_syr2k)(int);
	int (*test_syrk)(int);
	int (*test_adi)(int);
	int (*test_conv2d)(int);
	int (*test_conv3d)(int);
	int (*test_fdtd)(int);
	int (*test_jacobi1d)(int);
	int (*test_jacobi2d)(int);

	start = clock();
	cudaSetDevice(0);
	cudaMalloc((void**)&temp, sizeof(int));
	end = clock();

	printf("Wait 1 seconds\n");
	usleep(1000000);



	/* 2mm */
	handle_2mm = dlopen("./2mm.so", RTLD_LAZY);
	if (!handle_2mm) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	dlerror();

	*(void **)(&test_2mm) = dlsym(handle_2mm, "_Z8main_2mmi");

	handle_2mm = dlopen("./2mm.so", RTLD_LAZY);
	if (!handle_2mm) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	(*test_2mm)(5);
	dlclose(handle_2mm);


	/* 3mm */
	handle_3mm = dlopen("./3mm.so", RTLD_LAZY);
	if (!handle_3mm) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	dlerror();

	*(void **)(&test_3mm) = dlsym(handle_3mm, "_Z8main_3mmi");

	handle_3mm = dlopen("./3mm.so", RTLD_LAZY);
	if (!handle_3mm) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	(*test_3mm)(5);
	dlclose(handle_3mm);


	/* atax */
	handle_atax = dlopen("./atax.so", RTLD_LAZY);
	if (!handle_atax) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	dlerror();

	*(void **)(&test_atax) = dlsym(handle_atax, "_Z9main_ataxi");

	handle_atax = dlopen("./atax.so", RTLD_LAZY);
	if (!handle_atax) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	(*test_atax)(5);
	dlclose(handle_atax);


	/* bicg */
	handle_bicg = dlopen("./bicg.so", RTLD_LAZY);
	if (!handle_bicg) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	dlerror();

	*(void **)(&test_bicg) = dlsym(handle_bicg, "_Z9main_bicgi");

	handle_bicg = dlopen("./bicg.so", RTLD_LAZY);
	if (!handle_bicg) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	(*test_bicg)(5);
	dlclose(handle_bicg);


	/* doitgen */
	handle_doitgen = dlopen("./doitgen.so", RTLD_LAZY);
	if (!handle_doitgen) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	dlerror();

	*(void **)(&test_doitgen) = dlsym(handle_doitgen, "_Z12main_doitgeni");

	handle_doitgen = dlopen("./doitgen.so", RTLD_LAZY);
	if (!handle_doitgen) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	(*test_doitgen)(5);
	dlclose(handle_doitgen);


	/* gemm */
	handle_gemm = dlopen("./gemm.so", RTLD_LAZY);
	if (!handle_gemm) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	dlerror();

	*(void **)(&test_gemm) = dlsym(handle_gemm, "_Z9main_gemmi");

	handle_gemm = dlopen("./gemm.so", RTLD_LAZY);
	if (!handle_gemm) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	(*test_gemm)(5);
	dlclose(handle_gemm);


	/* gemver */
	handle_gemver = dlopen("./gemver.so", RTLD_LAZY);
	if (!handle_gemver) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	dlerror();

	*(void **)(&test_gemver) = dlsym(handle_gemver, "_Z11main_gemveri");

	handle_gemver = dlopen("./gemver.so", RTLD_LAZY);
	if (!handle_gemver) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	(*test_gemver)(5);
	dlclose(handle_gemver);


	/* gesummv */
	handle_gesummv = dlopen("./gesummv.so", RTLD_LAZY);
	if (!handle_gesummv) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	dlerror();

	*(void **)(&test_gesummv) = dlsym(handle_gesummv, "_Z12main_gesummvi");

	handle_gesummv = dlopen("./gesummv.so", RTLD_LAZY);
	if (!handle_gesummv) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	(*test_gesummv)(5);
	dlclose(handle_gesummv);


	/* mvt */
	handle_mvt = dlopen("./mvt.so", RTLD_LAZY);
	if (!handle_mvt) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	dlerror();

	*(void **)(&test_mvt) = dlsym(handle_mvt, "_Z8main_mvti");

	handle_mvt = dlopen("./mvt.so", RTLD_LAZY);
	if (!handle_mvt) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	(*test_mvt)(5);
	dlclose(handle_mvt);


	/* syr2k */
	handle_syr2k = dlopen("./syr2k.so", RTLD_LAZY);
	if (!handle_syr2k) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	dlerror();

	*(void **)(&test_syr2k) = dlsym(handle_syr2k, "_Z10main_syr2ki");

	handle_syr2k = dlopen("./syr2k.so", RTLD_LAZY);
	if (!handle_syr2k) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	(*test_syr2k)(5);
	dlclose(handle_syr2k);


	/* syrk */
	handle_syrk = dlopen("./syrk.so", RTLD_LAZY);
	if (!handle_syrk) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	dlerror();

	*(void **)(&test_syrk) = dlsym(handle_syrk, "_Z9main_syrki");

	handle_syrk = dlopen("./syrk.so", RTLD_LAZY);
	if (!handle_syrk) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	(*test_syrk)(5);
	dlclose(handle_syrk);


	/* adi */
	handle_adi = dlopen("./adi.so", RTLD_LAZY);
	if (!handle_adi) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	dlerror();

	*(void **)(&test_adi) = dlsym(handle_adi, "_Z8main_adii");

	handle_adi = dlopen("./adi.so", RTLD_LAZY);
	if (!handle_adi) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	(*test_adi)(5);
	dlclose(handle_adi);


	/* conv2d */
	handle_conv2d = dlopen("./2DConvolution.so", RTLD_LAZY);
	if (!handle_conv2d) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	dlerror();

	*(void **)(&test_conv2d) = dlsym(handle_conv2d, "_Z11main_conv2di");

	handle_conv2d = dlopen("./2DConvolution.so", RTLD_LAZY);
	if (!handle_conv2d) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	(*test_conv2d)(5);
	dlclose(handle_conv2d);


	/* conv3d */
	handle_conv3d = dlopen("./3DConvolution.so", RTLD_LAZY);
	if (!handle_conv3d) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	dlerror();

	*(void **)(&test_conv3d) = dlsym(handle_conv3d, "_Z11main_conv3di");

	handle_conv3d = dlopen("./3DConvolution.so", RTLD_LAZY);
	if (!handle_conv3d) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	(*test_conv3d)(5);
	dlclose(handle_conv3d);


	/* fdtd */
	handle_fdtd = dlopen("./fdtd2d.so", RTLD_LAZY);
	if (!handle_fdtd) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	dlerror();

	*(void **)(&test_fdtd) = dlsym(handle_fdtd, "_Z9main_fdtdi");

	handle_fdtd = dlopen("./fdtd2d.so", RTLD_LAZY);
	if (!handle_fdtd) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	printf("%d main time = %lf\n", (*test_fdtd)(5), (float)(end-start)/CLOCKS_PER_SEC);
	dlclose(handle_fdtd);


	/* jacobi1d */
	handle_jacobi1d = dlopen("./jacobi1D.so", RTLD_LAZY);
	if (!handle_jacobi1d) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	dlerror();

	*(void **)(&test_jacobi1d) = dlsym(handle_jacobi1d, "_Z13main_jacobi1di");

	handle_jacobi1d = dlopen("./jacobi1D.so", RTLD_LAZY);
	if (!handle_jacobi1d) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	printf("%d main time = %lf\n", (*test_jacobi1d)(5), (float)(end-start)/CLOCKS_PER_SEC);
	dlclose(handle_jacobi1d);


	/* jacobi2d */
	handle_jacobi2d = dlopen("./jacobi2D.so", RTLD_LAZY);
	if (!handle_jacobi2d) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	dlerror();

	*(void **)(&test_jacobi2d) = dlsym(handle_jacobi2d, "_Z13main_jacobi2di");

	handle_jacobi2d = dlopen("./jacobi2D.so", RTLD_LAZY);
	if (!handle_jacobi2d) {
		fprintf(stderr, "%s\n", dlerror());
		exit(EXIT_FAILURE);
	}

	printf("%d main time = %lf\n", (*test_jacobi2d)(5), (float)(end-start)/CLOCKS_PER_SEC);
	dlclose(handle_jacobi2d);


	return 0;
}

