#!/usr/bin/env python3

# -*- coding: utf-8 -*

import boto3
import json
import sys
import pickle
import os
from collections import defaultdict
import pexpect
import subprocess
import argparse

# get Name tag
def parse_sets(tags):
    result = {}
    for tag in tags:
        key = tag['Key']
        val = tag['Value']
        result[key] = val
    return result

# get instance with instance name for update
def get_ec2_instance_list(profile="default"):
    instance_list = []
    instances = get_instances(profile)
    for reservations in instances['Reservations']:
        for instance in reservations['Instances']:
            tags = parse_sets(instance['Tags'])
            instance_list.append(tags['Name'])
    return instance_list

# use cache 
def get_instances(profile="default"):
    try: instances = pickle.load(open(os.path.dirname(os.path.abspath(__file__)) + "/" + profile + "_instances.cache", "rb"))
    except (OSError, IOError) as e:
        session = boto3.session.Session(profile_name=profile)
        ec2 = session.client('ec2')
        instances =  ec2.describe_instances()
        pickle.dump(instances, open(os.path.dirname(os.path.abspath(__file__)) + "/" + profile + "_instances.cache", "wb"))
    return instances

## find instance with instance name
def find_ec2_instanceid(instance_name, profile_name):
    instances = get_instances(profile_name)
    for reservations in instances['Reservations']:
        for instance in reservations['Instances']:
            tags = parse_sets(instance['Tags'])
            if tags['Name'] == instance_name:
                return instance['InstanceId']

def parse_sets(tags):
    result = {}
    for tag in tags:
        key = tag['Key']
        val = tag['Value']
        result[key] = val
    return result

if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("arg1")
    parser.add_argument("--profile", help="set profile")
    args = parser.parse_args()

    if not args.profile :
        profile = "default"
    else:
        profile = args.profile

    if args.arg1 == 'update':
        instance_list = get_ec2_instance_list(profile)
        instances_txt = ' '.join(map(str, instance_list))

        path = os.environ['HOME'] + '/.aws_instances_' + profile

        with open(path, mode='w') as f:
            f.write(instances_txt)
        exit()

    instance_name =  args.arg1

    instance_id = find_ec2_instanceid(instance_name, profile)

    if instance_id == None:
        print("instance not found, please check Name tag and environment")
        exit()

    stty_size = subprocess.check_output(['stty','size']).decode('utf-8').strip().split()
    rows = stty_size[0]
    cols = stty_size[1]

    prc = pexpect.spawn("aws ssm start-session --region ap-northeast-1 --target " + instance_id + " --profile " + profile)

    if 'TMUX' in os.environ:
        os.system("tmux rename-window " + instance_name)

    if 'EC2USER' and 'EC2PASSWORD' in os.environ:
        ec2user= os.environ['EC2USER']
        ec2password = os.environ['EC2PASSWORD']
        prc.expect('$')
        prc.sendline('su - ' + ec2user)
        prc.expect("Password:")
        prc.sendline(ec2password )

    prc.expect('$')
    prc.sendline("stty rows " + rows + " cols " + cols)
    prc.interact()

