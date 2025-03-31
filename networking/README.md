## DPDK Networking with EC2 F2

### Overview

In the [associated blog post](https://aws.amazon.com/blogs/publicsector/agile-satellite-communication-ground-systems-with-amazon-ec2-f2-fpga-solutions/), we use the Custom Logic Streaming Data Engine (CL_SDE) example to generate traffic. A [packet generator-responder topology](https://github.com/aws/aws-fpga/blob/f2/sdk/apps/virtual-ethernet/doc/Virtual_Ethernet_Application_Guide.md#packetgen-dual-instance-loopback) with two EC2 instances is also supported, which includes the Elastic Network Adapter (ENA) offload functionality to provide the full end-to-end functionality that [DPDK](https://www.dpdk.org/) offers. It, too, leverages CL_SDE, so this is a foundational step you'll need to take to work with DPDK on F2.


### Background
You can build and run the [virtual ethernet](https://github.com/aws/aws-fpga/tree/f2/sdk/apps/virtual-ethernet) DPDK-based F2 examples in multiple ways: -

* Build and run it on an F2 instance directly - use the AWS F2 Developer AMI which you can find by searching for it in the public AMI catalog in any AWS Region where F2 instances are supported. In the AMI catalog, the AMI is called:
```bash
F2 FPGA Developer AMI - 1.16.2 - Xilinx Tools 2024.1
```
The version number may differ but you'll be able to find it by the F2 FPGA Developer AMI prefix.

* Using your own AMI on F2 - per the [HDK Readme](https://github.com/aws/aws-fpga/tree/f2/hdk#step-7-load-accelerator-afi-on-f2-instance) AWS recommends using AMIs with at least Ubuntu 20.04 and kernel version 5.15. This `cl_sde` example was tested with an Ubuntu 22.04 LTS Community AMI `ubuntu-jammy-22.04-amd64-server-20240927` which you can find in the [AMI Catalog](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#AMICatalog:)
> [!NOTE]
> The DPDK kernel used in this example was built with gcc-12. If the Ubuntu distribution you are using defaults to a lower gcc version the `virtual_ethernet_install.py` installation will fail. You can update your gcc version to version 12 as shown [here](https://phoenixnap.com/kb/install-gcc-ubuntu)

Review the example here: [AWS F2 CL_SDE example](https://github.com/aws/aws-fpga/blob/f2/hdk/cl/examples/cl_sde/README.md). 

Execute steps 1-6 in the [HDK Readme](https://github.com/aws/aws-fpga/blob/f2/hdk/README.md) to build the `cl_sde` Design Checkpoint (DCP) and Amazon FPGA Image (AFI). You can do this on any AWS instance type (or your own compute resources if you already have a [supported AMD toolkit vesion](https://github.com/aws/aws-fpga/blob/f2/User_Guide_AWS_EC2_FPGA_Development_Kit.md#hardware-development-kit-hdk)). Given the large size of the FPGA used for F2, AMD tools work best with at least 4 vCPU’s and 32GiB Memory. We recommend [Compute Optimized and Memory Optimized instance types](https://aws.amazon.com/ec2/instance-types/) to successfully run the synthesis of acceleration code. Developers may start coding and run simulations on low-cost `General Purpose` [instances types](https://aws.amazon.com/ec2/instance-types/).

### Prerequisites
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

6. Next, load the CL_SDE AGFI. The AWS-provided AGFI ID is located at the bottom of this page: [AWS F2 Github repository] (https://github.com/aws/aws-fpga/blob/f2/hdk/cl/examples/cl_sde/README.md)

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


### Configuration
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
