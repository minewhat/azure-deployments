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
AE_IP="$4"
CASSA_IP="$5"
CRUNCHER_IP="$6"
WORKER_IP="$7"
JOBS_IP="$8"
echo "
deb http://nginx.org/packages/mainline/ubuntu/ trusty nginx
deb-src http://nginx.org/packages/mainline/ubuntu/ trusty nginx
" > /etc/apt/sources.list.d/nginx.list
wget -q -O- http://nginx.org/keys/nginx_signing.key | sudo apt-key add -
curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
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
# give read/write permission to all users
sudo mkdir -p /raid1/mongo/
sudo mkdir -p /raid1/mongo/log
sudo mkdir -p /raid1/mongo/data
sudo mkdir -p /home/ubuntu/minewhat
# give read/write permission to all users
sudo chown -R ubuntu:ubuntu /raid1
sudo chown -R ubuntu:ubuntu /home/ubuntu/minewhat

# most common need
sudo apt-get -y install unzip
sudo apt-get -y install make
sudo apt-get -y install build-essential maven2 libkrb5-dev
sudo apt-get -y install uuid-dev libtool
sudo apt-get -y install pkg-config autoconf automake
sudo apt-get -y install libc6-dev-i386
sudo apt-get -y install libev4 libev-dev
sudo apt-get -y install python-setuptools python-pip
sudo apt-get -y install lynx
sudo apt-get -y install software-properties-common
sudo apt-get install -y python-software-properties python g++ make
sudo apt-get install -y nodejs
sudo apt-get install -y xfsprogs
sudo npm install -g forever
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

# Disable THP
sudo echo never > /sys/kernel/mm/transparent_hugepage/enabled
sudo echo never > /sys/kernel/mm/transparent_hugepage/defrag
sudo grep -q -F 'transparent_hugepage=never' /etc/default/grub || echo 'transparent_hugepage=never' >> /etc/default/grub

sudo apt-get install -y mongodb-org=3.0.3 mongodb-org-server=3.0.3 mongodb-org-shell=3.0.3 mongodb-org-mongos=3.0.3 mongodb-org-tools=3.0.3
sudo service mongod stop
echo "
dbpath=/raid1/mongo/data
logpath=/raid1/mongo/log/mongodb.log
logappend=true
fork=true
replSet = mw
" > /etc/mongod.conf
sudo -u ubuntu /usr/bin/mongod --config /etc/mongod.conf
sleep 2
MY_IPS=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`

echo "
$MY_IPS  mongo1.choice.ai
$MY_IPS  mongo2.choice.ai
$MY_IPS mongo1.choice.ai
$MY_IPS mongo2.choice.ai
$MY_IPS mongodbdomain1.linodefarm.minewhat.com
$MY_IPS mongodbdomain2.linodefarm.minewhat.com
$MY_IPS mongodb1.linodefarm.minewhat.com
$MY_IPS mongodb2.linodefarm.minewhat.com
$CASSA_IP cassa1.choice.ai
$CASSA_IP cassa2.choice.ai
$CASSA_IP cassaseed5.linodefarm.minewhat.com
$CASSA_IP cassaseed6.linodefarm.minewhat.com
$CASSA_IP cassaseedrealtime.linodefarm.minewhat.com
$AE_IP aerospike1.choice.ai
$AE_IP aerospike2.choice.ai
$AE_IP aerospike3.choice.ai
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
$WORKER_IP google.choice.ai
$WORKER_IP search.choice.ai
$WORKER_IP crawler.choice.ai
$JOBS_IP shopify.choice.ai
$JOBS_IP aweber.choice.ai
$JOBS_IP mailchimp.choice.ai
$JOBS_IP sendgrid.choice.ai
$JOBS_IP bigcommerce.choice.ai
$JOBS_IP highwire.choice.ai
$JOBS_IP americommerce.choice.ai
" >> /etc/hosts

sudo -u ubuntu mongo --eval "rs.initiate({
	'_id' : 'mw',
	'members' : [
		{
			'_id' : 0,
			'host' : 'mongo1.choice.ai:27017',
      priority: 10
		}
	]
})
"
# change owership of .npm n .forever folders to ubuntu
sudo chown -R ubuntu:ubuntu /home/ubuntu/.npm/
forever list
forever columns add dir
sudo chown -R ubuntu:ubuntu /home/ubuntu/.forever/

cd /home/ubuntu/minewhat
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/Server.git
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/server2.git
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/app2.git
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/cdnassets.git

cd /home/ubuntu/minewhat/Server/Config
sudo -u ubuntu git checkout MW_V2.3
#System Tuning Settings
cat linux/limits.conf | sudo tee -a /etc/security/limits.conf
cat linux/sysctl.conf | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
cd /home/ubuntu/
#Copy GEO
sudo -u ubuntu mkdir GeoIP
cp /home/ubuntu/minewhat/Server/Config/Geo* GeoIP
sudo -u ubuntu gunzip -f GeoIP/*

cd /home/ubuntu/minewhat/app2/choiceai
sudo -u ubuntu sh prepare.sh
sudo -u ubuntu gulp dist

cd /home/ubuntu/minewhat/cdnassets/mwstoreSample
sudo -u ubuntu tar zxvf node_modules_ubuntu.tgz
sudo chown -R ubuntu:ubuntu /home/ubuntu/
sudo -u ubuntu gulp build

cd /home/ubuntu/minewhat/server2/choiceai
wget http://assets.choice.ai.s3.amazonaws.com/node_modules/node_modules_ubuntu_server.tar.gz
sudo -u ubuntu sh prepare.sh
sudo -u ubuntu /home/ubuntu/Servers/redis/src/redis-server /home/ubuntu/minewhat/Server/Config/redis/redissession.conf
sudo -u ubuntu /home/ubuntu/Servers/redis/src/redis-server /home/ubuntu/minewhat/Server/Config/redis/redisstatscache1.conf
sudo -u ubuntu sh scripts/startwidget.sh
sudo -u ubuntu sh scripts/startwidgetData.sh
sudo -u ubuntu sh scripts/startnotif.sh
cd static
sudo -u ubuntu ln -s  /home/ubuntu/minewhat/app2/choiceai/dist newapp
sudo -u ubuntu ln -s  /home/ubuntu/minewhat/app2/choiceai/dist settings

sudo apt-get install nginx --yes
cd /home/ubuntu/minewhat/server2/config/nginx
sudo cp choice* /etc/nginx
sudo cp nginx.conf /etc/nginx
sudo cp dhparams.pem /etc/nginx/conf.d
sudo cp cai_conf_d/* /etc/nginx/conf.d
sudo service nginx restart

# setup startup and shutdown scripts
sudo -u ubuntu cp -r /home/ubuntu/minewhat/server2/scripts/machinescripts/cai/mongo/* /home/ubuntu/
sudo cp /home/ubuntu/minewhat/server2/scripts/mwinit /etc/init.d/mwinit
sudo chmod +x /etc/init.d/mwinit
sudo chmod +x /home/ubuntu/startupscripts/basic.sh
sudo chmod +x /home/ubuntu/shutdownscripts/basic.sh
sudo update-rc.d mwinit defaults 10
