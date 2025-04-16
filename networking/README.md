## DPDK Networking with EC2 F2

### Overview

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
### VPC Networking

1. For the single-instance F2 example, a VPC with a single subnet in a [Region where F2 instances are supported](https://docs.aws.amazon.com/ec2/latest/instancetypes/ec2-instance-regions.html) is required. You must configure access to your EC2 instance so that you can connect to it on the CLI for to complete these steps.

2. For the two-instance example, a VPC with two subnets is required. Each instance requires a network interface in each subnet.

> [!NOTE]
> Build your VPC in a Region where [F2 instances are available](https://docs.aws.amazon.com/ec2/latest/instancetypes/ec2-instance-regions.html). Both subnets must be in the same Availability Zone.

### Placement Group

1. In the two-instance example, the packet generator instance and the F2 instance must be placed in a Cluster Placement Group.


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

### Instance build overview

1. Follow the Prerequisites and Placement Group guidance above.

2. Build your Amazon EC2 F2 Virtual Ethernet Instance with two Elastic Network Adapters in two subnets in the same Availability Zone. If you build this instance from your own Ubuntu LTS AMI that does not include gcc-12, install gcc-12 as outlined in the Background section above.

3. Build your Packet Generator Instance with two Elastic Network Adapters in the same two subnets as the F2 instance uses. An m6i.8xlarge provides good performance for the Packet Generator Instance.

4. Ensure that both instances are in the Cluster Placement Group that you created earlier. They will work if they are not in the Cluster Placement Group, but network performance will be suboptimal.

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

8. Bind the second interface to the DPDK driver.

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

9. Edit the packet generator configuration file to match the source and destination IP addresses of the DPDK network adapters, and the destination MAC address of the DPDK adapter. Also set the protocol to TCP and the packet size to 9000 bytes.

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

```bash

