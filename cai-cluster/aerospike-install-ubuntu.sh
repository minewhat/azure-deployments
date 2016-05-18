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
WORKER_IP="$7"
echo "
deb http://nginx.org/packages/mainline/ubuntu/ trusty nginx
deb-src http://nginx.org/packages/mainline/ubuntu/ trusty nginx
" > /etc/apt/sources.list.d/nginx.list
wget -q -O- http://nginx.org/keys/nginx_signing.key | sudo apt-key add -
curl -sL https://deb.nodesource.com/setup_0.12 | sudo bash -
sudo add-apt-repository ppa:webupd8team/java --yes
sudo apt-get update --yes
# debconf
sudo apt-get install debconf-utils --yes
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

# create mount folder
sudo mkdir -p /raid1
sudo mkdir -p /home/ubuntu/minewhat
sudo mkdir -p /raid1/supervisorlogs
sudo mkdir /raid1/storml
sudo mkdir /raid1/zookeeper2
sudo mkdir /raid1/kafka-logs
sudo chown -R ubuntu:ubuntu /raid1
sudo chown -R ubuntu:ubuntu /home/ubuntu/minewhat
# give read/write permission to all users
sudo apt-get -y install unzip
sudo apt-get -y install make
sudo apt-get -y install pkg-config autoconf automake
sudo apt-get -y install build-essential maven2 libkrb5-dev
sudo apt-get -y install libc6-dev-i386
sudo apt-get -y install libev4 libev-dev
sudo apt-get -y install uuid-dev libtool
sudo apt-get -y install python-setuptools
sudo apt-get install -y nodejs
sudo apt-get install -y xfsprogs
sudo npm install -g forever
sudo apt-get -y install lynx
sudo apt-get -y install software-properties-common
sudo apt-get --yes install python-dev python-pip
sudo apt-get --yes install python-software-properties python g++
sudo pip install supervisor
forever list
forever columns add dir


cd /home/ubuntu/minewhat
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/Server.git
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/server2.git
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/workers.git
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/app2.git
echo "
$MONGO_IP mongo1.choice.ai
$MONGO_IP mongo2.choice.ai
$MONGO_IP mongodbdomain1.linodefarm.minewhat.com
$MONGO_IP mongodbdomain2.linodefarm.minewhat.com
$MONGO_IP mongodb1.linodefarm.minewhat.com
$MONGO_IP mongodb2.linodefarm.minewhat.com
$CASSA_IP cassa1.choice.ai
$CASSA_IP cassa2.choice.ai
$CASSA_IP cassaseed5.linodefarm.minewhat.com
$CASSA_IP cassaseed6.linodefarm.minewhat.com
$CASSA_IP cassaseedrealtime.linodefarm.minewhat.com
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
$CRUNCHER_IP mwzoo.linodefarm.minewhat.com
$CRUNCHER_IP mwzoo2.linodefarm.minewhat.com
$CRUNCHER_IP mwzooorder.linodefarm.minewhat.com
$WORKER_IP visual.choice.ai
$WORKER_IP shopify.choice.ai
$WORKER_IP mailchimp.choice.ai
$WORKER_IP bigcommerce.choice.ai
$WORKER_IP highwire.choice.ai
$WORKER_IP americommerce.choice.ai
$WORKER_IP google.choice.ai
$WORKER_IP search.choice.ai
$WORKER_IP crawler.choice.ai
" >> /etc/hosts

cd /home/ubuntu/minewhat/Server/Config
sudo -u ubuntu git checkout MW_V2.3
sudo -u ubuntu ./StromAMIprepare.sh
sudo -u ubuntu ./RedisAMIprepare.sh
sudo -u ubuntu ./setupprepare.sh
sudo -u ubuntu ./setupsupervisord.sh
sudo -u ubuntu ./addcleanuptocron.sh
#System Tuning Settings
cat linux/limits.conf | sudo tee -a /etc/security/limits.conf
cat linux/sysctl.conf | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
cd /home/ubuntu
wget -O aerospike.tgz 'http://aerospike.com/download/server/3.7.5.1/artifact/ubuntu14'
tar -xvf aerospike.tgz
cd aerospike-server-community-3.7.5.1-ubuntu14.04/
sudo ./asinstall # will install the .rpm packages
sudo cp /home/ubuntu/minewhat/server2/choiceai/aerospike.conf /etc/aerospike
sudo service aerospike start
# sudo tail -f /var/log/aerospike/aerospike.log
# wait for it. "service ready: soon there will be cake!"
#Copy GEO
sudo -u ubuntu mkdir GeoIP
cp /home/ubuntu/minewhat/Server/Config/Geo* GeoIP
sudo -u ubuntu gunzip -f GeoIP/*
sudo chown -R ubuntu:ubuntu /home/ubuntu/.npm/
sudo chown -R ubuntu:ubuntu /home/ubuntu/.forever/

cd /home/ubuntu/minewhat/server2/choiceai
wget http://assets.choice.ai.s3.amazonaws.com/node_modules/node_modules_ubuntu_server.tar.gz
sudo -u ubuntu sh prepare.sh
rm -rf node_modules/memwatch-next
rm -rf node_modules/kafka-node
npm i kafka-node memwatch-next
sudo -u ubuntu /home/ubuntu/Servers/redis/src/redis-server /home/ubuntu/minewhat/Server/Config/redis/redissession.conf
sudo -u ubuntu /home/ubuntu/Servers/redis/src/redis-server /home/ubuntu/minewhat/Server/Config/redis/redisstatscache1.conf
sudo -u ubuntu sh scripts/startwidgetData.sh

sudo apt-get install nginx --yes
cd /home/ubuntu/minewhat/server2/config/nginx
sudo cp choice* /etc/nginx
sudo cp nginx.conf /etc/nginx
sudo cp dhparams.pem /etc/nginx/conf.d
sudo cp cai_conf_d/* /etc/nginx/conf.d
sudo service nginx restart

# setup startup and shutdown scripts
sudo -u ubuntu cp -r /home/ubuntu/minewhat/server2/scripts/machinescripts/cai/aerospike/* /home/ubuntu/
sudo cp /home/ubuntu/minewhat/server2/scripts/mwinit /etc/init.d/mwinit
sudo chmod +x /etc/init.d/mwinit
sudo chmod +x /home/ubuntu/startupscripts/basic.sh
sudo chmod +x /home/ubuntu/shutdownscripts/basic.sh
sudo update-rc.d mwinit defaults 10
