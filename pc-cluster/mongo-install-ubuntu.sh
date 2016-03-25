#!/usr/bin/env bash
help()
{
    echo "This script installs mongo on Ubuntu"
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

sudo add-apt-repository -y ppa:nginx/stable
curl -sL https://deb.nodesource.com/setup_0.12 | sudo bash -
# mongo install
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list
sudo apt-get update --yes
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
sudo mkdir -p /mnt
# give read/write permission to all users
sudo mkdir -p /raid1/mongo/
sudo mkdir -p /raid1/mongo/log
sudo mkdir -p /raid1/mongo/data
sudo mkdir -p /home/ubuntu/minewhat
# give read/write permission to all users
sudo chown -R ubuntu:ubuntu /raid1
sudo chown -R ubuntu:ubuntu /mnt
sudo chown -R ubuntu:ubuntu /home/ubuntu/minewhat

# most common need
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

#prepare folders
sudo mkdir /mnt/redisdb
sudo chown ubuntu:ubuntu /mnt/redisdb
cd ~
mkdir Servers
cd Servers
wget http://download.redis.io/releases/redis-2.8.19.tar.gz
tar zxvf redis-2.8.19.tar.gz
ln -s redis-2.8.19/ redis
cd redis
make 32bit

# Disable THP
sudo echo never > /sys/kernel/mm/transparent_hugepage/enabled
sudo echo never > /sys/kernel/mm/transparent_hugepage/defrag
sudo grep -q -F 'transparent_hugepage=never' /etc/default/grub || echo 'transparent_hugepage=never' >> /etc/default/grub

sudo apt-get install -y mongodb-org=3.0.7 mongodb-org-server=3.0.7 mongodb-org-shell=3.0.7 mongodb-org-mongos=3.0.7 mongodb-org-tools=3.0.7
sudo service mongod stop
echo "
systemLog:
   destination: file
   path: /raid1/mongo/log/mongodb.log
   logAppend: true
storage:
  engine: wiredTiger
  dbPath: /raid1/mongo/data
processManagement:
   fork: true
net:
  port: 27017
  bindIp: 0.0.0.0
replication:
   replSetName: mw
" > /etc/mongod.conf
sudo -u ubuntu /usr/bin/mongod --config /etc/mongod.conf
sleep 2
MY_IPS=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`

echo "
$MY_IPS mongo1.productclues.com
$MY_IPS mongo2.productclues.com
$MY_IPS mongodbdomain1.linodefarm.productclues.com
$MY_IPS mongodbdomain2.linodefarm.productclues.com
$MY_IPS caizooremote.productclues.com
$MY_IPS caicollector1.productclues.com
$MY_IPS caicollector2.productclues.com
$MY_IPS caizoolocal.productclues.com
$MY_IPS zoo1.productclues.com
$MY_IPS mwzooremote.linodefarm.productclues.com
$MY_IPS mwcollector1.linodefarm.productclues.com
$MY_IPS zoo1.linodefarm.productclues.com
$MY_IPS mwzoolocal.linodefarm.productclues.com
$MY_IPS mwzooremote.linodefarm.minewhat.com
$MY_IPS mwcollector1.linodefarm.minewhat.com
$MY_IPS zoo1.linodefarm.minewhat.com
$MY_IPS mwzoolocal.linodefarm.minewhat.com
$MY_IPS mongodb1.linodefarm.productclues.com
$MY_IPS mongodb2.linodefarm.productclues.com
$MY_IPS mongodbdomain1.linodefarm.minewhat.com
$MY_IPS mongodbdomain2.linodefarm.minewhat.com
$MY_IPS mongodb1.linodefarm.minewhat.com
$MY_IPS mongodb2.linodefarm.minewhat.com
$MY_IPS shopify.productclues.com
$MY_IPS bigcommerce.productclues.com
$ES_IP elastic.azure.minewhat.com
" >> /etc/hosts

sudo -u ubuntu mongo --eval 'rs.initiate({
	"_id" : "mw",
	"members" : [
		{
			"_id" : 0,
			"host" : "mongo1.productclues.com:27017",
      priority: 10
		}
	]
})
'

cd /home/ubuntu/minewhat
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/Server.git
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/server2.git
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/app2.git
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/workers.git
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/addons.git

cd /home/ubuntu/minewhat/Server/Config
sudo -u ubuntu git checkout MW_V2.3
cd /home/ubuntu/
#Copy GEO
sudo -u ubuntu mkdir GeoIP
cp /home/ubuntu/minewhat/Server/Config/Geo* GeoIP
sudo -u ubuntu gunzip -f GeoIP/*

cd /home/ubuntu/minewhat/app2/productclues
cp /home/ubuntu/minewhat/app2/choice/node_modules_ubuntu.tgz .
sudo -u ubuntu tar -zxvf node_modules_ubuntu.tgz
sudo -u ubuntu sh prepare.sh
sudo -u ubuntu gulp dist


sudo apt-get install nginx --yes
cd /home/ubuntu/minewhat/server2/config/nginx
cp productclues* /etc/nginx
cp dhparams.pem /etc/nginx/conf.d
cp pc_conf_d/* /etc/nginx/conf.d
sudo service nginx restart

cd /home/ubuntu/minewhat/addons/productClues_Addons
sudo -u ubuntu sh prepare.sh
sudo -u ubuntu sh startshopify.sh
sudo -u ubuntu sh startbigcommerce.sh

cd /home/ubuntu/minewhat/server2/productclues
sudo -u ubuntu tar zxvf node_modules_ubuntu.tar.gz
sudo -u ubuntu /home/ubuntu/Servers/redis/src/redis-server /home/ubuntu/minewhat/Server/Config/redis/redissession.conf
sudo -u ubuntu /home/ubuntu/Servers/redis/src/redis-server /home/ubuntu/minewhat/Server/Config/redis/redisstatscache1.conf
sudo -u ubuntu /home/ubuntu/Servers/redis/src/redis-server /home/ubuntu/minewhat/Server/Config/redis/redislow321.conf
sudo -u ubuntu sh scripts/startworker.sh
sudo -u ubuntu sh scripts/startproductclues.sh
sudo -u ubuntu sh scripts/startnotif.sh
cd static
sudo -u ubuntu ln -s  /home/ubuntu/minewhat/app2/productclues/dist newapp
sudo -u ubuntu ln -s  /home/ubuntu/minewhat/app2/productclues/dist settings

cd /home/ubuntu/minewhat/workers/configs
sudo cp supervisord.conf /etc/
sudo cp supervisord /etc/init.d/supervisord
sudo chmod +x /etc/init.d/supervisord
sudo service supervisord start
cd /home/ubuntu/minewhat/workers/shell_scripts
sudo -u ubuntu sh setup.sh
sudo service supervisord stop

echo "

[program:pc_generalWorker]
command=/usr/bin/python /home/ubuntu/minewhat/workers_2/workers/generalWorker.py
user=ubuntu
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
logfile = /raid1/supervisorlogs/program:pc_generalWorker.log
logfile_maxbytes = 50MB
logfile_backups=1
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1

[program:pc_feedWorker]
command=/usr/bin/python /home/ubuntu/minewhat/workers_2/workers/feedWorker.py
user=ubuntu
autostart=false
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
autorestart=true
startsecs=10
stopsignal=KILL
logfile = /raid1/supervisorlogs/program:pc_feedWorker.log
logfile_maxbytes = 50MB
logfile_backups=1

[program:pc_GA_DumpWorker]
command=/usr/bin/python /home/ubuntu/minewhat/workers_2/workers/productclues/pc_GA_DumpWorker.py
user=ubuntu
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
logfile = /raid1/supervisorlogs/program:pc_GA_DumpWorker.log
logfile_maxbytes = 50MB
logfile_backups=1

[program:pc_crawlerWorker]
command=/usr/bin/python /home/ubuntu/minewhat/workers_2/workers/crawlerWorker.py
user=ubuntu
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
logfile = /raid1/supervisorlogs/program:wo_crawlerWorker_2.log
logfile_maxbytes = 50MB
logfile_backups=1

[program:pc_esSyncWorker_revamp]
command=/usr/bin/python /home/ubuntu/minewhat/workers/workers/esSyncWorker_revamp.py
user=ubuntu
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
logfile = /raid1/supervisorlogs/program:pc_esSyncWorker_revamp.log
logfile_maxbytes = 50MB
logfile_backups=1
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1

[program:pc_productWorker]
command=/usr/bin/python /home/ubuntu/minewhat/workers/workers/productWorker.py
user=ubuntu
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
logfile = /raid1/supervisorlogs/program:pc_productWorker.log
logfile_maxbytes = 50MB
logfile_backups=1

" >> /etc/supervisord.conf
sudo -u ubuntu service supervisord start
sudo -u ubuntu supervisorctl start all


# setup startup and shutdown scripts
sudo -u ubuntu cp -r /home/ubuntu/minewhat/server2/scripts/machinescripts/productclues/mongo/* /home/ubuntu/

cat << EOF > /etc/init/choice.conf
# choice
description "start choice specific services"

start on starting
script
    /home/ubuntu/startupscripts/basic.sh
end script
EOF