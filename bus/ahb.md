# AHB协议详解

## AHB总线

AHB总线在AMBA2中就已经定义，AHB总线一开始主要是作为系统高速总线使用，适用于高性能，低功耗的系统设计。目前因为AXI总线作为高速总线的优势更加明显，AHB会用在相对低速的系统设计中。基本排序就是APB适用于低速设计，AXI适用于高速设计，AHB则介于两者之间。

在AMBA协议中，AHB一开始主要面向系统级高带宽高性能的系统互联设计，支持多master，多slave的互联模式。但是随着系统的发展，AHB更多用于支持简单的数据传输，因此后来对AHB协议做了简化设计，<font color=Red>**定义了AHB-Lite协议，简化之后的协议主要用在单master数据访问中，不需要支持split与retry**</font>，因为中间的多外设结构都可以通过互联方便的实现。

目前AHB协议多用在低性能需求的M型处理器中，也多用在片上memory或者一些低带宽需求定位外设接口设计。

## **AHB 结构**

因为AHB协议支持多master，多slave的结构设计，因此需要有Arbiter与Decoder实现请求与响应的仲裁与编解码映射。

![img](https://pic4.zhimg.com/80/v2-c78256f0f0e5d8e621e70a2b3a1a3ff3_720w.jpg)

Master会首先向仲裁发送发文请求，仲裁决定合适让master获取总线访问的权限，master获取权限之后会将数据与控制信号发送到仲裁器，仲裁器通过地址解析判断对应的slave通路，然后将请求发送到对应的目的端。同样响应的数据会通过Decoder解析，然后返回给对应的master。

通过这种多路复用的机制实现多对多的访问。<font color=Red>但是这种结构有一个缺点就是一次能有一对maste与slave通信，无法实现多对多的同时通信，对于带宽需求比较大或者实时性要求较高的系统不太适合。</font>

AHB支持增量传输(Incrementing burst)与回环传输(Wrapping burst)。Incrementing burst可以实现地址与数据的递增，Wrapping burst可以实现地址的边界的换回。

## **AHB-Lite结构**

AHB-Lite是对AHB协议的精简，支持单个master的数据传输，在一对多的设计中可以通过Decoder对master的地址解码选择对应的slave通路。

![img](https://pic2.zhimg.com/80/v2-af150c95a311277b3f0c8889bd880b0d_720w.jpg)

master接口信号：

![img](https://pic2.zhimg.com/80/v2-7bc1848c8a07480590ffefb4370dbe15_720w.jpg)

salve接口信号：

![img](https://pic1.zhimg.com/80/v2-d1b749327d90ca4a01cd4edcd8b5eaf0_720w.jpg)

AHB信号：

![img](https://pic3.zhimg.com/80/v2-c79e59ba96c034e57f45253b22e4702e_720w.jpg)

![img](https://pic1.zhimg.com/80/v2-dca2c347d402256ea69e9a27079a4fa0_720w.jpg)

![img](https://pic4.zhimg.com/80/v2-3f68bf339ccb979943b07f867e75619f_720w.jpg)





## AHB传输

### Basic transfers

![img](https://pic3.zhimg.com/80/v2-07f68839630f5944236098d0c0283d2e_720w.jpg)

在basic传输中，可以看到传输分为地址段和数据端，第一个cycle传输地址控制信息，第二个cycle传输数据信息。在数据段中，slave会返回对应的响应hready。

**With Wait transfers**

![img](https://pic3.zhimg.com/80/v2-17238f890fef7a411e0963b50e3390aa_720w.jpg)

slave侧可以通过hready来添加延时等待，以防止内部无法及时处理或者准备所需要的数据。每个slave都会有一个hreadyout来表示内部是否已经准备完成。Internet会将所有的hreadyout合并成hready来控制相关的传输。

**Transfer type**

![img](https://pic2.zhimg.com/80/v2-abd74cd46a4c5f61f229151881d2adf5_720w.jpg)

AHB中定义了4中传输状态类型。IDLE表示无数据传输；<font color=Red>BUSY表示master处于忙碌状态，用于在burst中插入发送的等待延时</font><font>；NONSEQ表示一个single传输或者是一个burst传输中的第一拍数据，NONSEQ中地址与之前的传输没有关系，表示一笔新的传输；SEQ表示处于burst传输状态中，发送的地址与之前的地址是有关系，因为burst传输地址有相关性。

![img](https://pic2.zhimg.com/80/v2-c2aaf6af9d3d1941c52907950b938b19_720w.jpg)

T0-T1：master发送burst读的第一拍地址（0x20）信息，传输类型为NONSEQS。

T1-T2：master发出一个BUSY状态，表示本次发送的控制信息无效；slave返回上一拍对应的读数据Data(0x20)。

T2-T3： master发送第二拍burst地址（0x24）信息，此时传输状态为SEQ；此时因为上一拍master发送的为BUSY传输，因此这拍master会忽略slave的返回值。

T3-T4：master继续发送第三拍的地址（0x28）信息，slave返回第二拍数据Data(0x24)；

T4-T5：master继续发送最后一拍的地址（0x2c）信息，此时salve无法及时处理master发送的传输，因此通过拉低hready来进入等待状态。

T5-T6：因为上一个cycle中slave拉低了hready，master需要保持对应的地址段信息，slave此时可以响应master，因此把hready拉高表示此次传输有效，把对应的第三拍的数据Data(0x28)返回。

T6-T7：此时master不会发送控制信息，slave返回最后一拍的数据Data(0x2C)。

**Lock transfers**

![img](https://pic1.zhimg.com/80/v2-eb0d550dca45df9e0044215103f13b7c_720w.jpg)

<font color=Red>lock传输是为了保证master发送的一笔传输都被一次性响应完，不允许中间插入其他传输响应。这个主要应用在多个master通过ahb访问同一个slave的情况。</font>

**Transfer size**

![img](https://pic2.zhimg.com/80/v2-90e0bca6e96acc80c0f4d6026f99a811_720w.jpg)

AHB hsize有3bit位宽，表示传输数据的大小为2的幂次方Byte，最大支持1024bit。

**Burst operaption**

![img](https://pic3.zhimg.com/80/v2-75182724725a3c8f24922b91cfe6fe8e_720w.jpg)

AHB支持多种传输类型：单笔传输（SINGLE）；不定长的递增传输（INCR），回环传输（WRAP4/8/16）,定长的递增传输（INCR4/8/16）;

**Wrap4 Transfer**

![img](https://pic4.zhimg.com/80/v2-40394eee4503288be343b9c53327cab7_720w.jpg)

wrap4是16字节为边界做环回，起始地址为0x38，会环回到0x30地址重新进行地址递增。

地址环回的简单计算方法是从0开始进行计算，比如正常的传输应该是0x00,0x04,0x08,0x0c，然后根据具体的起始地址以及环回长度进行递增。如果是wrap8，则0x00~0x1c一组，0x20~0x3c一组；

**INCR4 transfer**

![img](https://pic1.zhimg.com/80/v2-bc3d4bf3236859f41852420429934c28_720w.jpg)

增量传输为地址递增的传输，每次传输地址都会相应递增。地址递增的大小根据数据的大小来判定。

<font color=red>备注：burst主要用在bus arbiter和一些特殊的slave用来提前准备数据用，比如dram这种。其他普通的slave貌似没什么用。</font>

**Protection control**

![img](https://pic1.zhimg.com/80/v2-1b59d5c86e90f04db90aca5df09d87fc_720w.jpg)

Hprot可以针对不同的传输类型进行控制。

Hprot[0],Hprot[1]用来表示数据指令传输以及相关的优先级顺序。

<font color=red>Hprot[2]用来指示是否为bufferable传输，影响到传输响应的返回节点，是否可以从中间返回还是必须要从最终目的端返回，即是否支持early response。 个人理解：就是写操作的ready信号是由真正的目的slave返回的还是可以由中间的协议arbiter，bridge代为返回。如果对于一些由严格先后顺序的读写操作，那就不能用bufferable。因为操作的顺序可能被打乱。</font>

Hprot[3]表示是否支持传输可能改，比如是否支持对读写传输的合并或者拆分，对传输的hburst或者hsize的更改。（系统可以按照更高效的方式进行传输的重新组合）

HProt[4]表示是否必须从cache中取数以及是否更新最终的memory。

Hprot[5]表示是否更新cache中的内容

Hprot[6]表示这笔传输在内存中是否与其他的master共享，来保证所有master看到的都是一致的数据。

**（HProt[4] ~ HProt[6]为了满足带cache功能的slave设备和cache一致性）**

### **Secure transfer**

AHB中有HNONSEC信号可以实现secure属性的传输控制。Secure 传输可实现不同安全属性的任务传输，针对不同secure属性的slave可以实现不同的访问权限。secure可以访问nonsecure属性的salve，但是nonsecure传输不能访问secure属性的slave。

### **Exclusive transfer**

HEXCL信号是可以实现AHB的独占访问传输。独占访问适用在多master的系统中，一个master对一段地址空间进行独占传输，如果在传输期间，这段地址没有被其他的master访问过，则独占访问成功，返回HEXOKAY，如果传输期间，这段地址有被其他master访问过，则独占访问失败，返货HOKAY。

## AHB不同版本之间的对比

![img](https://pic4.zhimg.com/80/v2-08cc07c6543f949077160a74a833b723_720w.jpg)







# AHB进阶

## AHB中的retry和split的区别是什么

在AMBA AHB传输过程中，slave使用信号HRESP[1:0]返回当前传输的状态：

**OKAY**：表示当前传输正常，当HREADY变高时传输已成功完成。

ERROR：表示发生了传输错误，且传输失败。

**RETRY 和SPLI**T：RETRY和SPLIT传输响应都表明传输无法立即完成，总线应继续尝试传输。在正常操作中，在arbiter 允许另一个master可以访问总线之前，当前master应该完成特定burst中的所有传输。然而为了避免某个master未完成的burst传输占据比较大延迟，arbiter有可能中断burst传输。在这种情况下，master必须对总线重新申请仲裁，以完成剩余的burst请求。



**需要大量处理周期的AHB slave都可以使用SPLIT和RETRY响应，以避免在数据尚未准备好之前stall住总线**，但同时也需要告诉master下一次重新发起传输请求。

RETRY和SPLIT之间的区别在于，SPLIT 响应告诉AHB仲裁器给予所有其他master仲裁高优先级直到SPLIT 传输可以完成，防止其他master被饿死。而RETRY响应只告诉AHB仲裁器将优先级给更高优先级的master，不会排除返回SPLIT 响应的master。<font color=Red>（需要有个dummy master，防止所有的master均进入split模式，导致没有任何master让bus进入IDLE）。</font>

SPLIT响应的实现比RETRY更复杂，但其优点是总线带宽实现最大效率。**对于SPLIT 响应和RETRY响应，master的行为是相同的，都需要取消下一次的数据访问，并且重试当前的访问。**

当然，对于只支持一个master的AHB-lite协议的设计中不支持SPLIT和RETRY 响应，因为这些设计只支持一个master。



HRESP信号用于表示AHB从设备的响应，在AMBA 2 AHB中，有四种取值，分别是OKAY、ERROR、RETRY、SPLIT，<font color=Red>**而在AHB LITE以及AHB5中，则仅有OKAY与ERROR两种取值**。</font>

AMBA 2 AHB的HRESP信号定义如下：

![[公式]](https://www.zhihu.com/equation?tex=%5Cbegin%7Barray%7D%5Bt%5D%7B%7Cc%7Cc%7Cc%7C%7D+%5Chline+HRESP%5B1%3A0%5D+%26+%E5%93%8D%E5%BA%94+%26+%E6%8F%8F%E8%BF%B0%5C%5C+%5Chline+00+%26+OKAY+%26+%E4%BC%A0%E8%BE%93%E6%88%90%E5%8A%9F%E5%AE%8C%E6%88%90%5C%5C+%5Chline+01+%26+ERROR+%26+%E4%BC%A0%E8%BE%93%E5%8F%91%E7%94%9F%E4%BA%86%E9%94%99%E8%AF%AF%5C%5C+%5Chline+10+%26+RETRY+%26+AHB%E4%BB%8E%E8%AE%BE%E5%A4%87%E4%B8%8D%E8%83%BD%E7%AB%8B%E5%8D%B3%E5%AE%8C%E6%88%90%E4%BC%A0%E8%BE%93%EF%BC%8CAHB%E4%B8%BB%E8%AE%BE%E5%A4%87%E5%BA%94%E5%BD%93%E9%87%8D%E8%AF%95%E4%BC%A0%E8%BE%93%5C%5C+%5Chline+11+%26+SPLIT+%26+AHB%E4%BB%8E%E8%AE%BE%E5%A4%87%E4%B8%8D%E8%83%BD%E7%AB%8B%E5%8D%B3%E5%AE%8C%E6%88%90%E4%BC%A0%E8%BE%93%EF%BC%8CAHB%E4%B8%BB%E8%AE%BE%E5%A4%87%E5%8F%AF%E4%BB%A5%E9%87%8A%E6%94%BE%E6%80%BB%E7%BA%BF%E6%89%80%E6%9C%89%E6%9D%83%EF%BC%8C%E5%BD%93AHB%E4%BB%8E%E8%AE%BE%E5%A4%87%E5%87%86%E5%A4%87%E5%A5%BD%E6%97%B6%EF%BC%8C%E4%B8%BB%E8%AE%BE%E5%A4%87%E5%8F%AF%E4%BB%A5%E5%86%8D%E6%AC%A1%E8%AF%B7%E6%B1%82%E6%80%BB%E7%BA%BF%E6%89%80%E6%9C%89%E6%9D%83%E4%BB%A5%E4%BE%BF%E5%AE%8C%E6%88%90%E4%BC%A0%E8%BE%93%5C%5C+%5Chline+%5Cend%7Barray%7D)

在传输类型为IDLE或BUSY时，或者从设备未被选中时，AHB从设备必须在HRESP上回应OKAY信号。

当AHB从设备反馈RETRY时，主设备必须通过将传输类型替换为IDLE的方式取消掉当前的传输，并立即重新启动最后一次失败的传输。

当AHB从设备反馈SPLIT时，主设备必须通过将传输类型替换为IDLE的方式取消掉当前传输并释放掉连接到仲裁器的HBUSREQ信号以便释放总线控制权，当AHB从设备准备好接收传输时，从设备会使用叫做HSPLIT的边缘信号让仲裁器恢复主设备的总线所有权，然后主设备就可以重启传输。

<font color=Red>由于操作的复杂性，SPLIT响应与HSPLIT信号很少被使用，从2001年开始，多层AHB方法被发明出来，SPLIT和RETRY机制被废除，因为新的解决方案易用性更高，并且可以避免单词传输拖慢系统的其余部分，同时可以提升系统带宽。</font>





## AHB dummy master 和 AHB dummy salve

AHB dummy salve保证地址异常，复位，所有slave都gating时，以及BUS IDLE时系统不挂死。

AHB dummy master是一个只执行IDLE传输的master。它在一个系统中是必需的，以便arbiter可以授予一个master仲裁，但是并保证不执行任何真正的传输。在两种场景下，仲裁需要dummy master：1、LOCK传输返回SPLIT 响应，2、当返回SPLIT 响应时，其他的master也正处于等待SPLIT响应的状态。



## HPROT

在AMBA 2 AHB以及AHB Lite中，HPROT信号为4bit，定义如下：

![[公式]](https://www.zhihu.com/equation?tex=%5Cbegin%7Barray%7D%5Bt%5D%7B%7Cc%7Cc%7Cc%7Cc%7C%7D+%5Chline+%E4%BF%A1%E5%8F%B7+%26+%E5%8A%9F%E8%83%BD+%26+%E5%80%BC%E4%B8%BA0%E6%97%B6+%26+%E5%80%BC%E4%B8%BA1%E6%97%B6%5C%5C+%5Chline+HPROT%5B0%5D+%26+%E6%95%B0%E6%8D%AE%2F%E6%93%8D%E4%BD%9C%E7%A0%81+%26+%E5%8F%96%E6%8C%87%E4%BB%A4+%26+%E8%AE%BF%E9%97%AE%E6%95%B0%E6%8D%AE%5C%5C+%5Chline+HPROT%5B1%5D+%26+%E7%89%B9%E6%9D%83%E7%BA%A7+%26+%E9%9D%9E%E7%89%B9%E6%9D%83%E7%9A%84%EF%BC%88%E7%94%A8%E6%88%B7%EF%BC%89+%26+%E7%89%B9%E6%9D%83%E7%9A%84%5C%5C+%5Chline+HPROT%5B2%5D+%26+%E5%8F%AFBuffer+%26+%E6%9C%AC%E6%AC%A1%E4%BC%A0%E8%BE%93%E5%BF%85%E9%A1%BB%E5%AE%8C%E6%88%90%E5%90%8E%E6%89%8D%E8%83%BD%E5%90%AF%E5%8A%A8%E4%B8%80%E4%B8%AA%E6%96%B0%E7%9A%84%E4%BC%A0%E8%BE%93+%26+%E5%86%99%E4%BC%A0%E8%BE%93%E5%8F%AF%E8%A2%ABBuffer%5C%5C+%5Chline+HPROT%5B3%5D+%26+%E5%8F%AFCache+%26+%E6%95%B0%E6%8D%AE%E4%B8%8D%E8%83%BD%E8%A2%ABCache+%26+%E6%95%B0%E6%8D%AE%E5%8F%AF%E4%BB%A5%E8%A2%ABCache%5C%5C+%5Chline+%5Cend%7Barray%7D)

当访问一般的存储器（非外设）时，HPROT[3:2]的编码可以取以下的值：

![[公式]](https://www.zhihu.com/equation?tex=%5Cbegin%7Barray%7D%5Bt%5D%7B%7Cc%7Cc%7C%7D+%5Chline+HPROT%5B3%3A2%5D+%26+%E4%BC%A0%E8%BE%93%E5%A4%A7%E5%B0%8F%5C%5C+%5Chline+00+%26+%E8%AE%BE%E5%A4%87%EF%BC%88%E4%B8%8D%E5%8F%AFBuffer%EF%BC%89%5C%5C+%5Chline+01+%26+%E8%AE%BE%E5%A4%87%EF%BC%88%E5%8F%AFBuffer%EF%BC%89%5C%5C+%5Chline+10+%26+%E5%86%99%E7%A9%BF%E6%A8%A1%E5%BC%8F%E7%9A%84%E5%8F%AFCache%E5%AD%98%E5%82%A8%E5%99%A8%5C%5C+%5Chline+11+%26+%E5%86%99%E5%9B%9E%E6%A8%A1%E5%BC%8F%E7%9A%84%E5%8F%AFCache%E5%AD%98%E5%82%A8%E5%99%A8%5C%5C+%5Chline+%5Cend%7Barray%7D)

在AMBA 5 AHB中，该属性被扩展，其定义如下所示：

![[公式]](https://www.zhihu.com/equation?tex=%5Cbegin%7Barray%7D%5Bt%5D%7B%7Cc%7Cc%7Cc%7Cc%7C%7D+%5Chline+%E4%BF%A1%E5%8F%B7+%26+%E5%8A%9F%E8%83%BD+%26+%E5%80%BC%E4%B8%BA0%E6%97%B6+%26+%E5%80%BC%E4%B8%BA1%E6%97%B6%5C%5C+%5Chline+HPROT%5B0%5D+%26+%E6%95%B0%E6%8D%AE%2F%E6%93%8D%E4%BD%9C%E7%A0%81+%26+%E5%8F%96%E6%8C%87%E4%BB%A4+%26+%E8%AE%BF%E9%97%AE%E6%95%B0%E6%8D%AE%5C%5C+%5Chline+HPROT%5B1%5D+%26+%E7%89%B9%E6%9D%83%E7%BA%A7+%26+%E9%9D%9E%E7%89%B9%E6%9D%83%E7%9A%84%EF%BC%88%E7%94%A8%E6%88%B7%EF%BC%89+%26+%E7%89%B9%E6%9D%83%E7%9A%84%5C%5C+%5Chline+HPROT%5B2%5D+%26+%E5%8F%AFBuffer+%26+%E6%9C%AC%E6%AC%A1%E4%BC%A0%E8%BE%93%E5%BF%85%E9%A1%BB%E5%AE%8C%E6%88%90%E5%90%8E%E6%89%8D%E8%83%BD%E5%90%AF%E5%8A%A8%E4%B8%80%E4%B8%AA%E6%96%B0%E7%9A%84%E4%BC%A0%E8%BE%93+%26+%E5%86%99%E4%BC%A0%E8%BE%93%E5%8F%AF%E8%A2%ABBuffer%5C%5C+%5Chline+HPROT%5B3%5D+%26+%E5%8F%AF%E4%BF%AE%E6%94%B9+%26+%E6%95%B0%E6%8D%AE%E4%B8%8D%E8%83%BD%E8%A2%ABCache+%26+%E6%95%B0%E6%8D%AE%E5%8F%AF%E4%BB%A5%E8%A2%ABCache%5C%5C+%5Chline+HPROT%5B4%5D+%26+%E6%9F%A5%E6%89%BE+%26+%E4%BC%A0%E8%BE%93%E6%B2%A1%E6%9C%89%E8%A2%ABCache+%26+%E4%BC%A0%E8%BE%93%E5%BF%85%E9%A1%BB%E6%9F%A5%E6%89%BECache%5C%5C+%5Chline+HPROT%5B5%5D+%26+%E5%88%86%E9%85%8D+%26+%E4%B8%8D%E9%9C%80%E8%A6%81%E8%BF%9B%E8%A1%8CCache%E8%A1%8C%E5%88%86%E9%85%8D+%26+%E5%9C%A8Cache+Miss%E6%97%B6%E8%BF%9B%E8%A1%8CCache%E8%A1%8C%E5%88%86%E9%85%8D%5C%5C+%5Chline+HPROT%5B6%5D+%26+%E5%8F%AF%E5%85%B1%E4%BA%AB+%26+%E6%95%B0%E6%8D%AE%E6%B2%A1%E6%9C%89%E8%A2%AB%E5%85%B1%E4%BA%AB%EF%BC%88%E4%B8%8D%E9%9C%80%E8%A6%81%E7%BB%B4%E6%8A%A4%E6%95%B0%E6%8D%AE%E4%B8%80%E8%87%B4%E6%80%A7%EF%BC%89%E6%88%96%E8%80%85%E6%98%AF%E5%90%91%E4%B8%80%E4%B8%AA%E8%AE%BE%E5%A4%87%E4%BC%A0%E8%BE%93%EF%BC%88%E4%B8%8D%E5%8F%AFCache%EF%BC%89+%26+%E6%80%BB%E7%BA%BF%E4%BA%92%E8%81%94%E5%99%A8%E9%9C%80%E8%A6%81%E7%A1%AE%E4%BF%9D%E6%95%B0%E6%8D%AE%E4%B8%80%E8%87%B4%E6%80%A7%5C%5C+%5Chline+%5Cend%7Barray%7D)

Cache类型如下表所示：

![[公式]](https://www.zhihu.com/equation?tex=%5Cbegin%7Barray%7D%5Bt%5D%7B%7Cc%7Cc%7Cc%7Cc%7Cc%7Cc%7C%7D+%5Chline+HPROT%5B6%5D+%E5%8F%AF%E5%85%B1%E4%BA%AB+%26+HPROT%5B5%5D+%E5%88%86%E9%85%8D+%26+HPROT%5B4%5D+%E6%9F%A5%E6%89%BE+%26+HPROT%5B3%5D+%E5%8F%AF%E4%BF%AE%E6%94%B9+%26+HPROT%5B2%5D+%E5%8F%AFBuffer+%26+%E5%AD%98%E5%82%A8%E5%99%A8%E7%B1%BB%E5%9E%8B%5C%5C+%5Chline+0+%26+0+%26+0+%26+0+%26+0+%26+%E4%B8%8D%E5%8F%AFBuffer%E8%AE%BE%E5%A4%87%5C%5C+%5Chline+0+%26+0+%26+0+%26+0+%26+1+%26+%E5%8F%AFBuffer%E8%AE%BE%E5%A4%87%5C%5C+%5Chline+0+%26+0+%26+0+%26+1+%26+0+%26+%E4%B8%80%E8%88%AC%E7%9A%84%E4%B8%8D%E5%8F%AFCache%E3%80%81%E4%B8%8D%E5%8F%AF%E5%85%B1%E4%BA%AB%E5%AD%98%E5%82%A8%E5%99%A8%5C%5C+%5Chline+0+%26+0%E6%88%961+%26+1+%26+1+%26+0+%26+%E5%86%99%E7%A9%BF%E3%80%81%E4%B8%8D%E5%8F%AF%E5%85%B1%E4%BA%AB%E5%AD%98%E5%82%A8%E5%99%A8%5C%5C+%5Chline+0+%26+0%E6%88%961+%26+1+%26+1+%26+1+%26+%E5%86%99%E5%9B%9E%E3%80%81%E4%B8%8D%E5%8F%AF%E5%85%B1%E4%BA%AB%E5%AD%98%E5%82%A8%E5%99%A8%5C%5C+%5Chline+1+%26+0+%26+0+%26+1+%26+0+%26+%E4%B8%80%E8%88%AC%E7%9A%84%E4%B8%8D%E5%8F%AFCache%E3%80%81%E5%8F%AF%E5%85%B1%E4%BA%AB%E5%AD%98%E5%82%A8%E5%99%A8%5C%5C+%5Chline+1+%26+0%E6%88%961+%26+1+%26+1+%26+0+%26+%E5%86%99%E7%A9%BF%E3%80%81%E5%8F%AF%E5%85%B1%E4%BA%AB%E5%AD%98%E5%82%A8%E5%99%A8%5C%5C+%5Chline+1+%26+0%E6%88%961+%26+1+%26+1+%26+1+%26+%E5%86%99%E5%9B%9E%E3%80%81%E5%8F%AF%E5%85%B1%E4%BA%AB%E5%AD%98%E5%82%A8%E5%99%A8%5C%5C+%5Chline+%5Cend%7Barray%7D)



# AHB互联方式

## 单主设备的互联方式

一个仅有一个主设备（例如，一个Cortex-M处理器）以及多个从设备的简单设计如下所示：



![img](https://pic4.zhimg.com/80/v2-f8ff110e7c00b0bb852b1c66713cc68b_720w.jpg)



信号可以被分为地址阶段信号与数据阶段信号。

地址阶段信号如下所示：

- 必须：HADDR、HTRANS、HSEL、HWRITE、HSIZE
- 可选：HPROT、HBURST、HMASTLOCK、HEXCL、HAUSER

数据阶段信号如下所示：

- 必须：HWDATA、HRDATA、HRESP、HREADY（以及HREADYOUT）
- 可选：HEXOKAY、HWUSER、HRUSER

每一次传输都包含一个地址阶段和一个数据阶段，传输可被流水化，也就是说，本次传输中的地址阶段和上次传输中的数据阶段共同进行，具体行为如下图所示：



![img](https://pic3.zhimg.com/80/v2-06969ea154e3ed973fd894709cb93da6_720w.jpg)



当前激活的AHB从设备在数据阶段会令HREADYOUT信号有效，该信号会被从设备信号多路选择器传输到主设备的HREADY端口。

如果一个AHB从设备当前未被选中，则该设备的HREADYOUT信号应为高以表示该设备已准备好。

一个最小的AHB系统包含如下三个组件：

- 地址译码器：基于HADDR输入信号，生成HSEL信号用于从设备的选择以及AHB从设备信号多路选择器。
- AHB从设备选择器：将多个从设备连接到一个单独的AHB段（Segment）。
- 默认从设备：这是一个特殊的AHB从设备，当HADDR不在任何其它AHB从设备的地址范围内时，该设备才会被选中，通常该设备被选中是由于系统发生了一些错误（例如由于C指针处理器错误，软件尝试读取无效的存储器位置），该从设备在被访问时只会返回一个错误响应，对该设备的写出数据会被忽略，并且对于读请求，该设备会永远返回0。如果地址空间被完整分配给了其它所有的从设备，则默认从设备可以不使用。

## 多主设备的互联方式

在早期的AMBA 2规范中，多个主设备使用一个主设备信号多路选择器，该选择器由总线仲裁器控制，同时，从设备返回的数据由从设备信号多路选择器选择，并最终传递给总线总设备，其互联方式如下图所示：



![img](https://pic4.zhimg.com/80/v2-49dec38f8ac29e7afa80f08593e964d3_720w.jpg)



仲裁步骤如下：

1. 主设备首先使能HBUSREQ信号。
2. 仲裁器经过仲裁后，将仲裁结果通过HGRANT信号返回给对应的主设备。
3. 获得总线的主设备在总线上开始传输，未获得总线的主设备放弃传输。

可见，这种方法会极大地限制总线的最大带宽，因此在多层AHB中使用了一种新的支持多主设备的方法，在这种方法中，一个关键性的组件被称为AHB总线矩阵，其互联方式如下所示：



![img](https://pic1.zhimg.com/80/v2-d99a7d496f7d4a20fd633e381c7c8a54_720w.jpg)



这种方式与早期AMBA 2最大的不同在于，当两个主设备访问不同的两个从设备时，可以同时进行，而不需通过仲裁决出传输顺序。

为了解决多个主设备访问同一个从设备的冲突问题，每一个主端口（连接到AHB从设备的端口）都有一个仲裁器，如果一个主设备请求的从设备正在被另一个主设备使用，传输请求就会被保存在输入阶段的Buffer中，通过这样的方式，舍弃掉了HBUSREQ与HGRANT信号。

当然，如果对总线带宽的要求不高，并因此想要简化总线设计，仍然可以沿用AMBA 2时代的互联方式，只是在其中去掉了AMBA 2时代的仲裁器，而是在AHB主设备信号多路选择器中集成与AHB5中同样的输入阶段及仲裁器，互联方式如下图所示：



![img](https://pic3.zhimg.com/80/v2-c580cbd91cda5ecdf7bd9dff19b99d6a_720w.jpg)





## Multi Layer

#### 1. 介绍：

multi-layer AHB 是基于AHB互联[架构](https://so.csdn.net/so/search?q=架构&spm=1001.2101.3001.7020)：

- 可以开发更多可用总线带宽的多主机系统

- 可以构建灵活体系架构的复杂多主机系统；消除了在硬件设计阶段，就修改有关将系统资源分配给特定主机的设计决策要求
- 可以使用标准的AHB主从模块而不需要修改
- 每个AHB layer可以非常简单，因为只有一个主机，所以不需要仲裁，只需要MUX；
- 可以使用AHB-Lite协议，即不需要请求和授予，不需要RETRY/SPLIT事务；
- 仲裁器可以高效的为每一个外设进行点仲裁，并且仅当多个主机希望同时访问同一从机时，才有必要；
- AHB 基础架构是多路选择器块，完成多主机到外设的连接
- 由于多层架构是基于AHB协议，可以复用之前设计的主机和从机，而不需要修改	



![在这里插入图片描述](https://img-blog.csdnimg.cn/20201204220435812.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3ZpdmlkMTE3,size_16,color_FFFFFF,t_70)

#### 2. 应用：

##### a. 多层互连拓朴结构

每一个主机都有自己的AHB layer，通过 interconnnect [matrix](https://so.csdn.net/so/search?q=matrix&spm=1001.2101.3001.7020) 连接

![在这里插入图片描述](https://img-blog.csdnimg.cn/20201204221712568.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3ZpdmlkMTE3,size_16,color_FFFFFF,t_70)

说明：
	i. 每个layer有一个译码器，决定那个slave需要传输；
	ii. MUX决定了传输从适当的传输到所需要的slave;



#### 3. Advance Options

##### a. 第一种：私有从机

i. 让slave私有，如slave4/5只属于Master2，这将可以使用AHB-Lite来互连，减少了互连矩阵的复杂性；
ii. 当从机只被一个主机使用时，可以使用此互连结构；

![在这里插入图片描述](https://img-blog.csdnimg.cn/20201204221755482.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3ZpdmlkMTE3,size_16,color_FFFFFF,t_70)





##### b. 第二种：一个从端口上多从机

i. 让多个从设备单个挂载在互连矩阵上，这对于组合多个低带宽的从机很有用；
ii. 可以用在一系列从设备被一个主设备访问（如DMA），而互联矩阵仅用在特殊情况下可以访问，如dubug系统时。

![在这里插入图片描述](https://img-blog.csdnimg.cn/20201204221911268.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3ZpdmlkMTE3,size_16,color_FFFFFF,t_70)



##### c. 第三种：一个layer层中多主机

i. 多主机共享一个Layer，适用于结合众多低带宽的多主机，如测试接口控制器TIC

![在这里插入图片描述](https://img-blog.csdnimg.cn/20201204221918697.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3ZpdmlkMTE3,size_16,color_FFFFFF,t_70)

##### d. 第四种：分离的AHB子系统

i. 每个layer可以成为完整的AHB子系统；
ii. 单从设备。通常片上存储器，用作两个子系统的缓存区

![在这里插入图片描述](https://img-blog.csdnimg.cn/20201204221927344.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3ZpdmlkMTE3,size_16,color_FFFFFF,t_70)



##### e. 第五种：多端口的从设备

i. 多层AHB系统中，如SRAM控制器，可以并行被不同layer高效传输；
ii. 通过设计从机有多个AHB从设备端口

![在这里插入图片描述](https://img-blog.csdnimg.cn/20201204221933586.png)



#### 4. 例子

a. CPU1有处于AHB layer 1;
b. CPU2与DMA engine 共享AHB layer2;
c. SRAM 仅连接至layer，仅可以被CPU1访问；
d. LCD控制器，仅连至layer2,可以被DMA和CPU2访问；
e. 互连矩阵，有两个从设备端口，两个都可以被两个layer层访问
一个可以是AHB2APB桥，如下方多从机，能够挂载多低带宽的外设
f. 外部SRAM接口有两个layer层的接口

![在这里插入图片描述](https://img-blog.csdnimg.cn/20201204221940202.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3ZpdmlkMTE3,size_16,color_FFFFFF,t_70)