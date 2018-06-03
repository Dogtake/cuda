#include <stdlib.h>
#include <stdio.h>
#include <string>
#include <time.h>
#include <cuda.h>
#include <math.h>

__global__ void HashingKernel(int *cuda_hash_table,int *cuda_a_list, int *cuda_b_list, int *cuda_random_value,int* cuda_func_index, int n, int p,int *cuda_kicked_list,int t){
	int key = threadIdx.x + blockDim.x*blockIdx.x;
	int index = cuda_func_index[key];
	int hash_value = ((cuda_a_list[index] * cuda_random_value[key] + cuda_b_list[index]) % p) % n;
	// if (key==16777217)
	// 	printf("%d,%d\n",cuda_a_list[index] * cuda_random_value[key] + cuda_b_list[index],hash_value);
	if (cuda_kicked_list[key]==1 || cuda_hash_table[hash_value]==0){
		
		cuda_hash_table[hash_value] = cuda_random_value[key];
		cuda_func_index[key] = (cuda_func_index[key] + 1) % t;
	}
}
__global__ void CheckKickKernel(int *cuda_hash_table,int *cuda_a_list, int *cuda_b_list, int *cuda_random_value,int* cuda_func_index, int n, int p,int *cuda_kicked_list,int t){
	int key = threadIdx.x + blockDim.x*blockIdx.x;
	int index = (cuda_func_index[key]+t-1)%t;
	int hash_value = ((cuda_a_list[index] * cuda_random_value[key] + cuda_b_list[index]) % p) % n;

	if (cuda_hash_table[hash_value]==cuda_random_value[key]){
		cuda_kicked_list[key] = 0;
	}else{
		cuda_kicked_list[key] = 1;
	}
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
	int *kicked_list;
	int *hash_table;
	int *func_index;	
	int *cuda_a_list;
	int *cuda_b_list;
	int *cuda_random_value;
	int *cuda_hash_table;
	int *cuda_kicked_list;
	int *cuda_func_index;
	int block_num;
	int block_size;
	int sum;


	s = 20;
	input_size = pow(2,s);
	t = 2;
	n = pow(2,25);
	p = 75000103;
	bound_length = (int)4*log(n);
	block_num = input_size/256;
	// printf("block_num=%d\n", block_num);
	block_size = 256;

	// printf("input_size=%d\n", input_size);
	// printf("n=%d\n",n);

	cudaMalloc((void **) &cuda_a_list,sizeof(int)*t);
	cudaMalloc((void **) &cuda_b_list,sizeof(int)*t);
	cudaMalloc((void **) &cuda_hash_table,sizeof(int)*n);
	cudaMalloc((void **) &cuda_random_value,sizeof(int)*input_size);
	cudaMalloc((void **) &cuda_kicked_list,sizeof(int)*input_size);
	cudaMalloc((void **) &cuda_func_index,sizeof(int)*input_size);

	a_list = (int*)malloc(sizeof(int)*t);
	b_list = (int*)malloc(sizeof(int)*t);
	hash_table = (int*)malloc(sizeof(int)*n);
	random_value = (int*)malloc(sizeof(int)*input_size);
	kicked_list = (int*)malloc(sizeof(int)*input_size);
	func_index = (int*)malloc(sizeof(int)*input_size);

	srand(time(0));
	for (i = 0;i < t;i++){
		a_list[i] = rand()%100;
		b_list[i] = rand()%100;
		while (a_list[i]==0){
			a_list[i]=rand()%100;
		}
		while (b_list[i]==0){
			b_list[i]=rand()%100;
		}
	}
	for (i = 0;i < input_size;i++){
		random_value[i] = rand()%1000000;
		while (random_value[i]==0) {
			random_value[i] = rand()%1000000;
		}
		// printf("random_value[%d]=%d\n",i,random_value[i] );
	}
	memset(hash_table,0,sizeof(int)*n);
	memset(kicked_list,0,sizeof(int)*input_size);
	memset(func_index,0,sizeof(int)*input_size);

	cudaMemcpy(cuda_a_list,a_list,sizeof(int)*t,cudaMemcpyHostToDevice);
	cudaMemcpy(cuda_b_list,b_list,sizeof(int)*t,cudaMemcpyHostToDevice);
	cudaMemcpy(cuda_hash_table,hash_table,sizeof(int)*n,cudaMemcpyHostToDevice);
	cudaMemcpy(cuda_random_value,random_value,sizeof(int)*input_size,cudaMemcpyHostToDevice);
	cudaMemcpy(cuda_kicked_list,kicked_list,sizeof(int)*input_size,cudaMemcpyHostToDevice);
	cudaMemcpy(cuda_func_index,func_index,sizeof(int)*input_size,cudaMemcpyHostToDevice);

	int count = 0;
	while(1){
		sum = 0;
		HashingKernel<<<block_num,block_size>>>(cuda_hash_table,cuda_a_list,cuda_b_list,cuda_random_value,cuda_func_index,n,p,cuda_kicked_list,t);
		// cudaMemcpy(hash_table,cuda_hash_table,sizeof(int)*n,cudaMemcpyDeviceToHost);
		// for (i=0;i<n;i++){
		// 	// printf("hash_table[%d]=%d\n",i,hash_table[i] );
		// 	if (hash_table[i]!=0){
		// 		printf("there is conflict\n");
		// 	}
		// }
		// break;
		CheckKickKernel<<<block_num,block_size>>>(cuda_hash_table,cuda_a_list,cuda_b_list,cuda_random_value,cuda_func_index,n,p,cuda_kicked_list,t);
		cudaMemcpy(kicked_list,cuda_kicked_list,sizeof(int)*input_size,cudaMemcpyDeviceToHost);
		for (i = 0;i<input_size;i++){
			sum+=kicked_list[i];
		}
		printf("sum = %d\n",sum );
		if (sum == 0){
			break;
		}
		count += 1;
		if(count == bound_length){
			count = 0;
			printf("------------------------Restart!------------------------\n");
			for (i = 0;i < t;i++){
				a_list[i] = rand()%1000;
				b_list[i] = rand()%1000;
				while (a_list[i]==0){
					a_list[i]=rand()%1000;
				}
				while (b_list[i]==0){
					b_list[i]=rand()%1000;
				}
			}
			memset(hash_table,0,sizeof(int)*n);
			memset(kicked_list,0,sizeof(int)*input_size);
			memset(func_index,0,sizeof(int)*input_size);

			cudaMemcpy(cuda_a_list,a_list,sizeof(int)*t,cudaMemcpyHostToDevice);
			cudaMemcpy(cuda_b_list,b_list,sizeof(int)*t,cudaMemcpyHostToDevice);
			cudaMemcpy(cuda_hash_table,hash_table,sizeof(int)*n,cudaMemcpyHostToDevice);
			cudaMemcpy(cuda_kicked_list,kicked_list,sizeof(int)*input_size,cudaMemcpyHostToDevice);
			cudaMemcpy(cuda_func_index,func_index,sizeof(int)*input_size,cudaMemcpyHostToDevice);
		}
	}

	cudaMemcpy(hash_table,cuda_hash_table,sizeof(int)*n,cudaMemcpyDeviceToHost);
	cudaMemcpy(func_index,cuda_func_index,sizeof(int)*input_size,cudaMemcpyDeviceToHost);
	int index = (func_index[0]+t-1)%t;
	printf("index=%d\n", index);
	int hash_value=((a_list[index] * random_value[0] + b_list[index]) % p) % n;
	printf("hash_value=%d\n",hash_value );
	if(hash_table[hash_value]==random_value[0])
		printf("Rigth anwser!\n");

	free(a_list);
	free(b_list);
	free(hash_table);
	free(random_value);
	free(func_index);
	free(kicked_list);
	cudaFree(cuda_a_list);
	cudaFree(cuda_b_list);
	cudaFree(cuda_hash_table);
	cudaFree(cuda_random_value);
	cudaFree(cuda_func_index);
	cudaFree(cuda_kicked_list);
	return 0;
}
