#!/usr/bin/env bash

echo "Starting FPGA image cycling..."

if [ "$#" -ne 2 ]
then
  echo "Error - please supply 2 AGFI id arguments"
  exit 1
fi

echo "AGFI id's : $1 $2"

SCRIPT_PATH="/home/ubuntu/src/project_data/fpga-scripts"
cd ../

# updated to use IMDSv2
TOKEN1=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` \
        && curl -H "X-aws-ec2-metadata-token: $TOKEN1" http://169.254.169.254/latest/meta-data/

instanceid=$(curl -H "X-aws-ec2-metadata-token: $TOKEN1" http://169.254.169.254/latest/meta-data/instance-id)
instancetype=$(curl -H "X-aws-ec2-metadata-token: $TOKEN1" http://169.254.169.254/latest/meta-data/instance-type)
region=$(curl -H "X-aws-ec2-metadata-token: $TOKEN1" http://169.254.169.254/latest/meta-data/placement/region)

#instanceid=$(curl http://169.254.169.254/latest/meta-data/instance-id)
#instancetype=$(curl http://169.254.169.254/latest/meta-data/instance-type)

cnt=0

for n in {1..10};
do

  $SCRIPT_PATH/clear-fpga-image.sh

  $SCRIPT_PATH/load-fpga-image.sh $1

  # replace with your application/waveform #1
  cd cl_mem_perf
  sudo ./test_hbm_perf32
  cd ..

  sleep 10

  $SCRIPT_PATH/clear-fpga-image.sh

  $SCRIPT_PATH/load-fpga-image.sh $2

  # replace with your application/waveform #2
  cd cl_mem_perf
  sudo ./test_aws_clk_gen
  cd ..

  cnt=$((n*2))
  echo "$cnt count of load image invocations"
  aws cloudwatch put-metric-data --namespace "FPGA metrics" --region $region --metric-name fpgaCountLoadImages --value $cnt --unit Count --dimensions InstanceID=$instanceid,InstanceType=$instancetype

done

echo "FPGA cycling script complete"

