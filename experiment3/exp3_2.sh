nvcc hash3.cu -o run
echo 24 2 0 2
for((i=0;i<5;i++));
do
	./run 24 2 0 2;
done

echo 24 2 0 1.9
for((i=0;i<5;i++));
do
	./run 24 2 0 1.9;
done

echo 24 2 0 1.8
for((i=0;i<5;i++));
do
	./run 24 2 0 1.8;
done

echo 24 2 0 1.7
for((i=0;i<5;i++));
do
	./run 24 2 0 1.7;
done

echo 24 2 0 1.6
for((i=0;i<5;i++));
do
	./run 24 2 0 1.6;
done

echo 24 2 0 1.5
for((i=0;i<5;i++));
do
	./run 24 2 0 1.5;
done

echo 24 2 0 1.4
for((i=0;i<5;i++));
do
	./run 24 2 0 1.4;
done

echo 24 2 0 1.3
for((i=0;i<5;i++));
do
	./run 24 2 0 1.3;
done

echo 24 2 0 1.2
for((i=0;i<5;i++));
do
	./run 24 2 0 1.2;
done
