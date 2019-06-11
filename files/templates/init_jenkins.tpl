#!/bin/bash
set -a 
source /etc/environment

wget -qO - https://pkg.jenkins.io/debian/jenkins.io.key | apt-key add -
echo "deb https://pkg.jenkins.io/debian-stable binary/" >> /etc/apt/sources.list.d/jenkins.list
apt-get update
apt-get install openjdk-8-jre -y
apt-get install jenkins -y

${elk_useradd}
