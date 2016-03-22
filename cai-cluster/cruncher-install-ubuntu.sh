#!/usr/bin/env bash
help()
{
    echo "This script installs cruncher on Ubuntu"
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

# debconf
sudo apt-get install debconf-utils --yes

# JDK
sudo add-apt-repository ppa:webupd8team/java --yes
sudo apt-get update --yes
echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections
sudo apt-get install oracle-java7-installer --yes
sudo apt-get install oracle-java7-set-default --yes


# installing GIT
sudo apt-get --yes --force-yes install git
# install maven
sudo apt-get install maven --yes

# device queue settings
echo noop > /sys/block/sdb/queue/scheduler
echo 0 > /sys/block/sdb/queue/read_ahead_kb
echo 0 > /sys/block/sdb/queue/rotational

# most common need
sudo apt-get -y install unzip
sudo apt-get -y install make
sudo apt-get -y install build-essential maven2
sudo apt-get -y install uuid-dev libtool
sudo apt-get -y install git pkg-config autoconf automake
sudo apt-get -y install python-setuptools python-pip
sudo apt-get -y install lynx
sudo apt-get -y install software-properties-common
sudo apt-get install -y python-software-properties python g++ make
sudo add-apt-repository -y ppa:chris-lea/node.js
sudo apt-get update
sudo apt-get install -y nodejs
sudo apt-get install -y xfsprogs
sudo pip install supervisor
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

# setup stormkafkamon
cd stormkafkamon
sudo python setup.py install

# setup storm cluster
cd /home/ubuntu/minewhat/Server/Config
sudo -u ubuntu git checkout MW_V2.3
sudo -u ubuntu ./StromAMIprepare.sh
sudo -u ubuntu ./RedisAMIprepare.sh
sudo -u ubuntu ./setupprepare.sh
sudo -u ubuntu ./setupsupervisord.sh
sudo -u ubuntu ./addcleanuptocron.sh

# change owership of .npm n .forever folders to ubuntu
sudo chown -R ubuntu:ubuntu /home/ubuntu/.npm/
sudo chown -R ubuntu:ubuntu /home/ubuntu/.forever/

# install node modules
cd /home/ubuntu/minewhat/Server/stats
sudo -u ubuntu npm install
cd /home/ubuntu/minewhat/Server/evictor
sudo -u ubuntu npm install
cd /home/ubuntu/minewhat/Server/listener
sudo -u ubuntu npm install

# setup kafka queues
cd /home/ubuntu/minewhat/Server/listener
node createQueues.js

# setup startup and shutdown scripts
sudo -u ubuntu cp -r /home/ubuntu/minewhat/server2/scripts/machinescripts/myntra/crunchers/* /home/ubuntu/

# setup utility scripts
sudo -u ubuntu cp /home/ubuntu/minewhat/server2/scripts/workerLogs.sh /home/ubuntu/
sudo -u ubuntu cp /home/ubuntu/minewhat/server2/scripts/queueStatus.sh /home/ubuntu/