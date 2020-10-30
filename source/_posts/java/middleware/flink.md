---
title: flink
categories: 
- java
- middleware
tags: 
- flink
---

**Apache Flink** 是一个在无界和有界数据流上进行状态计算的框架和分布式处理引擎.Flink 已经可以在所有常见的集群环境中运行,并以 in-memory 的速度和任意的规模进行计算.

可以类比 **spring batch** 或者**spark**进行学习,基本流程就是**数据获取->数据处理->数据输出**

<!-- more -->

### QuickStart

#### 搭建执行环境

这边通过 **docker-compose** 构建,当然也可以直接下载编译好的二进制版本了,[download](https://flink.apache.org/downloads.html)

```yaml
version: "3"
services:
  jobmanager:
    image: flink
    expose:
      - "6123"
    ports:
      - "8081:8081"
    command: jobmanager
    environment:
      - JOB_MANAGER_RPC_ADDRESS=jobmanager
  taskmanager:
    image: flink
    expose:
      - "6121"
      - "6122"
    depends_on:
      - jobmanager
    command: taskmanager
    links:
      - "jobmanager:jobmanager"
    environment:
      - JOB_MANAGER_RPC_ADDRESS=jobmanager
```

#### 创建应用

这里根据创建一个`WordCount`应用

```groovy
buildscript {
    repositories {
        jcenter() // this applies only to the Gradle 'Shadow' plugin
    }
    dependencies {
        classpath 'com.github.jengelman.gradle.plugins:shadow:2.0.4'
    }
}
plugins {
    id 'java'
    id 'application'
    // shadow plugin to produce fat JARs
    id 'com.github.johnrengelman.shadow' version '2.0.4'
}

configurations {
    flinkShadowJar // dependencies which go into the shadowJar

    // always exclude these (also from transitive dependencies) since they are provided by Flink
    flinkShadowJar.exclude group: 'org.apache.flink', module: 'force-shading'
    flinkShadowJar.exclude group: 'com.google.code.findbugs', module: 'jsr305'
    flinkShadowJar.exclude group: 'org.slf4j'
    flinkShadowJar.exclude group: 'org.apache.logging.log4j'
}

ext {
    javaVersion = '1.8'
    flinkVersion = '1.11.2'
    scalaBinaryVersion = '2.12'
    slf4jVersion = '1.7.15'
    log4jVersion = '2.12.1'
}

dependencies {
    compile "org.apache.flink:flink-streaming-java_${scalaBinaryVersion}:${flinkVersion}"
    compile "org.apache.flink:flink-clients_${scalaBinaryVersion}:${flinkVersion}"
    compile "org.apache.flink:flink-connector-kafka_${scalaBinaryVersion}:${fflinkVersion}"
    compile 'org.slf4j:slf4j-simple:1.7.21'
}

// make compileOnly dependencies available for tests:
sourceSets {
    main.compileClasspath += configurations.flinkShadowJar
    main.runtimeClasspath += configurations.flinkShadowJar

    test.compileClasspath += configurations.flinkShadowJar
    test.runtimeClasspath += configurations.flinkShadowJar

    javadoc.classpath += configurations.flinkShadowJar
}

run.classpath = sourceSets.main.runtimeClasspath

jar {
    manifest {
        attributes 'Built-By': System.getProperty('user.name'),
                'Build-Jdk': System.getProperty('java.version')
    }
}

shadowJar {
    configurations = [project.configurations.flinkShadowJar]
}
```

```java
public class WordCount {

    public static void main(String[] args) throws Exception {
        // 获取本地执行环境
        final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        // 设置并行数量
        env.setParallelism(1);
        // 获取数据流
        DataStream<String> stream = env.socketTextStream("localhost", 9999);
        // 转换算子处理数据流并输出结果
        stream.flatMap(new Tokenizer()).keyBy(r -> r.f0).sum(1).print();
        // 执行
        env.execute("Flink Streaming Java API Skeleton");
    }

    public static class Tokenizer implements FlatMapFunction<String, Tuple2<String, Integer>> {
        @Override
        public void flatMap(String value, Collector<Tuple2<String, Integer>> out) throws Exception {
            String[] stringList = value.split("\\s");
            for (String s : stringList) {
                // 使用out.collect方法向下游发送数据
                out.collect(new Tuple2(s, 1));
            }
        }
    }
}
```

如果是在**IDEA**本地运行的话,记得引入依赖`flink-clients`

```shell
 nc -lk 9999
```

如果，已经搭建好了 **Flink WebUI** 运行环境,上传提交编译好的jar包 **JobGraph** 即可,或者通过命令行运行

```shell
flink run -c todo.lib.flink.WordCount WordCount.jar
```

### DataStream API

#### DataSource

##### 内置数据源

###### Batch

从数组或者集合，一般本地调试使用

```java
String[] elementInput = new String[]{"hello Flink", "Second Line"};
DataStream<String> stream = env.fromElements(elementInput);
```

###### File

可以使用 `readTextFile` 方法直接读取文本文件, 这种方式可以用来监控一下 **log** 日志文件, 也可以使用 `readFile` 方法通过指定 `InputFormat` 来读取特定数据类型的文件, `InputFormat`可以是内置类,如 `CsvInputFormat` 或者用户自定义 `InputFormat` 接口类.

在 `readFile()` 方法中有一项参数为 `WatchType`, 共有两种模式 (`PROCESS_CONTINUOUSLY `/ `PROCESS_ONCE`). 在 `PROCESS_CONTINUOUSLY` 模式下, 检测到文件变动就会将文件全部内容加载在 **flink**, 在 `PROCESS_ONCE` 模式下, 只会将文件变动的那部分加载到 **flink**.

```java
// 添加文件源
// 直接读取文本文件
DataStream<String> stream = env.readTextFile(logPath);
// 读取csv
CsvInputFormat csvInput = new RowCsvInputFormat(
    new Path(csvPath),                                        // 文件路径
    new TypeInformation[]{Types.STRING, Types.STRING, Types.STRING},// 字段类型
    "\n",                                             // 行分隔符
    ",");                                            // 字段分隔符
csvInput.setSkipFirstLineAsHeader(true);
// 指定 CsvInputFormat, 监控csv文件(两种模式), 时间间隔是10ms
DataStream<Row> stream = env.readFile(csvInput, csvPath, FileProcessingMode.PROCESS_CONTINUOUSLY, 10);
```

###### Socket

```java
// 添加Socket作为数据输入源
// 4个参数 -> (hostname:Ip地址, port:端口, delimiter:分隔符, maxRetry:最大重试次数)
DataStream<String> stream = env.socketTextStream("localhost", 9999, "\n", 4);
```

##### 外部数据源

外部数据源是重头戏, 一般来说项目中均是使用外部数据源作为数据的源头.

###### 第三方数据源

flink 通过实现 `SourceFunction` 定义了非常丰富的第三方数据连接器.对于第三方数据源, flink的支持分为三种,有**只读型(**Twitter Streaming API / Netty ), **只写型**( Cassandra / Elasticsearch / hadoop FileSystem), 支持**读写**(Kafka / Amazon Kinesis / RabbitMQ)

- Apache Kafka (Source / Sink)
- Apache Cassandra (Sink)
- Amazon Kinesis Streams (Source / Sink)
- Elasticsearch (Sink)
- Hadoop FileSystem (Sink)
- RabbitMQ (Source / Sink)
- Apache NiFI (Source / Sink)
- Twitter Streaming API (Source)
- Apache Bahir 中的连接器:
- Apache ActiveMQ (Source / Sink)
- Apache Flume (Sink)
- Redis (Sink)
- Akka (Sink)
- Netty (Source)

**以Kafka 为例 做演示**

```java
Properties properties = new Properties();
properties.setProperty("bootstrap.servers", "localhost:9092");
properties.setProperty("group.id", "test");
DataStream<String> dataStream = env
    .addSource(new FlinkKafkaConsumer<>("topic", new SimpleStringSchema(), properties));
dataStream.print();
```

```shell
docker exec -it kafka_container_id bash
cd /opt/kafka/bin
// 生产数据
./kafka-console-producer.sh --broker-list 172.17.0.6:9092 --topic flink-test
// 消费数据
./kafka-console-consumer.sh --zookeeper 172.17.0.6:2181 --topic first_topic --from-beginning

```



###### 自定义数据源

用户也可以自己定义连接器, 通过实现 `SourceFunction` 定义单个线程的接入的数据连接器, 也可以通过实现`ParallelSourceFunction` 接口或者继承 `RichParallelSourceFunction` 类定义并发数据源接入器.



### 相关链接

[apache flink](https://ci.apache.org/projects/flink/flink-docs-release-1.12/)

[github flink](https://github.com/apache/flink)

[尚硅谷](https://confucianzuoyuan.github.io/flink-tutorial/)