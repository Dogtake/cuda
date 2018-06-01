#include <stdlib.h>
#include <stdio.h>
#include <string>
#include <time.h>
#include <cuda.h>
#include <math.h>

__global__ void HashingKernel(int key,int value){
}

int main(){
	int i;
	int input_size;
	int s;
	int t;
	int n;
	int p;
	int bound_length;
	int *a_list;
	int *b_list;
	int *hash_table;	
	int *cuda_a_list;
	int *cuda_b_list;
	int *cuda_hash_table;

	s = 10;
	input_size = 2^s;
	t = 2;
	n = 2^25;
	p = 218641;
	bound_length = 4*log(n);

	cudaMalloc((void **) &cuda_a_list,sizeof(int)*t);
	cudaMalloc((void **) &cuda_b_list,sizeof(int)*t);
	cudaMalloc((void **) &cuda_hash_table,sizeof(int)*n);

	a_list = (int*)malloc(sizeof(int)*t);
	b_list = (int*)malloc(sizeof(int)*t);
	hash_table = (int*)malloc(sizeof(int)*n);

	for (i = 0;i < t;i++){
		a_list[i] = rand();
		b_list[i] = rand();
	}

	cudaMemcpy(cuda_a_list,a_list,sizeof(int)*t,cudaMemcpyHostToDevice);
	cudaMemcpy(cuda_b_list,b_list,sizeof(int)*t,cudaMemcpyHostToDevice);


	free(a_list);
	free(b_list);
	free(hash_table);
	cudaFree(cuda_a_list);
	cudaFree(cuda_b_list);
	cudaFree(cuda_hash_table);
	return 0;
}
