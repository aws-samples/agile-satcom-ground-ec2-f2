## DPDK Networking with EC2 F2

### Overview

In the [associated blog post](https://aws.amazon.com/blogs/publicsector/agile-satellite-communication-ground-systems-with-amazon-ec2-f2-fpga-solutions/), we use the Custom Logic Streaming Data Engine (CL_SDE) example to generate traffic. In the future, a packet generator-responder topology with two EC2 instances will be supported, which will include the Elastic Network Adapter (ENA) offload functionality to provide the full end-to-end functionality that DPDK offers. It, too, will leverage CL_SDE, so this is a foundational step you'll need to take to work with DPDK on F2.

### Prerequisites
Review the example here: [AWS F2 CL_SDE example](https://github.com/aws/aws-fpga/blob/f2/hdk/cl/examples/cl_sde/README.md)

To use the CL_SDE, you'll first need to build an AFI with the CL_SDE using the process described in the documentation here: [AWS F2 FPGA](https://github.com/aws/aws-fpga/blob/f2/hdk/README.md)

After building the AFI, you'll identify the associated AFI and AGFI IDs and load this into an available FPGA slot so that you can use them for throughput testing.

### Prerequisites
1. Set the AWS_FPGA_REPO_DIR:

```bash
AWS_FPGA_REPO_DIR=/home/ubuntu/aws-fpga
```
2. Set the HDK_DIR:

```bash
INSTALL_DIR=/home/ubuntu/installations
```

3. Clone the repository:

```bash
git clone https://github.com/aws/aws-fpga.git $AWS_FPGA_REPO_DIR
```

4. Change to the $AWS_FPGA_REPO_DIR and source the hdk setup script:

```bash
cd $AWS_FPGA_REPO_DIR
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

```bash
source sdk_setup.sh
```
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

6. Next, load the CL_SDE AFI.

```bash
sudo fpga-load-local-image -S 0 -I agfi-0925b211f5a81b071
```
View the FPGA slot status to see the local image loaded successfully:
```bash
sudo fpga-describe-local-image -S 0
```
The output should look like this:

```bash
AFI          0       agfi-0925b211f5a81b071  loaded            0        ok               0       0x10212415
AFIDEVICE    0       0x1d0f      0xf002      0000:34:00.0

```

```bash
cd $HDK_DIR/cl/examples/
```


### Configuration
1. Software installation and build phase:
```bash
cd $SDK_DIR/apps/virtual-ethernet/scripts
sudo ./virtual_ethernet_install.py $INSTALL_DIR
```

2.  System setup and device bind phase, e.g. on instance boot (not necessary if completed above):
```bash
sudo fpga-load-local-image -S 0 -I agfi-0925b211f5a81b071
cd $SDK_DIR/apps/virtual-ethernet/scripts
sudo ./virtual_ethernet_setup.py $INSTALL_DIR/dpdk 0
```

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
You can exit this screen with a ctrl-c. After that, you'll get a final screen similar to this:

```bash
Waiting for lcores to finish...

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
