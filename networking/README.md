## DPDK Networking with EC2 F2

### Overview

In the blog post, we use the Custom Logic Streaming Data Engine (CL_SDE) example. To use the CL_SDE, you'll first need to build an AFI with the CL_SDE using the process described in the documentation here: [AWS F2 FPGA](https://github.com/aws/aws-fpga-preview?tab=readme-ov-file#build-accelerator-afi-using-hdk-design-flow)

### Configuration
1. Pre-install the FPGA Management tools by sourcing the sdk_setup.sh script in the AWS F2 github repository.

```bash
    $ cd aws-fpga-preview
    $ source sdk_setup.sh
```

2. Next, build the CL_SDE AFI.

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




