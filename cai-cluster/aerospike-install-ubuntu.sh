#!/usr/bin/env bash
help()
{
    echo "This script installs aerospike on Ubuntu"
    echo "Parameters:"
    echo "git credentials username:password"
    echo "static mongo IP"
    echo "static Elasticsearch IP"
    echo "static Aerospike IP"
    echo "static Cassandra IP"
    echo "static Cruncher IP"
}

#Script Parameters
GIT_AUTH="$1"
MONGO_IP="$2"
ES_IP="$3"
AE_IP="$4"
CASSA_IP="$5"
CRUNCHER_IP="$6"
sudo apt-get update --yes

# installing GIT
sudo apt-get --yes --force-yes install git

# create mount folder
sudo mkdir -p /mnt

# give read/write permission to all users
sudo chmod -R a+w /mnt
# create mount folder
sudo mkdir -p /raid1
sudo mkdir -p /home/ubuntu/minewhat
sudo chmod -R a+w /raid1
sudo chown -R ubuntu:ubuntu /raid1
sudo chown -R ubuntu:ubuntu /home/ubuntu/minewhat
cd /home/ubuntu/minewhat
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/Server.git
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/server2.git
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/workers.git
echo "
$MONGO_IP  mongo1.choice.ai
$MONGO_IP  mongo2.choice.ai
$CASSA_IP cassa1.choice.ai
$CASSA_IP cassa2.choice.ai
$AE_IP aerospike1.choice.ai
$AE_IP aerospike2.choice.ai
$ES_IP elastic.azure.minewhat.com
$CRUNCHER_IP caizooremote.choice.ai
$CRUNCHER_IP caicollector1.choice.ai
$CRUNCHER_IP caicollector2.choice.ai
$CRUNCHER_IP caizoolocal.choice.ai
$CRUNCHER_IP zoo1.choice.ai
$CRUNCHER_IP mwzooremote.linodefarm.choice.ai
$CRUNCHER_IP mwcollector1.linodefarm.choice.ai
$CRUNCHER_IP mwcollector2.linodefarm.choice.ai
$CRUNCHER_IP zoo1.linodefarm.choice.ai
$CRUNCHER_IP mwzoolocal.linodefarm.choice.ai
" >> /etc/hosts


cd /home/ubuntu
wget -O aerospike.tgz 'http://aerospike.com/download/server/latest/artifact/ubuntu12'
tar -xvf aerospike.tgz
cd aerospike-server-community-3.7.4.1-ubuntu12.04/
sudo ./asinstall # will install the .rpm packages
sudo service aerospike start
# sudo tail -f /var/log/aerospike/aerospike.log
# wait for it. "service ready: soon there will be cake!"