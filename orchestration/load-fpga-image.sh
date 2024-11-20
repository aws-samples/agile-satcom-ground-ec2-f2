#!/usr/bin/env bash

echo "Starting FPGA load image..."

instanceid=$(curl http://169.254.169.254/latest/meta-data/instance-id)
instancetype=$(curl http://169.254.169.254/latest/meta-data/instance-type)

if [ "$#" -ne 1 ]
then
  echo "Error - please supply an AGFI id argument"
  exit 1
fi

SECONDS=0

echo "AGFI id : $1"

sudo fpga-load-local-image -S 0 -I $1 -H

duration=$SECONDS
echo "$duration seconds elapsed."

aws cloudwatch put-metric-data --namespace "FPGA metrics" --metric-name fpgaLoadImageTime --value $duration --unit Seconds --dimensions InstanceID=$instanceid,InstanceType=$instancetype



