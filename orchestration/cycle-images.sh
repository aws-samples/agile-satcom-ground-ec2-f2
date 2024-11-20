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

instanceid=$(curl http://169.254.169.254/latest/meta-data/instance-id)
instancetype=$(curl http://169.254.169.254/latest/meta-data/instance-type)

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
  aws cloudwatch put-metric-data --namespace "FPGA metrics" --metric-name fpgaCountLoadImages --value $cnt --unit Count --dimensions InstanceID=$instanceid,InstanceType=$instancetype

done

echo "FPGA cycling script complete"

