## DPDK Networking with Amazon EC2 F2 Instances

### Overview

Agile satcom imposes substantial networking requirements. Demodulating a satcom RF waveform and transforming it into digitized intermediate frequency (DigIF) streams produces approximately a 1:20 expansion in data rate. That is, 100 MHz of RF bandwidth equates to 2 Gbps of DigIF data, assuming an 8-bit sample rate. It is important to select a cloud compute instance type with sufficient network bandwidth. An Amazon EC2 F2.48xlarge instance with eight FPGAs and 100 Gbps of network throughput could accommodate approximately 4 GHz of RF spectrum, split across eight or more channels.

In the [associated blog post](https://aws.amazon.com/blogs/publicsector/agile-satellite-communication-ground-systems-with-amazon-ec2-f2-fpga-solutions/), we use the Custom Logic Streaming Data Engine (CL_SDE) example to generate traffic. A [packet generator-responder topology](https://github.com/aws/aws-fpga/blob/f2/sdk/apps/virtual-ethernet/doc/Virtual_Ethernet_Application_Guide.md#packetgen-dual-instance-loopback) with two EC2 instances is also supported, which includes the Elastic Network Adapter (ENA) offload functionality to provide the full end-to-end functionality that [DPDK](https://www.dpdk.org/) offers. It, too, leverages CL_SDE, so this is a foundational step you'll need to take to work with DPDK on F2.


### Background
You can build and run the [virtual ethernet](https://github.com/aws/aws-fpga/tree/f2/sdk/apps/virtual-ethernet) DPDK-based F2 examples in multiple ways:

* Build and run it on an F2 instance directly - use the AWS F2 Developer AMI which you can find by searching for it in the public AMI catalog in any AWS Region where F2 instances are supported. In the AMI catalog, the AMI is called:
```bash
F2 FPGA Developer AMI - 1.16.2 - Xilinx Tools 2024.1
```
The version number may differ from the one listed above, but you'll be able to find it by the F2 FPGA Developer AMI prefix.

* Using your own AMI on F2 - per the [HDK Readme](https://github.com/aws/aws-fpga/tree/f2/hdk#step-7-load-accelerator-afi-on-f2-instance) AWS recommends using AMIs with at least Ubuntu 20.04 and kernel version 5.15. This `cl_sde` example was tested with an Ubuntu 22.04 LTS Community AMI `ubuntu-jammy-22.04-amd64-server-20240927` which you can find in the [AMI Catalog](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#AMICatalog:)

> [!NOTE]
> The DPDK kernel used in this example was built with gcc-12. If the Ubuntu distribution you are using defaults to a lower gcc version the `virtual_ethernet_install.py` installation will fail. You can update your gcc version to version 12 as shown [here](https://phoenixnap.com/kb/install-gcc-ubuntu)

### Before you begin
1. Review the example here: [AWS F2 CL_SDE example](https://github.com/aws/aws-fpga/blob/f2/hdk/cl/examples/cl_sde/README.md). 

2. Choose whether you will be completing the single-instance F2 example or [two-instance example](https://github.com/aws/aws-fpga/blob/f2/sdk/apps/virtual-ethernet/doc/Virtual_Ethernet_Application_Guide.md#packetgen-dual-instance-loopback) with a general-purpose compute Packet Generator Instance and F2 Virtual Ethernet Instance.

3. Build your Amazon EC2 instance or instances according to your choice in the previous step. You can use the same F2 instance for both examples.

> [!NOTE]
> The two-instance configuration requires two network interfaces for both the packet generator and the F2 instance. When building an EC2 instance from an Ubuntu image, the network configuration is simplified if you create the instance with two Elastic Network Adapters rather than creating the instances with one network adapter and adding the second one later. See Prerequisites below for more details.


Execute steps 1-6 in the [HDK Readme](https://github.com/aws/aws-fpga/blob/f2/hdk/README.md) to build the `cl_sde` Design Checkpoint (DCP) and Amazon FPGA Image (AFI). You can do this on any AWS instance type (or your own compute resources if you already have a [supported AMD toolkit vesion](https://github.com/aws/aws-fpga/blob/f2/User_Guide_AWS_EC2_FPGA_Development_Kit.md#hardware-development-kit-hdk)). Given the large size of the FPGA used for F2, AMD tools work best with at least 4 vCPU’s and 32GiB Memory. We recommend [Compute Optimized and Memory Optimized instance types](https://aws.amazon.com/ec2/instance-types/) to successfully run the synthesis of acceleration code. Developers may start coding and run simulations on low-cost `General Purpose` [instances types](https://aws.amazon.com/ec2/instance-types/).


### Prerequisites

#### VPC Networking

1. For the single-instance F2 example, a VPC with a single subnet in a [Region where F2 instances are supported](https://docs.aws.amazon.com/ec2/latest/instancetypes/ec2-instance-regions.html) is required. You must configure access to your EC2 instance so that you can connect to it on the CLI for to complete these steps.

2. For the two-instance example, a VPC with two subnets is required. Each instance requires a network interface in each subnet.

> [!NOTE]
> Build your VPC in a Region where [F2 instances are available](https://docs.aws.amazon.com/ec2/latest/instancetypes/ec2-instance-regions.html). Both subnets must be in the same Availability Zone.

#### Placement Group

1. In the two-instance example, the packet generator instance and the F2 instance must be placed in a [Cluster Placement Group](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-placement-group.html).


### F2 Single-Instance Virtual Ethernet Instance initial steps

On your F2 instance (e.g. f2.6xlarge): -

1. Set the AWS_FPGA_REPO_DIR:

```bash
AWS_FPGA_REPO_DIR=/home/ubuntu/aws-fpga
```
2. Set the INSTALL_DIR:

```bash
INSTALL_DIR=/home/ubuntu/installations
```
This is the location the DPDK will be installed into.

3. Clone the repository:

```bash
git clone https://github.com/aws/aws-fpga.git $AWS_FPGA_REPO_DIR
```

4. Change to the $AWS_FPGA_REPO_DIR and, if using the AWS F2 Developer AMI, source the hdk setup script:

```bash
cd $AWS_FPGA_REPO_DIR
```

> [!NOTE]
> Skip this step if using your own Ubuntu LTS AMI.

```bash
source hdk_setup.sh
```

Monitor for success messages. You should see the following:

```bash
INFO: Setting up environment variables
INFO: Using vivado v2024.1 (64-bit)
INFO: VIVADO_TOOL_VERSION is 2024.1 
INFO: HDK shell is up-to-date
WARNING: Don't forget to set the CL_DIR variable for the directory of your Custom Logic.
INFO: AWS HDK setup PASSED.
```

5. Source the sdk setup script:
> [!NOTE]
> This step is required for all AMI types, since the SDK includes the [FPGA Management Tools](https://github.com/aws/aws-fpga/tree/f2/sdk/userspace/fpga_mgmt_tools)

```bash
source sdk_setup.sh
```
When prompted to restart services, tab to 'Ok' and hit Enter.

Monitor for success messages. You should see the following:

```bash
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
AWS FPGA: Copying Amazon FPGA Image (AFI) Management Tools to /usr/local/bin
AWS FPGA: Installing shared library to /usr/local/lib
	libfpga_mgmt.so.1 (libc6,x86-64) => /usr/local/lib/libfpga_mgmt.so.1
AWS FPGA: Done with Amazon FPGA Image (AFI) Management Tools install.
Done with SDK install.
INFO: sdk_setup.sh PASSED
```

6. Next, load the CL_SDE AGFI. The AWS-provided AGFI ID for the CL_SDE application is located at the bottom of this page: [AWS F2 Github repository](https://github.com/aws/aws-fpga/blob/f2/hdk/cl/examples/cl_sde/README.md)

```bash
sudo fpga-load-local-image -S 0 -I <your-agfi-id>
```
View the FPGA slot status to see the local image loaded successfully:
```bash
sudo fpga-describe-local-image -S 0
```
The output should look like this:

```bash
AFI          0       your-agfi-id  loaded            0        ok               0       0x10212415
AFIDEVICE    0       0x1d0f      0xf002      0000:34:00.0

```

```bash
cd $HDK_DIR/cl/examples/
```


### F2 Single-Instance Virtual Ethernet build and test phases
1. Software installation and build phase:
```bash
cd $SDK_DIR/apps/virtual-ethernet/scripts
./virtual_ethernet_install.py $INSTALL_DIR
```

2.  System setup and device bind phase:
```bash
sudo ./virtual_ethernet_setup.py $INSTALL_DIR/dpdk 0
```
Change the 0 to a 1 if using slot 1 on a multi-instance F2.

3. Testpmd application setup and start phase:
```bash
cd $INSTALL_DIR/dpdk
sudo ./build/app/dpdk-testpmd -l 0-1  -- --port-topology=loop --auto-start --tx-first --stats-period=3
```

4. Monitor your results. You should see a screen with port statistics that looks like this:

```bash
Port statistics ====================================
  ######################## NIC statistics for port 0  ########################
  RX-packets: 58142968   RX-missed: 0          RX-bytes:  476307193856
  RX-errors: 0
  RX-nombuf:  0         
  TX-packets: 58143000   TX-errors: 0          TX-bytes:  476307456000

  Throughput (since last show)
  Rx-pps:      1082088          Rx-bps:  70915734696
  Tx-pps:      1082088          Tx-bps:  70915756536
  ############################################################################
```
In this example, the RX-bps field shows about 71 Gbps, which equates to about 8.86 GB/s.

You can exit this screen with a ctrl-c. After that, you'll get a final screen similar to this:

```bash
  ---------------------- Forward statistics for port 0  ----------------------
  RX-packets: 203551792      RX-dropped: 0             RX-total: 203551792
  TX-packets: 203551824      TX-dropped: 0             TX-total: 203551824
  ----------------------------------------------------------------------------

  +++++++++++++++ Accumulated forward statistics for all ports+++++++++++++++
  RX-packets: 203551792      RX-dropped: 0             RX-total: 203551792
  TX-packets: 203551824      TX-dropped: 0             TX-total: 203551824
  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Done.

Stopping port 0...
Stopping ports...
Done

Shutting down port 0...
Closing ports...
Done

Bye...

```

## Two-Instance Test

In practice, an FPGA instance would consume data produced elsewhere, whether that is a satcom digitizer or other data streaming producer, and process that data. So we provide in this example an environment that includes a data producer, which is a packet generator running on a general-purpose compute instance, and run the virtual ethernet application on the F2 instance to return that traffic to the packet generator to allow throughput measurement. The two-instance topology and metrics provided offer a useful amount of detail for determining real-world performance capability under a variety of operating conditions, such as packet size and protocol.

### Instance build overview

1. Follow the Prerequisites and Placement Group guidance above.

2. Build your Amazon EC2 F2 Virtual Ethernet Instance with two Elastic Network Adapters in two subnets in the same Availability Zone. If you build this instance from your own Ubuntu LTS AMI that does not include gcc-12, install gcc-12 as outlined in the Background section above.

3. Build your Packet Generator Instance with two Elastic Network Adapters in the same two subnets as the F2 instance uses. An m6i.8xlarge provides good performance for the Packet Generator Instance because this instance type offers 12.5 Gbps of network throughput.

4. Ensure that both instances are in the Cluster Placement Group that you created earlier. They will work if they are not in the Cluster Placement Group, but network performance will be suboptimal. Testing with instances inside and then outside a Cluster Placement group will provide an indication of the potential performance difference you may see with sources of streaming data that cannot be placed inside a Cluster Placement Group, such as data sources that are not in an Amazon EC2 instance.

### F2 Virtual Ethernet Instance

On your F2 instance (e.g. f2.6xlarge): -

1. Set the AWS_FPGA_REPO_DIR:

```bash
AWS_FPGA_REPO_DIR=/home/ubuntu/aws-fpga
```
2. Set the INSTALL_DIR:

```bash
INSTALL_DIR=/home/ubuntu/installations
```
This is the location the DPDK will be installed into.

3. Clone the repository:

```bash
git clone https://github.com/aws/aws-fpga.git $AWS_FPGA_REPO_DIR
```

4. Change to the $AWS_FPGA_REPO_DIR and, if using the AWS F2 Developer AMI, source the hdk setup script:

```bash
cd $AWS_FPGA_REPO_DIR
```

> [!NOTE]
> Skip this step if using your own Ubuntu LTS AMI.
```bash
source hdk_setup.sh
```

Monitor for success messages. You should see the following:

```bash
INFO: Setting up environment variables
INFO: Using vivado v2024.1 (64-bit)
INFO: VIVADO_TOOL_VERSION is 2024.1 
INFO: HDK shell is up-to-date
WARNING: Don't forget to set the CL_DIR variable for the directory of your Custom Logic.
INFO: AWS HDK setup PASSED.
```

5. Source the sdk setup script:
> [!NOTE]
> This step is required for all AMI types, since the SDK includes the [FPGA Management Tools](https://github.com/aws/aws-fpga/tree/f2/sdk/userspace/fpga_mgmt_tools)

```bash
source sdk_setup.sh
```
When prompted to restart services, tab to 'Ok' and hit Enter.

Monitor for success messages. You should see the following:

```bash
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
AWS FPGA: Copying Amazon FPGA Image (AFI) Management Tools to /usr/local/bin
AWS FPGA: Installing shared library to /usr/local/lib
	libfpga_mgmt.so.1 (libc6,x86-64) => /usr/local/lib/libfpga_mgmt.so.1
AWS FPGA: Done with Amazon FPGA Image (AFI) Management Tools install.
Done with SDK install.
INFO: sdk_setup.sh PASSED
```

6. Next, load the CL_SDE AGFI. The AWS-provided AGFI ID for the CL_SDE application is located at the bottom of this page: [AWS F2 Github repository](https://github.com/aws/aws-fpga/blob/f2/hdk/cl/examples/cl_sde/README.md)

```bash
sudo fpga-load-local-image -S 0 -I <your-agfi-id>
```
View the FPGA slot status to see the local image loaded successfully:
```bash
sudo fpga-describe-local-image -S 0
```
The output should look like this:

```bash
AFI          0       your-agfi-id  loaded            0        ok               0       0x10212415
AFIDEVICE    0       0x1d0f      0xf002      0000:34:00.0

```

7. Check interface bindings. Initially both network interfaces will be bound to the kernel driver.

First, use ifconfig to verify that both interfaces are present and check to see how they are enumerated.
```bash
ifconfig
```
If prompted, follow the steps to install net-tools.

```bash
sudo apt install net-tools
```
Make note of interface numbers (i.e., ens5, enp40s0)

Check the interface bindings:

```bash
python3 $INSTALL_DIR/dpdk/usertools/dpdk-devbind.py --status
```
Output should look like this:

```bash
Network devices using kernel driver
===================================
0000:27:00.0 'Elastic Network Adapter (ENA) ec20' if=ens5 drv=ena unused= *Active*
0000:28:00.0 'Elastic Network Adapter (ENA) ec20' if=enp40s0 drv=ena unused= *Active*
[rest omitted]
```

8. Bind the second interface to the IGB_UIO driver. This driver allows the FPGA to use DPDK networking and bypass kernel space.  

```bash
sudo $SDK_DIR/apps/virtual-ethernet/scripts/virtual_ethernet_setup.py $INSTALL_DIR/dpdk 0 --eni_dbdf 0000:28:00.0 --eni_ethdev enp40s0
```

Check the new bindings.

```bash
python3 $INSTALL_DIR/dpdk/usertools/dpdk-devbind.py --status
```

The output should look like this:

```bash
Network devices using DPDK-compatible driver
============================================
0000:28:00.0 'Elastic Network Adapter (ENA) ec20' drv=igb_uio unused=ena
0000:34:00.0 'Device f002' drv=igb_uio unused=

Network devices using kernel driver
===================================
0000:27:00.0 'Elastic Network Adapter (ENA) ec20' if=ens5 drv=ena unused=igb_uio *Active*
[rest omitted]
```

#### Start the throughput Virtual Ethernet test on the F2 instance

1. Start the test

```bash
cd $INSTALL_DIR/dpdk
sudo ./build/app/dpdk-testpmd -l 0-1 -- --port-topology=chained --auto-start --stats-period=3 --forward-mode=spp-eni-addr-swap
```

Keep the window open and proceed to the Packet Generator Instance configuration.

### Packet Generator Instance

On your Packet Generator instance (e.g. m6i.8xlarge): -

1. Set the AWS_FPGA_REPO_DIR:

```bash
AWS_FPGA_REPO_DIR=/home/ubuntu/aws-fpga
```
2. Set the INSTALL_DIR:

```bash
INSTALL_DIR=/home/ubuntu/installations
```
This is the location the DPDK will be installed into.

3. Clone the repository:

```bash
git clone https://github.com/aws/aws-fpga.git $AWS_FPGA_REPO_DIR
```

4. Change to the $AWS_FPGA_REPO_DIR and, if using the AWS F2 Developer AMI, source the hdk setup script:
> [!NOTE]
> Skip this step if using your own Ubuntu LTS AMI.

```bash
cd $AWS_FPGA_REPO_DIR
```

```bash
source hdk_setup.sh
```

Monitor for success messages. You should see the following:

```bash
INFO: Setting up environment variables
INFO: Using vivado v2024.1 (64-bit)
INFO: VIVADO_TOOL_VERSION is 2024.1 
INFO: HDK shell is up-to-date
WARNING: Don't forget to set the CL_DIR variable for the directory of your Custom Logic.
INFO: AWS HDK setup PASSED.
```

5. Source the sdk setup script:
> [!NOTE]
> This step is required for all AMI types, since the SDK includes the [FPGA Management Tools](https://github.com/aws/aws-fpga/tree/f2/sdk/userspace/fpga_mgmt_tools)

```bash
source sdk_setup.sh
```
When prompted to restart services, tab to 'Ok' and hit Enter.

Monitor for success messages. You should see the following:

```bash
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
AWS FPGA: Copying Amazon FPGA Image (AFI) Management Tools to /usr/local/bin
AWS FPGA: Installing shared library to /usr/local/lib
	libfpga_mgmt.so.1 (libc6,x86-64) => /usr/local/lib/libfpga_mgmt.so.1
AWS FPGA: Done with Amazon FPGA Image (AFI) Management Tools install.
Done with SDK install.
INFO: sdk_setup.sh PASSED
```

6. Install the packet generator application.

```bash
cd $SDK_DIR/apps/virtual-ethernet/scripts
./virtual_ethernet_pktgen_install.py $INSTALL_DIR
```

Results should be similar to this:
```bash
_____________________________
pktgen-dpdk installation and build complete!
pktgen-dpdk may be setup via the following step:
  sudo /home/ubuntu/aws-fpga/sdk/apps/virtual-ethernet/scripts/virtual_ethernet_pktgen_setup.py /home/ubuntu/installations --eni_dbdf <ENI_DBDF> --eni_ethdev <ENI_ETHDEV>
_____________________________
```

7. Check interface bindings. Initially both network interfaces will be bound to the kernel driver.

First, use ifconfig to verify that both interfaces are present and check to see how they are enumerated.
```bash
ifconfig
```
If prompted, follow the steps to install net-tools.

```bash
sudo apt install net-tools
```
Make note of interface numbers (i.e., ens5, ens6)

Check the interface bindings.

```bash
python3 $INSTALL_DIR/dpdk/usertools/dpdk-devbind.py --status
```
Output should be similar to step 7 in the F2 instance configuration, but with different interface numbers (ens5, ens6).

8. Configure the DPDK device binding for interface ens6.

```bash
sudo python3 $SDK_DIR/apps/virtual-ethernet/scripts/virtual_ethernet_pktgen_setup.py $INSTALL_DIR --eni_dbdf 0000:00:06.0 --eni_ethdev ens6
```
Results should look like this:

```bash
______________________________
DPDK setup complete!
pktgen-dpdk may be run via the following steps:
cd /home/ubuntu/installations/pktgen-dpdk sudo ./app/x86_64-native-linuxapp-gcc/pktgen -l 0,1 -n 4 --proc-type auto --log-level 7 --socket-mem 2048 --file-prefix pg -- -T -P -m [1].0 -f /home/ubuntu/aws-fpga/sdk/apps/virtual-ethernet/scripts/pktgen-ena.pkt
______________________________
```

```bash
python3 $INSTALL_DIR/dpdk/usertools/dpdk-devbind.py --status
```

Results should look like this:
```bash
Network devices using DPDK-compatible driver
============================================
0000:00:06.0 'Elastic Network Adapter (ENA) ec20' drv=igb_uio unused=ena

Network devices using kernel driver
===================================
0000:00:05.0 'Elastic Network Adapter (ENA) ec20' if=ens5 drv=ena unused=igb_uio *Active*
```

9. Edit the packet generator configuration file to match the source and destination IP addresses of the DPDK network adapters, and the destination MAC address of the DPDK adapter. Also set the protocol to TCP and the packet size to 9000 bytes for best performance. The larger the packet size, the higher the throughput. If your application will use UDP rather than TCP, change the protocol to UDP and compare results. You can also compare throughput results with other packet sizes to see the impact of smaller packet sizes. Change one variable at a time to make the most meaningful comparisons.

```bash
more $SDK_DIR/apps/virtual-ethernet/scripts/pktgen-ena.pkt
```

#### Start the packet generator

1. Start the test.

```bash
cd $INSTALL_DIR/pktgen-dpdk
sudo LD_LIBRARY_PATH=/usr/local/lib/x86_64-linux-gnu ./build/app/pktgen -l 0,1 -n 16 --proc-type auto --log-level 7 --socket-mem 4096 --file-prefix pg -- -T -j -P -m [1].0 -f $SDK_DIR/apps/virtual-ethernet/scripts/pktgen-ena.pkt
```

2. Monitor the Packet Generator Instance and the Virtual Ethernet Instance SSH windows to see the performance in real time. Monitor the Mbits/s Rx/Tx in green near the top of the screen to see the throughput in megabits per second. With a packet size of 9000 bytes, you should see the Jumbos count incrementing.

3. While the packet generator is running, you can use the set 0 commands to change parameters and see the performance differences in the application window above. Example:

```bash
set 0 size 512
```
changes the packet size to 512 bytes

The single- and two-instance configurations described here provide useful data on throughput capabilities of Amazon EC2 F2 FPGA instances for evaluating real-world workload capabilities. In the two-instance case, the packet generator running on an Amazon EC2 general-purpose compute instance can be used as a baseline for evaluating performance of an FPGA instance for digital satcom or other workloads where the streaming data source will be something other than an EC2 instance, which is useful for comparing and optimizing the performance of the production workload compared to that baseline.

#### Results

Here's an example of Packet Generator performance with 64-byte packets.

##### Packet generator instance

```bash
/ Ports 0-0 of 1   <Main Page>  Copyright(c) <2010-2023>, Intel Corporation
  Port:Flags        : 0:P------      Single
Link State          :        <UP-100000-FD>     ---Total Rate---
Pkts/s Rx           :                 93435                93435
       Tx           :                473468               473468
MBits/s Rx/Tx       :                59/303               59/303
Pkts/s Rx Max       :                 95996                95996
       Tx Max       :                495546               495546
Broadcast           :                     0
Multicast           :                   128
Sizes 64            :             498314240
      65-127        :                     0
      128-255       :                     0
      256-511       :                     0
      512-1023      :                     0
      1024-1518     :                     0
Runts/Jumbos        :                 128/0
ARP/ICMP Pkts       :                 128/0
Errors Rx/Tx        :                   0/0
Total Rx Pkts       :               7692946
      Tx Pkts       :              39310729
      Rx/Tx MBs     :            4923/25158
TCP Flags           :                .A....
TCP Seq/Ack         :           74616/74640
Pattern Type        :               abcd...
Tx Count/% Rate     :         Forever /100%
Pkt Size/Rx:Tx Burst:           64 / 64: 64
TTL/Port Src/Dest   :        64/54321/51234
Pkt Type:VLAN ID    :       IPv4 / TCP:0001
802.1p CoS/DSCP/IPP :             0/  0/  0
VxLAN Flg/Grp/vid   :      0000/    0/    0
IP  Destination     :         172.31.104.15
    Source          :     172.31.105.187/20
MAC Destination     :     12:a7:14:16:7c:b9
    Source          :     12:1c:73:0d:1f:41
NUMA/Vend:ID/PCI    :-1/1d0f:ec20/0000:00:06.0
-- Pktgen 24.03.1 (DPDK 24.03.0)  Powered by DPDK  (pid:67801) ----------------

Executing '/home/ubuntu/pktgen-ena.pkt'
sset 0 dst mac 12:a7:14:16:7c:b9
Pktgen:/> set 0 src ip 172.31.105.187/20
Pktgen:/> set 0 dst ip 172.31.104.15
Pktgen:/> set 0 sport 54321
Pktgen:/> set 0 dport 51234
Pktgen:/> set 0 type ipv4
Pktgen:/> set 0 proto tcp
Pktgen:/> set 0 size 64
Pktgen:/> start 0
Pktgen:/>
** Version: DPDK 24.03.0, Command Line Interface
Pktgen:/>
```

##### F2 Instance

```bash
Port statistics ====================================
  ######################## NIC statistics for port 0  ########################
  RX-packets: 5025535    RX-missed: 0          RX-bytes:  301532844
  RX-errors: 0
  RX-nombuf:  0
  TX-packets: 5025566    TX-errors: 0          TX-bytes:  301537571

  Throughput (since last show)
  Rx-pps:        93434          Rx-bps:     44849736
  Tx-pps:        93433          Tx-bps:     44848296
  ############################################################################

  ######################## NIC statistics for port 1  ########################
  RX-packets: 5025548    RX-missed: 0          RX-bytes:  301532844
  RX-errors: 0
  RX-nombuf:  0
  TX-packets: 5025548    TX-errors: 0          TX-bytes:  301532844

  Throughput (since last show)
  Rx-pps:        93436          Rx-bps:     44849320
  Tx-pps:        93435          Tx-bps:     44849160
  ############################################################################
```

### CPU Performance Impact of DPDK

Running DPDK is effective at offloading network traffic processing from the CPU of an F2 instance. To demonstrate the effect, you can run a test with the packet generator topology described above. Start by running top with no applications running (before starting the pktgen application), and you should see performance similar to this: 

```bash
top - 20:24:34 up 3 min,  1 user,  load average: 0.37, 0.36, 0.17
Tasks: 358 total,   1 running, 357 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.2 us,  0.0 sy,  0.0 ni, 95.8 id,  4.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem : 255704.3 total, 254276.3 free,    530.2 used,    897.8 buff/cache
MiB Swap:  10240.0 total,  10240.0 free,      0.0 used. 253215.8 avail Mem
```
The %Cpu line shows 0.2% user space (designated by 'us') CPU load with no applications running:

```bash
%Cpu(s):  0.2 us,  0.0 sy,  0.0 ni, 95.8 id,  4.0 wa,  0.0 hi,  0.0 si,  0.0 st
```

Then, start the testpmd application on the F2 instance, but don't start the pktgen application on the packet generator instance yet. Output should be similar to this:

```bash
top - 21:00:42 up 39 min,  3 users,  load average: 0.22, 0.27, 0.66
Tasks: 333 total,   1 running, 332 sleeping,   0 stopped,   0 zombie
%Cpu(s):  4.2 us,  0.0 sy,  0.0 ni, 95.8 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem : 255704.3 total, 218176.4 free,  33680.7 used,   3847.3 buff/cache
MiB Swap:  10240.0 total,  10240.0 free,      0.0 used. 219980.5 avail Mem
```
In this case, user space CPU load increases to 4.2%:

```bash
%Cpu(s):  4.2 us,  0.0 sy,  0.0 ni, 95.8 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
```

Finally, start the pktgen instance, sending 4000 byte packets in this example:

```bash
top - 21:02:23 up 41 min,  3 users,  load average: 0.86, 0.48, 0.70
Tasks: 331 total,   1 running, 330 sleeping,   0 stopped,   0 zombie
%Cpu(s):  4.2 us,  0.0 sy,  0.0 ni, 95.8 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem : 255704.3 total, 218176.9 free,  33680.1 used,   3847.3 buff/cache
MiB Swap:  10240.0 total,  10240.0 free,      0.0 used. 219981.0 avail Mem
```

In this case, there is no change in the user space CPU load with the test running and more than 93,000 packets per second being handled bidirectionally by DPDK networking. (See the port statistics below.)

```bash
%Cpu(s):  4.2 us,  0.0 sy,  0.0 ni, 95.8 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
```

Finally, the associated port statistics on the F2 instance during this test:

```bash
Port statistics ====================================
  ######################## NIC statistics for port 0  ########################
  RX-packets: 5025535    RX-missed: 0          RX-bytes:  301532844
  RX-errors: 0
  RX-nombuf:  0
  TX-packets: 5025566    TX-errors: 0          TX-bytes:  301537571

  Throughput (since last show)
  Rx-pps:        93434          Rx-bps:     44849736
  Tx-pps:        93433          Tx-bps:     44848296
  ############################################################################

  ######################## NIC statistics for port 1  ########################
  RX-packets: 5025548    RX-missed: 0          RX-bytes:  301532844
  RX-errors: 0
  RX-nombuf:  0
  TX-packets: 5025548    TX-errors: 0          TX-bytes:  301532844

  Throughput (since last show)
  Rx-pps:        93436          Rx-bps:     44849320
  Tx-pps:        93435          Tx-bps:     44849160
  ############################################################################
```

The results demonstrate that DPDK minimizes the CPU impact on the F2 instance.
