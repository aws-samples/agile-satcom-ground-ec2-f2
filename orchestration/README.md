## Orchestration - loading and resetting different AFI waveforms


### Description
This folder contains sample scripts to load and reset different AFIs representing different 
satcom waveforms. 

This is important when trying to orchestrate several AFIs/waveforms on a single FPGA i.e. being able to 
rapidly cycle between waveform images. 

[Amazon CloudWatch](https://aws.amazon.com/cloudwatch/) custom metrics are pushed to measure 
the load and clear times respectively, to validate that waveform cycle times meet latency requirements.

Results can be visualized in a Cloudwatch [dashboard](https://aws.amazon.com/cloudwatch/features/telemetry-alarms-dashboards/)
along side standard CPU and network utilization metrics.

### Example usage

On an F2 instance, edit cycle-images.sh to run your application command line.

Pass in the 2 Amazon Global FPGA id's (AGFI) e.g

`[>] ./cycle-images.sh agfi-1a2b3c4d5e6f7g8h9i agfi-9a8b7c6d5e4f3g2h1i`

### Configuration
You need to pre-install the FPGA Management tools by sourcing the sdk_setup.sh script in the AWS F2 github repository

```bash
    $ cd aws-fpga-preview
    $ source sdk_setup.sh
```
