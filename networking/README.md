## DPDK Networking with EC2 F2

### Overview

In the associated blog post, we use the Custom Logic Streaming Data Engine (CL_SDE) example to generate traffic. In the future, a packet generator-responder topology with two EC2 instances will be supported, which will include the Elastic Network Adapter (ENA) offload functionality to provide the full end-to-end functionality that DPDK offers. It, too, will leverage CL_SDE, so this is a foundational step you'll need to take to work with DPDK on F2.

### Prerequisites
Build on SDK 2.1.1

Review the example here: [AWS F2 CL_SDE example](https://github.com/aws/aws-fpga-preview/blob/main/hdk/cl/examples/cl_sde/README.md)

To use the CL_SDE, you'll first need to build an AFI with the CL_SDE using the process described in the documentation here: [AWS F2 FPGA](https://github.com/aws/aws-fpga-preview?tab=readme-ov-file#build-accelerator-afi-using-hdk-design-flow)

After building the AFI, you'll identify the image IDs and load them into an available FPGA slot so that you can use them for throughput testing.

**Note:** Disregard the Pre-generated AFI ID and AGFI ID in the Metadata table at the bottom of the page here: [AWS F2 CL_SDE example](https://github.com/aws/aws-fpga-preview/blob/main/hdk/cl/examples/cl_sde/README.md) You must build and load the CL_SDE in your account as described in the steps below under Configuration.

### Configuration
1. Pre-install the FPGA Management tools by sourcing the sdk_setup.sh script in the AWS F2 github repository.

```bash
    $ cd aws-fpga-preview
    $ source sdk_setup.sh
```

2. Next, build the CL_SDE AFI. Be sure to use the small_shell option, which is the only shell supported currently.

```bash
    $ cd hdk/cl/examples/cl_sde

    $export CL_DIR=$(pwd)
    cd build/scripts

    $ ./aws_build_dcp_from_cl.py --mode small_shell --cl cl_sde
```

3. After the build process completes, identify your AFI and AGFI.

```bash
    $ aws ec2 describe-fpga-images --owners self
```

The output should look similar to this:




