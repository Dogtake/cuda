#include <stdlib.h>
#include <stdio.h>
#include <string>
#include <time.h>

__global__ void hashing(){
}

int main(){
	int input_size;
	int t;
	int n;
	int p;
	int *a_list;
	int *b_list;
	int *hash_table;	

	t = 2;
	a_list = (int*)malloc(sizeof(int)*t);
	b_list = (int*)malloc(sizeof(int)*t);
	hash_table = (int*)malloc(sizeof(int)*n);
	free(a_list);
	free(b_list);
	free(hash_table);
	return 0;
}
