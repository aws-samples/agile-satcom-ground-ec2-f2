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
    $ AWS_FPGA_REPO_DIR=/home/ubuntu/aws-fpga
```
2. Set the HDK_DIR:

```bash
    $ INSTALL_DIR=/home/ubuntu/installations
```

3. Clone the repo:

```bash
    $ git clone https://github.com/aws/aws-fpga.git $AWS_FPGA_REPO_DIR
```

4. Change to $AWS_FPGA_REPO_DIR and source the hdk setup script:

```bash
    $ cd $AWS_FPGA_REPO_DIR
    $ source hdk_setup.sh
```

5. After the setup is complete, set the CL_DIR variable:

```bash
    $ cd $HDK_DIR/cl/examples/
```


### Configuration
1. Pre-install the FPGA Management tools by sourcing the sdk_setup.sh script in the AWS F2 github repository.

```bash
    $ cd aws-fpga
    $ source sdk_setup.sh
```

2. Next, build the CL_SDE AFI. Be sure to use the small_shell option, which is the only shell supported as of 12/12/24.

```bash
    $ cd hdk/cl/examples/cl_sde

    $export CL_DIR=$(pwd)
    cd build/scripts

    $ ./aws_build_dcp_from_cl.py --mode small_shell --cl cl_sde
```

3. Continue with the build process starting with step 5 here (deep link): [AWS FPGA Github repo](https://github.com/aws/aws-fpga/blob/f2/hdk/README.md#step-5-explore-build-artifacts)

4. Continue through step 8 to produce the output shown in the blog post.

Your throughput results should be on the order of 9-11 gigabytes per second with this single-instance test.

When used in an an end-to-end topology with a separate packet generator instance or an SDR, expect 12.5 Gbps throughput less some overhead for buffering per FPGA. You should be able to process several hundred megahertz of RF bandwidth per FPGA.
