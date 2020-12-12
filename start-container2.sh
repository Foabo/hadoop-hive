#!/bin/bash

# the default node number is 3
N=${1:-3}


# start hadoop master container
sudo docker rm -f hadoop-master &> /dev/null
echo "start hadoop-master container..."
sudo docker run -itd \
                --net=hadoopnet \
                -p 50070:50070 \
                -p 8088:8088 \
                -p 9083:9083 \
                --name hadoop-master \
                --hostname hadoop-master \
                -v /Users/inf/github.com.gitbug404/hadoop-hive/data/hadoop-master/hdfs:/root/hdfs \
                hadoop-hive:1 &> /dev/null


# start hadoop slave container
i=1
while [ $i -lt $N ]
do
	sudo docker rm -f hadoop-slave$i &> /dev/null
	echo "start hadoop-slave$i container..."
	sudo docker run -itd \
	                --net=hadoopnet \
	                --name hadoop-slave$i \
	                --hostname hadoop-slave$i \
                    -v /Users/inf/github.com.gitbug404/hadoop-hive/data/hadoop-slave$i/hdfs:/root/hdfs \
	                hadoop-hive:1 &> /dev/null
	i=$(( $i + 1 ))
done 

# get into hadoop master container
sudo docker exec -it hadoop-master bash

