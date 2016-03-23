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
" >> /etc/hosts
sudo add-apt-repository -y ppa:chris-lea/node.js
sudo apt-get update --yes
# installing GIT
sudo apt-get --yes --force-yes install git

# create mount folder
sudo mkdir -p /raid1
sudo mkdir -p /mnt
# give read/write permission to all users
sudo chown -R ubuntu:ubuntu /raid1
sudo chown -R ubuntu:ubuntu /mnt
sudo apt-get -y install unzip
sudo apt-get -y install make
sudo apt-get -y install git pkg-config autoconf automake
sudo apt-get -y install build-essential maven2
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

sudo mkdir -p /home/ubuntu/minewhat
sudo chmod -R a+w /raid1
sudo mkdir -p /raid1/supervisorlogs
sudo mkdir /mnt/storml
sudo mkdir /mnt/zookeeper2
sudo mkdir /mnt/kafka-logs
sudo chown ubuntu:ubuntu /mnt/storml/
sudo chown ubuntu:ubuntu /mnt/zookeeper2/
sudo chown ubuntu:ubuntu /mnt/kafka-logs
sudo chown -R ubuntu:ubuntu /raid1
sudo chown -R ubuntu:ubuntu /home/ubuntu/minewhat
cd /home/ubuntu/minewhat
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/Server.git
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/server2.git
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/workers.git
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/addons.git

cd /home/ubuntu/minewhat/Server/Config
sudo -u ubuntu git checkout MW_V2.3

cd /home/ubuntu/minewhat/workers/configs
sudo -u ubuntu git checkout cai_rel
sudo cp supervisord.conf /etc/
sudo cp supervisord /etc/init.d/supervisord
sudo chmod +x /etc/init.d/supervisord
sudo service supervisord start
cd /home/ubuntu/minewhat/workers/shell_scripts
sudo -u ubuntu sh setup.sh

