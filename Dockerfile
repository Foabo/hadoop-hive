FROM ubuntu:18.04

ADD sources.list /etc/apt/sources.list
ADD apache-hive-3.1.2-bin.tar.gz /
ADD mysql-connector-java-8.0.18.jar /
ADD hadoop-3.2.1.tar.gz /
COPY config/* /tmp/

WORKDIR /root

# install openssh-server, openjdk and wget,install hadoop 3.2.1
RUN apt-get update && \
    #apt-get install -y --reinstall software-properties-common && \
    #add-apt-repository -y ppa:openjdk-r/ppa && \
    apt-get update && \
    apt-get install -y openssh-server openssh-client vim less wget openjdk-8-jdk && \
    apt-get clean all && \
    mv /hadoop-3.2.1 /usr/local/hadoop && \
    mv /apache-hive-3.1.2-bin /usr/local/hive && \
    cp /mysql-connector-java-8.0.18.jar /usr/local/hive/lib/ 
    #apt-get -y --purge remove software-properties-common

# set environment variable
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV HADOOP_HOME=/usr/local/hadoop
ENV HIVE_HOME=/usr/local/hive
ENV PATH=$PATH:/usr/local/hadoop/bin:/usr/local/hadoop/sbin 

# ssh without key and hadoop config
RUN ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    mkdir -p ~/hdfs/namenode && \ 
    mkdir -p ~/hdfs/datanode && \
    mkdir $HADOOP_HOME/logs && \
    mv /tmp/ssh_config ~/.ssh/config && \
    mv /tmp/hadoop-env.sh /usr/local/hadoop/etc/hadoop/hadoop-env.sh && \
    mv /tmp/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml && \ 
    mv /tmp/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml && \
    mv /tmp/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml && \
    mv /tmp/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml && \
    mv /tmp/slaves $HADOOP_HOME/etc/hadoop/slaves && \
    mv /tmp/start-hadoop.sh ~/start-hadoop.sh && \
    mv /tmp/run-wordcount.sh ~/run-wordcount.sh && \
    mv /tmp/hive-site.xml /usr/local/hive/conf/ && \
    chmod +x ~/start-hadoop.sh && \
    chmod +x ~/run-wordcount.sh && \
    chmod +x $HADOOP_HOME/sbin/start-dfs.sh && \
    chmod +x $HADOOP_HOME/sbin/start-yarn.sh && \
    /usr/local/hadoop/bin/hdfs namenode -format && \
    rm /usr/local/hive/lib/guava-19.0.jar &&\
    cp /usr/local/hadoop/share/hadoop/hdfs/lib/guava-27.0-jre.jar /usr/local/hive/lib/
    # format namenode
#RUN /usr/local/hadoop/bin/hdfs namenode -format

CMD [ "sh", "-c", "service ssh start; bash"]

