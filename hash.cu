#include <stdlib.h>
#include <stdio.h>
#include <string>
#include <time.h>
#include <cuda.h>
#include <math.h>

__global__ void HashingKernel(int *cuda_hash_table,int *cuda_a_list, int *cuda_b_list, int cuda_p, int *random_value){
	int key = threadIdx.x + blockDim.x*blockIdx.x;
	int value = random_value[key];
	//printf("key = %d, value = %d\n",key,value);

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
	int *random_value;
	int *hash_table;	
	int *cuda_a_list;
	int *cuda_b_list;
	int *cuda_random_value;
	int *cuda_hash_table;
	int block_num;
	int block_size;

	s = 10;
	input_size = pow(2,s);
	t = 2;
	n = pow(2,25);
	p = 75000103;
	bound_length = (int)4*log(n);
	block_num = input_size/256;
	block_size = 256;
	printf("input_size = %d\n",input_size);

	cudaMalloc((void **) &cuda_a_list,sizeof(int)*t);
	cudaMalloc((void **) &cuda_b_list,sizeof(int)*t);
	cudaMalloc((void **) &cuda_hash_table,sizeof(int)*n);
	cudaMalloc((void **) &cuda_random_value,sizeof(int)*input_size);

	a_list = (int*)malloc(sizeof(int)*t);
	b_list = (int*)malloc(sizeof(int)*t);
	hash_table = (int*)malloc(sizeof(int)*n);
	random_value = (int*)malloc(sizeof(int)*input_size);

	srand(0);
	for (i = 0;i < t;i++){
		a_list[i] = rand()%1000;
		b_list[i] = rand()%1000;
		//printf("%d\n",a_list[i]);
	}
	for (i = 0;i < input_size;i++){
		random_value[i] = rand();
		//printf("%d\n",random_value[i]);
	}

	cudaMemcpy(cuda_a_list,a_list,sizeof(int)*t,cudaMemcpyHostToDevice);
	cudaMemcpy(cuda_b_list,b_list,sizeof(int)*t,cudaMemcpyHostToDevice);
	cudaMemcpy(cuda_random_value,random_value,sizeof(int)*input_size,cudaMemcpyHostToDevice);


	HashingKernel<<<block_num,block_size>>>(cuda_hash_table,cuda_a_list,cuda_b_list,p,cuda_random_value);

	cudaMemcpy(hash_table,cuda_hash_table,sizeof(int)*n,cudaMemcpyDeviceToHost);

	free(a_list);
	free(b_list);
	free(hash_table);
	free(random_value);
	cudaFree(cuda_a_list);
	cudaFree(cuda_b_list);
	cudaFree(cuda_hash_table);
	cudaFree(cuda_random_value);
	return 0;
}
