#!/bin/bash
set -a 
source /etc/environment


hostnamectl set-hostname ${instance_hostname}

yum install epel-release -y
yum install java-1.8.0-openjdk.x86_64 -y
yum install wget -y
yum update -y 
reboot
