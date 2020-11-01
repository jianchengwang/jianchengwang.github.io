---
title: flink
categories: 
- java
- middleware
tags: 
- flink
---

**Apache Flink** 是一个在无界和有界数据流上进行状态计算的框架和分布式处理引擎.Flink 已经可以在所有常见的集群环境中运行,并以 in-memory 的速度和任意的规模进行计算.

可以类比 **spring batch** 或者**spark**进行学习,基本流程就是**source->computer/transformation->sink**

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

###### Elements

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

flink 通过实现 `SourceFunction` 定义了非常丰富的第三方数据连接器.对于第三方数据源, flink的支持分为三种,有**只读型**(Twitter Streaming API / Netty ), **只写型**( Cassandra / Elasticsearch / hadoop FileSystem), 支持**读写**(Kafka / Amazon Kinesis / RabbitMQ)

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

我这边是远程服务器上**docker-compose**启动**kafka**,主要注意下面的**EN_IP**表示外网的IP地址

```yaml
# 一个 kafka节点 就是一个 broker。一个集群由多个 broker 组成。一个 broker可以容纳多个 topic
KAFKA_BROKER_ID: 0
# 配置zookeeper管理kafka的路径
KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181 
# 把kafka的地址端口注册给zookeeper，若远程访问要改成外网IP,千万注意是外网IP
KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://${EN_IP}:9092 
# 配置kafka的监听端口
KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092  
```

```java
Properties properties = new Properties();
properties.setProperty("bootstrap.servers", "EN_IP:9092");
properties.setProperty("group.id", "test");
DataStream<String> dataStream = env
    .addSource(new FlinkKafkaConsumer<>("topic", new SimpleStringSchema(), properties));
dataStream.print();
```

```shell
docker exec -it kafka_container_id bash
cd /opt/kafka/bin
// 生产数据
./kafka-console-producer.sh --broker-list EN_IP:9092 --topic flink-test
// 消费数据
./kafka-console-consumer.sh --bootstrap-server EN_IP:9092 --topic flink-test --from-beginning
```

###### 自定义数据源

用户也可以自己定义连接器, 通过实现 `SourceFunction` 定义单个线程的接入的数据连接器, 也可以通过实现`ParallelSourceFunction` 接口或者继承 `RichParallelSourceFunction` 类定义并发数据源接入器.

```java
 class SourceFromMySQL extends RichSourceFunction<User> {
     PreparedStatement ps;
     private Connection connection;

     @Override
     public void run(SourceContext<User> ctx) throws Exception {
         ResultSet resultSet = ps.executeQuery();
         while (resultSet.next()) {
             User user = new User(
                 resultSet.getInt("id"),
                 resultSet.getString("name").trim());
             ctx.collect(user);
         }
     }
     ........
```



#### Transformation

##### 基本转换算子

基本转换算子会针对流中的每一个单独的事件做处理,也就是说每一个输入数据会产生一个输出数据.单值转换,数据的分割,数据的过滤,都是基本转换操作的典型例子.

###### filter

```java
DataStream<SensorReading> filteredReadings = readings.filter(r -> r.temperature >= 25);
```

###### map

```java
DataStream<String> sensorIds = filteredReadings.map(r -> r.id);
```

###### flatMap

```java
DataStream<String> splitIds = sensorIds
    .flatMap((FlatMapFunction<String, String>)
             (id, out) -> { for (String s: id.split("_")) { out.collect(s);}})
    // provide result type because Java cannot infer return type of lambda function
    // 提供结果的类型，因为Java无法推断匿名函数的返回值类型
    .returns(Types.STRING);
```

###### richFunction

在函数处理数据之前,需要做一些初始化的工作;或者需要在处理数据时可以获得函数执行上下文的一些信息;以及在处理完数据时做一些清理工作

