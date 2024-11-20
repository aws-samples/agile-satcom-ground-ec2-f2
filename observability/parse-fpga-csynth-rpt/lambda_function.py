import json
import boto3
import os
import botocore
from botocore.exceptions import ClientError
import logging
import uuid
import time
import calendar
from datetime import datetime, timedelta
import argparse
import random


def lambda_handler(event, context):
    
    # this can be run either as cmd line py program or a Lambda based on the execution environment    
    execEnv = str(os.getenv('AWS_EXECUTION_ENV'))
    if execEnv.startswith("AWS_Lambda"):
        bucketName = os.getenv('bucketName')
        csynthRpt = os.getenv('csynthRpt')
    else:
        parser = argparse.ArgumentParser()
        parser.add_argument("-b", "--bucketname", help="This bucket will hold the output JSON metrics")
        parser.add_argument("-c", "--csynthRpt", help="This is the input file of FPGA csynth report")
        args = parser.parse_args()
        bucketName = args.bucketname
        csynthRpt = args.csynthRpt

    if None in (bucketName, csynthRpt):
        print("Invalid bucketName and/or input files")
        return -1
    else:
        print("Bucket: ", bucketName, " FPGA csynth report: ", csynthRpt)
        
    # read in the FPGA csynth report data file (rpt)
    with open(csynthRpt) as f_csynthRpt:
        lines = f_csynthRpt.readlines()

    # parse the csynth report file
    metricsDict = {}
    i=0
    for line in lines:
        if "* Date:" in line:
            date_fields = line.split()[-4:]
            month_num = list(calendar.month_abbr).index(date_fields[0])
            # convert to mm-dd-YYYY HH:MM:SS format
            date_str = str(month_num) + "-" + date_fields[1] + "-" + date_fields[3] + " " + date_fields[2]
            metricsDict['date'] = date_str

        if "* Project:" in line:
            metricsDict['project'] = line.split()[-1]

        if "* Target device:" in line:
            metricsDict['device'] = line.split()[-1]
        
        # skip ahead to get the latency mix, max
        # in some cases latency cant be calculated and shows as ' ?' - set these to 0
        if "+ Latency:" in line:
            latency = lines[i+6]
            metricsDict['latency'] = {}
            
            lat_min = latency.split("|")[1]
            if lat_min.strip() == '?':
                metricsDict['latency']['min'] = 0
            else:
                metricsDict['latency']['min'] = int(lat_min)
            
            lat_max = latency.split("|")[2]
            if lat_max.strip() == '?':
                metricsDict['latency']['max'] = 0
            else:
                metricsDict['latency']['max'] = int(lat_max)

        # grab the DSP, LUT metrics
        if "== Utilization Estimates" in line:
            metricsDict['dsp'] = {}
            metricsDict['lut'] = {}
            
            total = lines[i+14]
            metricsDict['dsp']['usage'] = int(total.split("|")[3])
            metricsDict['lut']['usage'] = int(total.split("|")[5])
            
            available = lines[i+20]
            metricsDict['dsp']['available'] = int(available.split("|")[3])
            metricsDict['lut']['available'] = int(available.split("|")[5])
            
            # if usage too low then Vitis reports as "~0" which is problematic
            # utilization is in percent
            metricsDict['dsp']['utilization'] = round(metricsDict['dsp']['usage'] / metricsDict['dsp']['available'] * 100, 2)
            metricsDict['lut']['utilization'] = round(metricsDict['lut']['usage'] / metricsDict['lut']['available'] * 100, 2)

        i += 1

    # dump metricsDict to a json file
    metrics_json = json.dumps(metricsDict, indent=4)
    
    # upload the metrics to S3 bucket
    csynth_file = os.path.basename(csynthRpt)
    cysynth_prefix = os.path.splitext(csynth_file)[0]
    
    now = datetime.now()
    date_time_fmt = now.strftime("%m-%d-%Y-%H-%M-%S")
    
    obj_name = "vitis-metrics/" + cysynth_prefix + "-" + date_time_fmt + ".json"
    upload_json(metrics_json, bucketName, obj_name)
    
    # print(metrics_json)


# generate a function to upload a JSON object to S3
def upload_json(json_obj, bucket, object_name):
    """Upload a JSON object to an S3 bucket

    :param json_obj: JSON object to upload
    :param bucket: Bucket to upload to
    :param object_name: S3 object name
    :return: True if file was uploaded, else False
    """

    # Upload the file
    s3_client = boto3.client('s3')
    try:
        response = s3_client.put_object(Body=json_obj, Bucket=bucket, Key=object_name)
    except ClientError as e:
        logging.error(e)
        return False
    return True




# allow local Python execution testing
if __name__ == '__main__':
    lambda_handler(None,None)