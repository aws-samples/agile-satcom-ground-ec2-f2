#!/usr/bin/env bash

echo "Starting FPGA clear image..."

instanceid=$(curl http://169.254.169.254/latest/meta-data/instance-id)
instancetype=$(curl http://169.254.169.254/latest/meta-data/instance-type)

SECONDS=0

sudo fpga-clear-local-image -S 0 -H

duration=$SECONDS
echo "$duration seconds elapsed."

aws cloudwatch put-metric-data --namespace "FPGA metrics" --metric-name fpgaClearImageTime --value $duration --unit Seconds --dimensions InstanceID=$instanceid,InstanceType=$instancetype

