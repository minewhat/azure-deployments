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
sudo add-apt-repository ppa:nginx/stable
sudo apt-get update --yes
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
sudo npm install -g forever
sudo pip install supervisor
# create mount folder
sudo mkdir -p /raid1
# give read/write permission to all users
sudo mkdir -p /raid1/mongo/
sudo mkdir -p /raid1/mongo/log
sudo mkdir -p /raid1/mongo/data
sudo mkdir -p /home/ubuntu/minewhat
sudo chmod -R a+w /raid1
sudo chown -R ubuntu:ubuntu /raid1
sudo chown -R ubuntu:ubuntu /home/ubuntu/minewhat
cd /home/ubuntu/minewhat
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/Server.git
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/server2.git
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/app2.git
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/cdnassets.git

cd /home/ubuntu/minewhat/cdnassets/mwstoreSample
npm i
gulp dist

sudo apt-get install nginx --yes
cd /home/ubuntu/minewhat/server2/config/nginx
cp choice* /etc/nginx
cp dhparams.pem /etc/nginx/conf.d
cp choice_conf_d/* /etc/nginx/conf.d
sudo service nginx restart

cd /home/ubuntu/minewhat/app2/choiceai
tar -zxvf node_modules.tgz
./prepare.sh
gulp dist

# mongo install
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list
sudo apt-get update --yes
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
sudo service mongod start
sleep 20
MY_IPS=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`

echo "
$MY_IPS  mongo1.choice.ai
$MY_IPS  mongo2.choice.ai
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

mongo --eval 'rs.initiate({
	"_id" : "mw",
	"members" : [
		{
			"_id" : 0,
			"host" : "mongo1.choice.ai:27017",
      priority: 10
		}
	]
})
'