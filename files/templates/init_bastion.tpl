#!/bin/bash
set -a 
source /etc/environment

apt-get update
apt-get install wget -y
wget https://bootstrap.pypa.io/get-pip.py -O /opt/get-pip.py
python3 /opt/get-pip.py
pip3 install ansible==2.8.1
chmod 0766 /usr/local/bin/ansible*
apt-get install -y awscli
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl
#snap install kubectl --classic 
curl -LO https://github.com/kubernetes/kops/releases/download/1.7.0/kops-linux-amd64
chmod +x kops-linux-amd64
mv ./kops-linux-amd64 /usr/local/bin/kops

${useradd}