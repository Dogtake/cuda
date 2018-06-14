nvcc hash4.cu -o run

echo 24 4 0 1.2 1
for((i=0;i<10;i++));
do
./run 24 4 0 1.2 1
done


echo 24 4 0 1.2 2
for((i=0;i<5;i++));
do
./run 24 4 0 1.2 2
done

echo 24 4 0 1.2 3
for((i=0;i<5;i++));
do
./run 24 4 0 1.2 3
done

echo 24 4 0 1.2 4
for((i=0;i<5;i++));
do
./run 24 4 0 1.2 4
done