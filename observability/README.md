## Observability - parsing FPGA metrics (DSPs used, LUTs etc)


### Description
This folder contains a sample AWS Lambda function to parse FPGA metrics (DSPs, LUTs, latency etc) from 
Vitis HLS reports.

This is important when trying to orchestrate several AFIs/waveforms on a single FPGA i.e. knowing how many
resources were used, you can then combine functions to make a bigger Design Checkpoint / AFI to fully
utilize the FPGA fabric.

The Lambda function can be used as a reference for customers seeking to retrieve satcom KPIs, 
such as receive signal-to-noise ratio (SNR) and modulation coding rates (modcod), 
then deliver them to an S3 bucket.

Results can be visualized in a BI tool such as [Amazon QuickSight](https://aws.amazon.com/quicksight/)

### Example usage

Set the environment variables as follows

| Key      | Value       | Description |
| ---------| ----------- | ----------- |
| bucketName  | your-bucket-name-12345 | location of the S3 bucket to store the JSON output |
| csynthRpt | your-design_csynth.rpt | Vitis HLS report for your-design |


### Configuration
* permission to put objects to S3
* timeout extended to at least 30s