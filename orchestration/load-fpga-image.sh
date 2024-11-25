#!/usr/bin/env bash

echo "Starting FPGA load image..."

# updated to use IMDSv2
TOKEN3=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` \
        && curl -H "X-aws-ec2-metadata-token: $TOKEN3" http://169.254.169.254/latest/meta-data/

instanceid=$(curl -H "X-aws-ec2-metadata-token: $TOKEN3" http://169.254.169.254/latest/meta-data/instance-id)
instancetype=$(curl -H "X-aws-ec2-metadata-token: $TOKEN3" http://169.254.169.254/latest/meta-data/instance-type)
region=$(curl -H "X-aws-ec2-metadata-token: $TOKEN3" http://169.254.169.254/latest/meta-data/placement/region)

#instanceid=$(curl http://169.254.169.254/latest/meta-data/instance-id)
#instancetype=$(curl http://169.254.169.254/latest/meta-data/instance-type)

if [ "$#" -ne 1 ]
then
  echo "Error - please supply an AGFI id argument"
  exit 1
fi

SECONDS=0

echo "AGFI id : $1"

sudo fpga-load-local-image -S 0 -I $1 -H

duration=$SECONDS
echo "$duration seconds elapsed to load image."

aws cloudwatch put-metric-data --namespace "FPGA metrics" --metric-name --region $region fpgaLoadImageTime --value $duration --unit Seconds --dimensions InstanceID=$instanceid,InstanceType=$instancetype



