#!/usr/bin/env bash

echo "Starting FPGA clear image..."

# updated to use IMDSv2
TOKEN2=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` \
	&& curl -H "X-aws-ec2-metadata-token: $TOKEN2" http://169.254.169.254/latest/meta-data/

instanceid=$(curl -H "X-aws-ec2-metadata-token: $TOKEN2" http://169.254.169.254/latest/meta-data/instance-id)
instancetype=$(curl -H "X-aws-ec2-metadata-token: $TOKEN2" http://169.254.169.254/latest/meta-data/instance-type)
region=$(curl -H "X-aws-ec2-metadata-token: $TOKEN2" http://169.254.169.254/latest/meta-data/placement/region)

#instanceid=$(curl http://169.254.169.254/latest/meta-data/instance-id)
#instancetype=$(curl http://169.254.169.254/latest/meta-data/instance-type)

SECONDS=0

sudo fpga-clear-local-image -S 0 -H

duration=$SECONDS
echo "$duration seconds elapsed to clear image."

aws cloudwatch put-metric-data --namespace "FPGA metrics" --region $region --metric-name fpgaClearImageTime --value $duration --unit Seconds --dimensions InstanceID=$instanceid,InstanceType=$instancetype

