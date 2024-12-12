## Agile satellite communication ground systems with Amazon EC2 F2 FPGA solutions

### Description
This repository contains sample code to demonstrate agile Satellite Communications use-cases. The associated blog 
is [here](https://aws.amazon.com/blogs/publicsector/agile-satellite-communication-ground-systems-with-amazon-ec2-f2-fpga-solutions/).

Satellite operators are seeking to replace inflexible hardware at their ground teleports with
digitizers, software channelizer and combiner, and one or more software defined radios.

The new F2 FPGA instances are well-suited to the category of virtualized satcom applications.
Based on the [AMD Virtex UltraScale+](https://www.amd.com/en/products/adaptive-socs-and-fpgas/fpga/virtex-ultrascale-plus.html) VU47P FPGA, satellite operators can (de)modulate and (de)code multiple waveforms in the cloud.
The SDRs may be in an AWS Region or at [AWS Outposts](https://aws.amazon.com/outposts/) infrastructure for higher bandwidth, low-latency use cases.

![Capture-Iris-fig2-virt-satcom](https://github.com/user-attachments/assets/567d85dc-4103-4b94-a071-4a974f7aff53)

The primary repository for getting started with F2 is [here](https://github.com/aws/aws-fpga/). 

This repository provides additional sample [AWS Lambda](https://aws.amazon.com/lambda/) functions to retrieve FPGA usage metrics, scripts to orchestrate
loading of multiple waveforms, and networking benchmarks using virtual ethernet ([DPDK](https://www.dpdk.org/))


## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
