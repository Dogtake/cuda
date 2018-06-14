#include <stdlib.h>
#include <stdio.h>
#include <string>
#include <time.h>
#include <cuda.h>
#include <math.h>

__global__ void HashingKernel(int *cuda_hash_table,int *cuda_a_list, int *cuda_b_list, int *cuda_random_value,int* cuda_func_index, int n, int p,int *cuda_kicked_list,int t,int flag){
	int key = threadIdx.x + blockDim.x*blockIdx.x;
	int index = cuda_func_index[key];
	unsigned int hash_value = (unsigned(cuda_a_list[index] * cuda_random_value[key] * cuda_random_value[key] + cuda_b_list[index]* cuda_random_value[key]* +cuda_b_list[index]) % p) % n;
	// unsigned int hash_value = (unsigned(cuda_a_list[index] * cuda_random_value[key] +cuda_b_list[index]) % p) % n;
	// printf("hash_value=%d\n",hash_value );
	if (cuda_kicked_list[key]==1 || flag==0){
		
		cuda_hash_table[hash_value] = cuda_random_value[key];
		cuda_func_index[key] = (cuda_func_index[key] + 1) % t;
		
	}
}
__global__ void CheckKickKernel(int *cuda_hash_table,int *cuda_a_list, int *cuda_b_list, int *cuda_random_value,int* cuda_func_index, int n, int p,int *cuda_kicked_list,int t){
	int key = threadIdx.x + blockDim.x*blockIdx.x;
	int index = (cuda_func_index[key]+t-1)%t;
	unsigned int hash_value = (unsigned(cuda_a_list[index] * cuda_random_value[key] * cuda_random_value[key] + cuda_b_list[index]* cuda_random_value[key]* +cuda_b_list[index]) % p) % n;
	// unsigned int hash_value = (unsigned(cuda_a_list[index] * cuda_random_value[key] +cuda_b_list[index]) % p) % n;
	if (cuda_hash_table[hash_value]==cuda_random_value[key]){
		cuda_kicked_list[key] = 0;
	}else{
		cuda_kicked_list[key] = 1;
	}
}

__global__ void LookUpKernel(int *cuda_hash_table,int *cuda_a_list,int *cuda_b_list, int t,int n,int p, int *cuda_lookup_table,int *cuda_results){
	int key = threadIdx.x + blockDim.x*blockIdx.x;
	int i,hash_value;

	for(i = 0;i < t;i++){
		hash_value = (unsigned(cuda_a_list[i] * unsigned(cuda_lookup_table[key]) + cuda_b_list[i]) % p) % n;
		if (cuda_hash_table[hash_value] == cuda_lookup_table[key]){
			cuda_results[key] = 1;
			break;
		}
	}
}