sudo apt-get install nginx --yes
cd /home/ubuntu/minewhat/server2/config/nginx
cp choice* /etc/nginx
cp dhparams.pem /etc/nginx/conf.d
cp choice_conf_d/* /etc/nginx/conf.d
sudo service nginx restart

cd /home/ubuntu/minewhat/addons/choiceAI_Addons
sudo -u ubuntu sh prepare.sh
sudo -u ubuntu sh startshopify.sh
sudo -u ubuntu sh startbigcommerce.sh

cd /home/ubuntu/minewhat/server2/choiceai
sudo -u ubuntu git checkout cai_rel
sudo -u ubuntu tar -zxvf node_modules_ubuntu.tar.gz
sudo -u ubuntu sh prepare.sh
sudo -u ubuntu /home/ubuntu/Servers/redis/src/redis-server /home/ubuntu/minewhat/Server/Config/redis/redissession.conf
sudo -u ubuntu /home/ubuntu/Servers/redis/src/redis-server /home/ubuntu/minewhat/Server/Config/redis/redisstatscache1.conf
sudo -u ubuntu sh scripts/startworker.sh

sudo service supervisord stop
echo "
[program:cai_general_worker]
command=/usr/bin/python /home/ubuntu/minewhat/workers/workers/generalWorker.py
user=ubuntu
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
logfile = /raid1/supervisorlogs/program:cai_general_worker.log
logfile_maxbytes = 50MB
logfile_backups=1

[program:cai_esSyncWorker_revamp]
command=/usr/bin/python /home/ubuntu/minewhat/workers/workers/esSyncWorker_revamp.py
user=ubuntu
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
logfile = /raid1/supervisorlogs/program:cai_esSyncWorker_revamp.log
logfile_maxbytes = 50MB
logfile_backups=1
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1

[program:cai_productWorker]
command=/usr/bin/python /home/ubuntu/minewhat/workers/workers/productWorker.py
user=ubuntu
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
logfile = /raid1/supervisorlogs/program:cai_productWorker.log
logfile_maxbytes = 50MB
logfile_backups=1


[program:cai_identifyTags]
command=/usr/bin/python /home/ubuntu/minewhat/workers/workers/choiceai/identifyTags.py
user=ubuntu
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
logfile = /raid1/supervisorlogs/program:cai_identifyTags.log
logfile_maxbytes = 50MB
logfile_backups=1

[program:cai_eventLoader]
command=/usr/bin/python /home/ubuntu/minewhat/workers/workers/choiceai/eventLoader.py
user=ubuntu
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
logfile = /raid1/supervisorlogs/program:cai_eventLoader.log
logfile_maxbytes = 50MB
logfile_backups=1

[program:cai_trainClassifier]
command=/usr/bin/python /home/ubuntu/minewhat/workers/workers/choiceai/trainClassifier.py
user=ubuntu
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
logfile = /raid1/supervisorlogs/program:cai_trainClassifier.log
logfile_maxbytes = 50MB
logfile_backups=1

[program:cai_processOrders]
command=/usr/bin/python /home/ubuntu/minewhat/workers/workers/choiceai/processOrders.py
user=ubuntu
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
logfile = /raid1/supervisorlogs/program:cai_processOrders.log
logfile_maxbytes = 50MB
logfile_backups=1

[program:cai_annCreator]
command=/usr/bin/python /home/ubuntu/minewhat/workers/workers/choiceai/annCreator.py
user=ubuntu
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
logfile = /raid1/supervisorlogs/program:cai_annCreator.log
logfile_maxbytes = 50MB
logfile_backups=1

[program:cai_corpusWorker]
command=/usr/bin/python /home/ubuntu/minewhat/workers/workers/choiceai/corpusWorker.py
user=ubuntu
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
logfile = /raid1/supervisorlogs/program:cai_corpusWorker.log
logfile_maxbytes = 50MB
logfile_backups=1

[program:cai_imagesDownloader]
command=/usr/bin/python /home/ubuntu/minewhat/workers/workers/choiceai/imagesDownloader.py
user=ubuntu
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
logfile = /raid1/supervisorlogs/program:cai_imagesDownloader.log
logfile_maxbytes = 50MB
logfile_backups=1

[program:cai_indexCreator]
command=/usr/bin/python /home/ubuntu/minewhat/workers/workers/choiceai/indexCreator.py
user=ubuntu
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
logfile = /raid1/supervisorlogs/program:cai_indexCreator.log
logfile_maxbytes = 50MB
logfile_backups=1

[program:cai_crawlerWorker_1]
command=/usr/bin/python /home/ubuntu/minewhat/workers/workers/crawlerWorker.py
user=ubuntu
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
logfile = /raid1/supervisorlogs/program:crawlerWorker_1.log
logfile_maxbytes = 50MB
logfile_backups=1

[program:cai_crawlerWorker_2]
command=/usr/bin/python /home/ubuntu/minewhat/workers/workers/crawlerWorker.py
user=ubuntu
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
logfile = /raid1/supervisorlogs/program:crawlerWorker_2.log
logfile_maxbytes = 50MB
logfile_backups=1

[program:cai_crawlerWorker_3]
command=/usr/bin/python /home/ubuntu/minewhat/workers/workers/crawlerWorker.py
user=ubuntu
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
logfile = /raid1/supervisorlogs/program:crawlerWorker_3.log
logfile_maxbytes = 50MB
logfile_backups=1

[program:cai_crawlerWorker_4]
command=/usr/bin/python /home/ubuntu/minewhat/workers/workers/crawlerWorker.py
user=ubuntu
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
logfile = /raid1/supervisorlogs/program:crawlerWorker_4.log
logfile_maxbytes = 50MB
logfile_backups=1

[program:cai_crawlerWorker_5]
command=/usr/bin/python /home/ubuntu/minewhat/workers/workers/crawlerWorker.py
user=ubuntu
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
logfile = /raid1/supervisorlogs/program:crawlerWorker_5.log
logfile_maxbytes = 50MB
logfile_backups=1
" >> /etc/supervisord.conf
sudo -u ubuntu service supervisord start
sudo -u ubuntu supervisorctl start all

# setup startup and shutdown scripts
sudo -u ubuntu cp -r /home/ubuntu/minewhat/server2/scripts/machinescripts/choice/workers/* /home/ubuntu/

cat << EOF > /etc/init/choice.conf
# choice
description "start choice specific services"

start on starting
script
    /home/ubuntu/startupscripts/basic.sh
end script
EOF