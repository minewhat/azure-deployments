#!/usr/bin/env bash
help()
{
    echo "This script installs workers on Ubuntu"
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
$WORKER_IP bigcommerce.choice.ai
$WORKER_IP highwire.choice.ai
$WORKER_IP americommerce.choice.ai
$WORKER_IP google.choice.ai
$WORKER_IP search.choice.ai
$WORKER_IP crawler.choice.ai
" >> /etc/hosts

sudo apt-get update --yes
# installing GIT
sudo apt-get --yes --force-yes install git

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
sudo apt-get install -y xfsprogs
sudo npm install -g forever
sudo apt-get -y install lynx
sudo apt-get -y install software-properties-common
sudo apt-get --yes install python-dev python-pip
sudo apt-get --yes install python-software-properties python g++
sudo pip install supervisor

#prepare folders
sudo mkdir /raid1/redisdb
sudo chown ubuntu:ubuntu /raid1/redisdb
cd /home/ubuntu
sudo -u ubuntu mkdir Servers
cd Servers
wget http://download.redis.io/releases/redis-3.0.7.tar.gz
tar zxvf redis-3.0.7.tar.gz
ln -s redis-3.0.7/ redis
sudo chown ubuntu:ubuntu /home/ubuntu
cd redis
sudo -u ubuntu make
# change owership of .npm n .forever folders to ubuntu
forever list
forever columns add dir
sudo chown -R ubuntu:ubuntu /home/ubuntu/.forever/
cd /home/ubuntu/minewhat
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/Server.git
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/server2.git
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/workers.git


cd /home/ubuntu/minewhat/Server/Config
sudo -u ubuntu git checkout MW_V2.3
#System Tuning Settings
cat linux/limits.conf | sudo tee -a /etc/security/limits.conf
cat linux/sysctl.conf | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
cd /home/ubuntu/

cd /home/ubuntu/minewhat/workers/configs
sudo cp supervisord.conf /etc/
sudo cp supervisord /etc/init.d/supervisord
sudo chmod +x /etc/init.d/supervisord
sudo service supervisord start
cd /home/ubuntu/minewhat/workers/shell_scripts
sudo -u ubuntu sh setup.sh

cd /home/ubuntu/minewhat/server2/choiceai
wget http://assets.choice.ai.s3.amazonaws.com/node_modules/node_modules_ubuntu_server.tar.gz
sudo -u ubuntu sh prepare.sh
sudo -u ubuntu /home/ubuntu/Servers/redis/src/redis-server /home/ubuntu/minewhat/Server/Config/redis/redishigh321.conf
sudo -u ubuntu /home/ubuntu/Servers/redis/src/redis-server /home/ubuntu/minewhat/Server/Config/redis/redislow321.conf
sudo -u ubuntu /home/ubuntu/Servers/redis/src/redis-server /home/ubuntu/minewhat/Server/Config/redis/redisstatscache1.conf


sudo service supervisord stop
echo "
[program:cai_TOPK_MANAGER]
command=python /home/ubuntu/minewhat/workers/workers/topkManager.py
user=ubuntu
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
logfile = /raid1/supervisorlogs/program:cai_TOPK_MANAGER.log
logfile_maxbytes = 50MB
logfile_backups=1

[program:cai_TOPK_1]
command=python /home/ubuntu/minewhat/workers/workers/topkWorkerV3.py 6409
user=ubuntu
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
logfile = /raid1/supervisorlogs/program:cai_TOPK_1.log
logfile_maxbytes = 50MB
logfile_backups=1

[program:cai_TOPK_2]
command=python /home/ubuntu/minewhat/workers/workers/topkWorkerV3.py 6419
user=ubuntu
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
logfile = /raid1/supervisorlogs/program:cai_TOPK_2.log
logfile_maxbytes = 50MB
logfile_backups=1

[program:cai_OTHERK]
command=python /home/ubuntu/minewhat/workers/workers/derivedkWorker.py
user=ubuntu
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
logfile = /raid1/supervisorlogs/program:cai_OTHERK.log
logfile_maxbytes = 50MB
logfile_backups=1

" >> /etc/supervisord.conf
sudo -u ubuntu service supervisord start
sudo -u ubuntu supervisorctl start all

# setup startup and shutdown scripts
sudo -u ubuntu cp -r /home/ubuntu/minewhat/server2/scripts/machinescripts/cai/jobs/* /home/ubuntu/
sudo cp /home/ubuntu/minewhat/server2/scripts/mwinit /etc/init.d/mwinit
sudo chmod +x /etc/init.d/mwinit
sudo chmod +x /home/ubuntu/startupscripts/basic.sh
sudo chmod +x /home/ubuntu/shutdownscripts/basic.sh
sudo update-rc.d mwinit defaults 10
