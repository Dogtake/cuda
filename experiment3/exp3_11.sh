nvcc hash3.cu -o run
echo 24 3 0 1.1
for ((i=0;i<5;i++));
do
	./run 24 3 0 1.1
done