```java
public static class MyFlatMap extends RichFlatMapFunction<Integer, Tuple2<Integer, Integer>> {
  private int subTaskIndex = 0;

  @Override
  public void open(Configuration configuration) {
    int subTaskIndex = getRuntimeContext.getIndexOfThisSubtask;
    // 做一些初始化工作
    // 例如建立一个和HDFS的连接
  }

  @Override
  public void flatMap(Integer in, Collector<Tuple2<Integer, Integer>> out) {
    if (in % 2 == subTaskIndex) {
      out.collect((subTaskIndex, in));
    }
  }

  @Override
  public void close() {
    // 清理工作，断开和HDFS的连接。
  }
}
```

##### 键控流转换算子

很多流处理程序的一个基本要求就是要能对数据进行分组,分组后的数据共享某一个相同的属性.**DataStream API**提供了一个叫做`KeyedStream`的抽象,此抽象会从逻辑上对DataStream进行分区,分区后的数据拥有同样的`Key`值,分区后的流互不相关.

###### keyBy

```java
KeyedStream<SensorReading, String> keyed = readings.keyBy(r -> r.id);
```

###### fold

通过将最后一个文件夹流与当前记录组合来推出 KeyedStream.它会发回数据流.

```java
KeyedStream.fold("1", new FoldFunction<Integer, String>() {
    @Override
    public String fold(String accumulator, Integer value) throws Exception {
        return accumulator + "=" + value;
    }
})
```

###### aggregate

滚动聚合算子由`KeyedStream`调用,并生成一个聚合以后的DataStream.

滚动聚合算子只能用在滚动窗口,不能用在滑动窗口.

滚动聚合操作会对每一个key都保存一个状态。因为状态从来不会被清空，所以我们在使用滚动聚合算子时只能使用在含有有限个key的流上面。

常见的滚动聚合算子: sum,min,max,minBy,maxBy

```java
DataStream<Tuple3<Integer, Integer, Integer>> resultStream = inputStream
    .keyBy(0) // key on first field of the tuple
    .sum(1);   // sum the second field of the tuple in place
```

###### window,windowAll

允许按时间或其他条件对现有 KeyedStream 进行分组.以下是以 10 秒的时间窗口聚合:

```java
inputStream.keyBy(0).window(Time.seconds(10));
inputStream.keyBy(0).windowAll(Time.seconds(10));
```

###### window join

我们可以通过一些 key 将同一个 window 的两个数据流 join 起来.

以下示例是在 5 秒的窗口中连接两个流,其中第一个流的第一个属性的连接条件等于另一个流的第二个属性

```java
inputStream.join(inputStream1)
           .where(0).equalTo(1)
           .window(Time.seconds(5))     
           .apply (new JoinFunction () {...});
```

###### split

此功能根据条件将流拆分为两个或多个流.当您获得混合流并且您可能希望单独处理每个数据流时,可以使用此方法.

```java
SplitStream<Integer> split = inputStream.split(new OutputSelector<Integer>() {
    @Override
    public Iterable<String> select(Integer value) {
        List<String> output = new ArrayList<String>(); 
        if (value % 2 == 0) {
            output.add("even");
        }
        else {
            output.add("odd");
        }
        return output;
    }
});
```

###### select

此功能允许您从拆分流中选择特定流

```java
SplitStream<Integer> split;
DataStream<Integer> even = split.select("even"); 
DataStream<Integer> odd = split.select("odd"); 
DataStream<Integer> all = split.select("even","odd");
```

###### project

Project 函数允许您从事件流中选择属性子集,并仅将所选元素发送到下一个处理流.

```java
DataStream<Tuple4<Integer, Double, String, String>> in = // [...] 
DataStream<Tuple2<String, String>> out = in.project(3,2);
```

###### reduce

reduce函数可以通过实现接口ReduceFunction来创建一个类.ReduceFunction接口定义了`reduce()`方法,此方法接收两个输入事件,输入一个相同类型的事件.

