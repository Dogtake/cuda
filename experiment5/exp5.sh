
nvcc hash5.cu -o run5
nvcc hash6.cu -o run6




echo 24 3 0 1.2 4
for((i=0;i<5;i++));
do
./run6 24 3 0 1.2 4
done
