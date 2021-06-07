## 0. 前言

1. 安装docker

2. 安装并运行phpMyAdmin和MySql

3. Docker创建网桥，并将容器加入该网络

4. 从github克隆代码到本地并修改配置文件

5. 生成镜像并运行

6. hive配置

   项目放在github上https://github.com/Foabo/hadoop-hive

## 1. 安装docker

参考官方文档，有详细说明，mac上下载了docker desktop之后就很方便，连docker-compose都装好了

### 1.1 更换docker镜像源

https://www.daocloud.io/mirror#accelerator-doc在这个页面下找到镜像地址

复制,打开docker dashboard->点击齿轮->左边Docker Engine

![](https://upload-images.jianshu.io/upload_images/14301043-112485336390dbdd.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 2. 安装并运行mysql和phpmyadmin

具体见我博客https://www.jianshu.com/p/32335bd372dc

## 3.将mysql 和 phpmyadmin加入同一个网络

事实上我那篇博客里创建phpmyadmin的时候已经和mysql互相连接了

但是为了后续配置，给他们加入一个docker里的私有网络

```shell
docker network creat hadoopnet
docker network connect hadoopnet mysql
docker network connect hadoopnet phpmyadmin
docker network inspect hadoopnet
```

最后一句可以查看我们hadoopnet的情况

```shell
$ docker network inspect hadoopnet
[
    {
        "Name": "hadoopnet",
        "Id": "509cca32dd24091456a46b357b870b776f2cd9b52b09dd5c486f3c0a6d6d910d",
        "Created": "2020-12-12T04:57:06.8458138Z",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.18.0.0/16",
                    "Gateway": "172.18.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {
            "34596622ac1beeebaf6e8e41f910693a7f621ebbdcfdcdbbb35f1cf6de6e7ef2": {
                "Name": "mysql",
                "EndpointID": "bb20ba54f3eb990e7e4383ca3e442577fd9ea6c2e27160d1ebd52327810672bb",
                "MacAddress": "02:42:ac:12:00:03",
                "IPv4Address": "172.18.0.3/16",
                "IPv6Address": ""
            },
            "50eb6d69b526b1dc5ba230659f61d8d521125def015d52c4852d954957691bd2": {
                "Name": "phpmyadmin",
                "EndpointID": "8b3b21a22a61a615348baa6ab52c5ae6bdc52fc6ab15f3593278bd1d839e817b",
                "MacAddress": "02:42:ac:12:00:04",
                "IPv4Address": "172.18.0.4/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {}
    }
]
```



## 4. 克隆github项目

这是我fork别人的一个项目，我自己也写过dockerfile配置hadoop集群，但是人家做的更好，拿过来进行修改了一下，确保能正确运行。

```shell
git clone https://github.com/foabo/hadoop-hive
```

实际的代码结构如下，克隆下来后，添加一些必须的文件并修改config的配置文件为你自己的实际情况

![](https://upload-images.jianshu.io/upload_images/14301043-e4b6e6c1a47c33fc.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 5.构建hadoop集群

### 5.1 生成镜像

当前目录下执行

```shell
docker build -t hadoop-hive:1 .
```

可能需要大于十分钟，这时候可以看会视频缓解一下无聊。

完成之后

```shell
$ docker images
REPOSITORY              TAG                 IMAGE ID            CREATED             SIZE
hadoop-hive             1                   72a6c0ec45dd        19 minutes ago      3.01GB
rabbitmq                3.8-management      263c941f71ea        2 weeks ago         186MB
ubuntu                  18.04               2c047404e52d        2 weeks ago         63.3MB
mysql                   5.7                 1b12f2e9257b        7 weeks ago         448MB
phpmyadmin/phpmyadmin   latest              4592b4f19053        8 weeks ago         469MB
```

可以看到生成了一个大概3G的镜像

### 5.2 启动集群

先在hadoop-hive目录下创建`/data/hadoop-master/`、`/data/hadoop-slaver1/`、`/data/hadoop-slaver2/`三个文件夹

![](https://upload-images.jianshu.io/upload_images/14301043-e474e03797508266.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

在`hadoop-hive`目录下，执行

```
bash start-container1.sh 
```

执行完这条命令我们便进入了master容器内部

这时候打开外部终端执行`docker ps`可以看到生成了三个容器

```shell
$ docker ps
CONTAINER ID        IMAGE                   COMMAND                  CREATED             STATUS              PORTS                                                                      NAMES
44d7a51abd14        hadoop-hive:1           "sh -c 'service ssh …"   15 seconds ago      Up 14 seconds                                                                                  hadoop-slave2
562848ea3787        hadoop-hive:1           "sh -c 'service ssh …"   16 seconds ago      Up 15 seconds                                                                                  hadoop-slave1
df8877f49e46        hadoop-hive:1           "sh -c 'service ssh …"   17 seconds ago      Up 16 seconds       0.0.0.0:8088->8088/tcp, 0.0.0.0:9083->9083/tcp, 0.0.0.0:50070->50070/tcp   hadoop-master
50eb6d69b526        phpmyadmin/phpmyadmin   "/docker-entrypoint.…"   3 weeks ago         Up 3 hours          0.0.0.0:6061->80/tcp                                                       phpmyadmin
34596622ac1b        mysql:5.7               "docker-entrypoint.s…"   3 weeks ago         Up 3 hours          0.0.0.0:3306->3306/tcp, 33060/tcp                                          mysql
                                             mysql
```

回到master容器内部，输入ls查看当前目录

```shell
root@hadoop-master:~# ls
hdfs  run-wordcount.sh  start-hadoop.sh
```

启动hadoop集群`bash start-hadoop.sh`

```shell
root@hadoop-master:~# bash start-hadoop.sh


Starting namenodes on [hadoop-master]
hadoop-master: Warning: Permanently added 'hadoop-master,172.18.0.2' (ECDSA) to the list of known hosts.
hadoop-master: WARNING: HADOOP_NAMENODE_OPTS has been replaced by HDFS_NAMENODE_OPTS. Using value of HADOOP_NAMENODE_OPTS.
Starting datanodes
WARNING: HADOOP_SECURE_DN_LOG_DIR has been replaced by HADOOP_SECURE_LOG_DIR. Using value of HADOOP_SECURE_DN_LOG_DIR.
localhost: Warning: Permanently added 'localhost' (ECDSA) to the list of known hosts.
localhost: WARNING: HADOOP_SECURE_DN_LOG_DIR has been replaced by HADOOP_SECURE_LOG_DIR. Using value of HADOOP_SECURE_DN_LOG_DIR.
localhost: WARNING: HADOOP_DATANODE_OPTS has been replaced by HDFS_DATANODE_OPTS. Using value of HADOOP_DATANODE_OPTS.
Starting secondary namenodes [hadoop-master]
hadoop-master: Warning: Permanently added 'hadoop-master,172.18.0.2' (ECDSA) to the list of known hosts.
hadoop-master: WARNING: HADOOP_SECONDARYNAMENODE_OPTS has been replaced by HDFS_SECONDARYNAMENODE_OPTS. Using value of HADOOP_SECONDARYNAMENODE_OPTS.


Starting resourcemanager
Starting nodemanagers
```

使用`exit`命令退出docker容器，拷贝hdfs文件到宿主机目录

```shell
docker cp hadoop-master:/root/hdfs /Users/inf/github.com.foabo/hadoop-hive/data/hadoop-master
docker cp hadoop-slave1:/root/hdfs /Users/inf/github.com.foabo/hadoop-hive/data/hadoop-slave1
docker cp hadoop-slave2:/root/hdfs /Users/inf/github.com.foabo/hadoop-hive/data/hadoop-slave2
```

复制了这么一些文件过来

![](https://upload-images.jianshu.io/upload_images/14301043-5cd3ad1818b760a0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

因为下一步要挂在卷到三个容器，打开docker  dashborad，点击小齿轮->Resources->FILE SHARING，添加可以挂载的卷，然后点击`Apply & Restart`,等待docker重启,我为了防止出错，将挂载的三个卷都分别加上去了

![](https://upload-images.jianshu.io/upload_images/14301043-288d65c727816557.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



重新运行容器，并挂载hdfs目录,运行start-container2.sh

```shell
$ bash start-container2.sh
start hadoop-master container...
start hadoop-slave1 container...
start hadoop-slave2 container...
root@hadoop-master:~# ls
hdfs  run-wordcount.sh  start-hadoop.sh
```

在此进入到master容器内部

这时候我们就可以开启hadoop



```shell
./start-hadoop.sh
```

执行wordcount脚本

```shell
./run-wordcount.sh
```

如果出现

```
input file1.txt:
2020-12-12 12:30:02,783 INFO sasl.SaslDataTransferClient: SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
Hello Hadoop

input file2.txt:
2020-12-12 12:30:05,445 INFO sasl.SaslDataTransferClient: SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
Hello Docker

wordcount output:
2020-12-12 12:30:08,058 INFO sasl.SaslDataTransferClient: SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
Docker	1
Hadoop	1
Hello	2


```

大功告成！

## 6. Hive配置

首先是配置hive-site.xml，在运行Dockerfile我已经配置好了

在master容器执行元数据库初始化

```shell
/usr/local/hive/bin/schematool -dbType mysql -initSchema
```

在浏览器输入`localhost:6061`登陆phpmyadmin，账户和密码都是root

打开hive数据库，你会看到一堆的数据表

![](https://upload-images.jianshu.io/upload_images/14301043-7410384c472286db.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

进入hive测试，

```shell
cd /usr/local/hive/bin
./hive
```

此时会出来hive的shell

测试

```shell
Logging initialized using configuration in jar:file:/usr/local/hive/lib/hive-common-3.1.2.jar!/hive-log4j2.properties Async: true
Loading class `com.mysql.jdbc.Driver'. This is deprecated. The new driver class is `com.mysql.cj.jdbc.Driver'. The driver is automatically registered via the SPI and manual loading of the driver class is generally unnecessary.
Hive-on-MR is deprecated in Hive 2 and may not be available in the future versions. Consider using a different execution engine (i.e. spark, tez) or using Hive 1.X releases.
Hive Session ID = 8d6dfbee-16e4-4350-a8c1-0b0ed61a2194
hive> show databases;
OK
default
Time taken: 0.868 seconds, Fetched: 1 row(s)
hive> quit;
```



## 7. 踩坑

执行wordcount时候出现了

> ```
> Please check whether your etc/hadoop/mapred-site.xml contains the below configuration:
> <property>
>   <name>yarn.app.mapreduce.am.env</name>
>   <value>HADOOP_MAPRED_HOME=${full path of your hadoop distribution directory}</value>
> </property>
> <property>
>   <name>mapreduce.map.env</name>
>   <value>HADOOP_MAPRED_HOME=${full path of your hadoop distribution directory}</value>
> </property>
> <property>
>   <name>mapreduce.reduce.env</name>
>   <value>HADOOP_MAPRED_HOME=${full path of your hadoop distribution directory}</value>
> </property>
> ```
>
> **解决**
>
> 则在命令行输入
>
> ```
> hadoop classpath
> ```
>
> 会打印一堆hadoop环境变量复制hadoop环境变量
>
> 在mapred-site.xml文件添加
>
> ```
>     <property>
>         <name>mapreduce.application.classpath</name>
>         <value>你复制的信息</value>
>     </property>
> ```
>
> 在yarn-site.xml文件添加
>
> ```
> <property>
>         <name>yarn.application.classpath</name>
>         <value> 
>         复制的hadoop环境变量
>         </value>
>     </property>
> ```
>
> 这两个文件在`/usr/local/hadoop/etc/hadoop/`下面，我在外部修改然后用命令
>
> ```
> docker cp config/mapred-site.xml 23aeb2c92ec9:/usr/local/hadoop/etc/hadoop/mapred-site.xml
> ```
>
> 将其复制进去，重启hadoop集群

进行元数据库初始化也报错了

> ```
> Exception in thread "main" java.lang.NoSuchMethodError: com.google.common.base.Preconditions.checkArgument(ZLjava/lang/String;Ljava/lang/Object;)V
> 	at org.apache.hadoop.conf.Configuration.set(Configuration.java:1357)
> 	at org.apache.hadoop.conf.Configuration.set(Configuration.java:1338)
> 	at org.apache.hadoop.mapred.JobConf.setJar(JobConf.java:536)
> 	at org.apache.hadoop.mapred.JobConf.setJarByClass(JobConf.java:554)
> 	at org.apache.hadoop.mapred.JobConf.<init>(JobConf.java:448)
> 	at org.apache.hadoop.hive.conf.HiveConf.initialize(HiveConf.java:5141)
> 	at org.apache.hadoop.hive.conf.HiveConf.<init>(HiveConf.java:5104)
> 	at org.apache.hive.beeline.HiveSchemaTool.<init>(HiveSchemaTool.java:96)
> 	at org.apache.hive.beeline.HiveSchemaTool.main(HiveSchemaTool.java:1473)
> 	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
> 	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
> 	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
> ```
>
> **解决**
>
> ```
> rm /usr/local/hive/lib/guava-19.0.jar
> cp /usr/local/hadoop/share/hadoop/hdfs/lib/guava-27.0-jre.jar /usr/local/hive/lib/
> ```
>
> 
>
> 