reduce作为滚动聚合的泛化实现,同样也要针对每一个key保存状态.因为状态从来不会清空,所以我们需要将reduce算子应用在一个有限key的流上.

```java
DataStream<SensorReading> maxTempPerSensor = keyed
    .reduce((r1, r2) -> {
        if (r1.temperature > r2.temperature) {
            return r1;
        } else {
            return r2;
        }
    });
```

##### 多流转换算子

许多应用需要摄入多个流并将流合并处理,还可能需要将一条流分割成多条流然后针对每一条流应用不同的业务逻辑.

###### union

合流的方式为FIFO方式,合并流类型要一致.

```java
DataStream<SensorReading> parisStream = ...
DataStream<SensorReading> tokyoStream = ...
DataStream<SensorReading> rioStream = ...
DataStream<SensorReading> allCities = parisStream
  .union(tokyoStream, rioStream)
```

###### connect,comap,coflatmap

两个流的数据类型可以不同,会对两个流中的数据应用不同的处理方法.

```java
DataStream<Tuple2<Integer, Long>> one = ...
DataStream<Tuple2<Integer, String>> two = ...
// keyBy two connected streams
ConnectedStreams<Tuple2<Int, Long>, Tuple2<Integer, String>> keyedConnect1 = one
  .connect(two)
  .keyBy(0, 0); // key both input streams on first attribute
// alternative: connect two keyed streams
ConnectedStreams<Tuple2<Integer, Long>, Tuple2<Integer, String>> keyedConnect2 = one
  .keyBy(0)
  .connect(two.keyBy(0));
```

##### 分布式转换算子

定义了事件如何分配到不同的任务中去

当我们使用DataStream API来编写程序时,系统将自动的选择数据分区策略,然后根据操作符的语义和设置的并行度将数据路由到正确的地方去.有些时候,我们需要在应用程序的层面控制分区策略,或者自定义分区策略

###### random

随机数据交换由`DataStream.shuffle()`方法实现。shuffle方法将数据随机的分配到下游算子的并行任务中去

###### round-robin

`rebalance()`方法使用Round-Robin负载均衡算法将输入流平均分配到随后的并行运行的任务中去

###### rescale

`rescale()`方法使用的也是round-robin算法,但只会将数据发送到接下来的并行运行的任务中的一部分任务中.本质上,当发送者任务数量和接收者任务数量不一样时,rescale分区策略提供了一种轻量级的负载均衡策略.如果接收者任务的数量是发送者任务的数量的倍数时,rescale操作将会效率更高.

`rebalance()`和`rescale()`的根本区别在于任务之间连接的机制不同.`rebalance()`将会针对所有发送者任务和所有接收者任务之间建立通信通道,而`rescale()`仅仅针对每一个任务和下游算子的一部分子并行任务之间建立通信通道

###### broadcast

`broadcast()`方法将输入流的所有数据复制并发送到下游算子的所有并行任务中去.

###### global

`global()`方法将所有的输入流数据都发送到下游算子的第一个并行任务中去.这个操作需要很谨慎,因为将所有数据发送到同一个task,将会对应用程序造成很大的压力.

###### custom

当Flink提供的分区策略都不适用时,我们可以使用`partitionCustom()`方法来自定义分区策略.这个方法接收一个`Partitioner`对象,这个对象需要实现分区逻辑以及定义针对流的哪一个字段或者key来进行分区.

#### Sink

Flink没有类似于spark中foreach方法,让用户进行迭代的操作.所有对外的输出操作都要利用Sink完成.最后通过类似如下方式完成整个任务最终输出操作.

```java
stream.addSink(new MySink(xxxx));
```

官方提供了一部分的框架的sink.除此以外,需要用户自定义实现sink.

##### 第三方sink

###### kafka

```xml
<dependency>
  <groupId>org.apache.flink</groupId>
  <artifactId>flink-connector-kafka_2.11</artifactId>
  <version>${flink.version}</version>
</dependency>
```

