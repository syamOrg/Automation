#!/bin/bash
set -a 
source /etc/environment
apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive 
apt-get -y upgrade 
apt-get install openjdk-8-jre -y
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch |  apt-key add -
apt-get update
apt-get install apt-transport-https -y
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" >> /etc/apt/sources.list.d/elastic-5.x.list
apt-get update
apt-get install elasticsearch -y
/usr/share/elasticsearch/bin/elasticsearch-plugin install discovery-ec2 -s
apt-get update 
apt-get install logstash -y
apt-get install kibana -y

${elk_useradd}