int main(int argc,char const *argv[]){
	int i;
	unsigned int input_size;
	unsigned int s;
	int t;
	unsigned int n;
	unsigned int p;
	unsigned int bound_length;
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
	int flag;
	int len;
	float ts;
	clock_t start,end;
	

	s = atoi(argv[1]);
	t = atoi(argv[2]);
	ts = (float)strtod(argv[4],NULL);
	len = atoi(argv[5]);

	input_size = pow(2,s);
	if (s == 24 ){
		if (t==2){
			input_size-=pow(2,22);
		}else if (t == 3){
			input_size-=pow(2,15);
		}
	}
	n = (int)(input_size*ts);
	p = 85000173;
	bound_length = len*(int)log(n);
	block_num = input_size/256;
	block_size = 256;


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
		a_list[i] = (unsigned)rand()%10000;
		b_list[i] = (unsigned)rand()%10000;
		while (a_list[i]==0){
			a_list[i]=(unsigned)rand();
		}
		while (b_list[i]==0){
			b_list[i]=(unsigned)rand();
		}
	}
	for (i = 0;i < input_size;i++){
		random_value[i] =unsigned( rand());
		while (random_value[i]==0) {
			random_value[i] = unsigned(rand());
		}
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
	int base = pow(2,24);
	start=clock();
	int first = 0;
	while(1){
		if (first == 0){
			flag = 0;
		}else{
			flag =1;
		}
		sum = 0;
		first = 1;
		HashingKernel<<<block_num,block_size>>>(cuda_hash_table,cuda_a_list,cuda_b_list,cuda_random_value,cuda_func_index,n,p,cuda_kicked_list,t,flag);
		CheckKickKernel<<<block_num,block_size>>>(cuda_hash_table,cuda_a_list,cuda_b_list,cuda_random_value,cuda_func_index,n,p,cuda_kicked_list,t);
		cudaMemcpy(kicked_list,cuda_kicked_list,sizeof(int)*input_size,cudaMemcpyDeviceToHost);
		for (i = 0;i<input_size;i++){
			sum+=kicked_list[i];
		}
		// printf("sum=%d,base=%d\n",sum,base);
		if(sum < base){
			count = 0;
			base = sum;
		}else{
			count += 1;
		}
		// printf("base = %d\n",base );
		if (sum == 0){
			break;
		}
		if(count > bound_length){
			count = 0;
			first = 0;
			// printf("------------------------Restart!------------------------\n");
			base = pow(2,24);
			for (i = 0;i < t;i++){
				a_list[i] = rand();
				b_list[i] = rand();
				while (a_list[i]==0){
					a_list[i]=rand();
				}
				while (b_list[i]==0){
					b_list[i]=rand();
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
	end=clock();	
	cudaMemcpy(hash_table,cuda_hash_table,sizeof(int)*n,cudaMemcpyDeviceToHost);
	cudaMemcpy(func_index,cuda_func_index,sizeof(int)*input_size,cudaMemcpyDeviceToHost);

	
	printf("%f\n",(double)(end-start)/CLOCKS_PER_SEC );
	//##########################################################################################
	// Experiment 2
	// printf("%d\n", input_size);
	if (argc == 4 && input_size>pow(2,23)){
		int counter;
		float percent = float(100-10*atoi(argv[3]))/100.0;
		int *results;
		int *lookup_table;
		int *cuda_results;
		int *cuda_lookup_table;

		// printf("Insertion Finished. Start Exp2:\n");
		// printf("percent=%f\n",percent );

		lookup_table  = (int*)malloc(sizeof(int)*input_size);
		results = (int *)malloc(sizeof(int)*input_size);
		memset(lookup_table,0,sizeof(int)*input_size);
		memset(results,0,sizeof(int)*input_size);
		
		cudaMalloc((void **) &cuda_results,sizeof(int)*input_size);
		cudaMalloc((void **) &cuda_lookup_table,sizeof(int)*input_size);

		for (i=0;i<input_size;i++){
			if (i<(int)(input_size*percent)){
				lookup_table[i] = random_value[rand()%input_size];
			}else{
				lookup_table[i] = rand();
			}
		}	
		cudaMemcpy(cuda_results,results,sizeof(int)*input_size,cudaMemcpyHostToDevice);
		cudaMemcpy(cuda_lookup_table,lookup_table,sizeof(int)*input_size,cudaMemcpyHostToDevice);
		
		counter = 0;

		start = clock();
		LookUpKernel<<<block_num,block_size>>>(cuda_hash_table,cuda_a_list,cuda_b_list,t,n,p,cuda_lookup_table,cuda_results);
		end = clock();

		cudaMemcpy(results,cuda_results,sizeof(int)*input_size,cudaMemcpyDeviceToHost);
		for(i =0;i<input_size;i++){
			counter +=  results[i];
		}
		if (counter>=(int)(input_size*percent)){
			// printf("counter = %d,percent = %d\n", counter,(int)(input_size*percent));
			printf("%f\n",(double)(end-start)/CLOCKS_PER_SEC);
		}
		
		free(lookup_table);
		free(results);
		cudaFree(cuda_results);
		cudaFree(cuda_lookup_table);
	}



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