```java
DataStream<String> union = high
  .union(low)
  .map(r -> r.temperature.toString);

union.addSink(
  new FlinkKafkaProducer011<String>(
    "localhost:9092",
    "test",
    new SimpleStringSchema()
  )
);
```

###### redis

```xml
<dependency>
  <groupId>org.apache.bahir</groupId>
  <artifactId>flink-connector-redis_2.11</artifactId>
  <version>1.0</version>
</dependency>
```

```java
public class RedisSink_ {
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(1);

        DataStream<User> stream = env.addSource(new UserSource());


        FlinkJedisPoolConfig conf = new FlinkJedisPoolConfig.Builder().setHost("localhost").build();

        stream.addSink(new RedisSink<SensorReading>(conf, new MyRedisSink()));

        env.execute();
    }

    public static class MyRedisSink implements RedisMapper<User> {
        @Override
        public String getKeyFromData(User user) {
            return user.getId().toString();
        }

        @Override
        public String getValueFromData(User User) {
            return user.getName();
        }

        @Override
        public RedisCommandDescription getCommandDescription() {
            return new RedisCommandDescription(RedisCommand.HSET, "flink-test");
        }
    }
}
```

```shell
docker exec -it redis_container_id redis-cli
auth 123456
keys keys flink-test
hvals flink-test
```

###### elasticsearch

```xml
<dependency>
  <groupId>org.apache.flink</groupId>
  <artifactId>flink-connector-elasticsearch6_2.11</artifactId>
  <version>${flink.version}</version>
</dependency>

<!-- 可选依赖 -->  
<dependency>
    <groupId>org.elasticsearch.client</groupId>
    <artifactId>elasticsearch-rest-high-level-client</artifactId>
    <version>7.9.1</version>

</dependency>
<dependency>
    <groupId>org.elasticsearch</groupId>
    <artifactId>elasticsearch</artifactId>
    <version>7.9.1</version>
</dependency>
```

```java
public class EsSink_ {
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(1);

        DataStreamSource<User> stream = env.addSource(new UserSource());

        ArrayList<HttpHost> httpHosts = new ArrayList<>();
        httpHosts.add(new HttpHost("localhost", 9200, "http"));
        ElasticsearchSink.Builder<User> sensorReadingBuilder = new ElasticsearchSink.Builder<>(
                httpHosts,
                (ElasticsearchSinkFunction<User>) (user, runtimeContext, requestIndexer) -> {
                    HashMap<String, String> map = new HashMap<>();
                    map.put("data", user.toString());
                    IndexRequest indexRequest = Requests
                            .indexRequest()
                            .index("flink-test") // 索引是flink-test，相当于数据库
                            .type("user") // es6需要加这一句
                            .source(map);

                    requestIndexer.add(indexRequest);
                }
        );
        sensorReadingBuilder.setBulkFlushMaxActions(1);
        stream.addSink(sensorReadingBuilder.build());

        env.execute();
    }
}
```

##### 自定义sink

继承 RichSinkFunction 抽象类,重写 invoke 方法

```java
public static class MyJDBCSink extends RichSinkFunction<User> {
    private Connection conn;
    private PreparedStatement insertStmt;
    private PreparedStatement updateStmt;

    @Override
    public void invoke(User value, Context context) throws Exception {
        updateStmt.setString(1, value.getName());
        updateStmt.setInt(2, value.getId());
        updateStmt.execute();

        if (updateStmt.getUpdateCount() == 0) {
            insertStmt.setInt(1, value.getId());
            insertStmt.setString(2, value.getName());
            insertStmt.execute();
    	}
    }
    ....
```



### 相关链接

[apache flink](https://ci.apache.org/projects/flink/flink-docs-release-1.12/)

[github flink](https://github.com/apache/flink)

[尚硅谷](https://confucianzuoyuan.github.io/flink-tutorial/)