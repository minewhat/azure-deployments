#!/usr/bin/env bash
help()
{
    echo "This script installs Crawlers on Ubuntu"
    echo "Parameters:"
    echo "-git git credentials username:password"
    echo "-mongo static mongo IP"
    echo "-h view this help content"
}

#Script Parameters
GIT_AUTH="$1"
MONGO_IP="$2"
sudo apt-get update --yes
# installing packages
curl -sL https://deb.nodesource.com/setup_0.12 | sudo bash -
sudo apt-get -y install nodejs
sudo apt-get -y install make
sudo apt-get -y install git pkg-config autoconf automake
sudo apt-get -y install build-essential maven2 python-dev
sudo apt-get -y install libc6-dev-i386
sudo apt-get -y install libev4 libev-dev
sudo apt-get -y install uuid-dev libtool
sudo apt-get --yes install python-software-properties python g++
sudo apt-get -y install python-setuptools python-pip
sudo apt-get -y install lynx
sudo apt-get -y install software-properties-common
sudo apt-get --yes install python-lxml
sudo pip install supervisor
sudo pip install pymongo==2.6.3
sudo pip install elasticsearch
sudo pip install redis
sudo pip install mandrill
sudo pip install jinja2
sudo pip install arrow
sudo pip install boto
sudo pip install simplejson
sudo pip install moment
sudo pip install kafka-python==0.9.4
sudo pip install git+git://github.com/minewhat/superlanceadds
sudo pip install python-magic
sudo pip install rarfile
sudo pip install unrar
sudo pip install tarfile
sudo pip install zipfile
sudo pip install xmltodict
sudo pip install paramiko
sudo pip install scpclient
sudo pip install oauth2client
sudo pip install google-api-python-client
sudo pip install xlrd
sudo pip install fastavro
sudo pip install redis
sudo pip install hash_ring
sudo pip install unidecode
sudo pip install pyquery==1.2.10
sudo pip install blist
# create mount folder
sudo mkdir -p /raid1
sudo mkdir -p /raid1/supervisorlogs
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
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/workers.git
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/addons.git
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/app2.git
cd workers/configs
sudo cp supervisord.conf /etc/
sudo cp supervisord /etc/init.d/supervisord
sudo chmod +x /etc/init.d/supervisord
sudo service supervisord start
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
$MY_IPS  mongodbdomain1.linodefarm.minewhat.com
$MY_IPS  mongodbdomain2.linodefarm.minewhat.com
$MY_IPS  mongodb1.linodefarm.minewhat.com
$MY_IPS  mongodb1.linodefarm.minewhat.com
40.114.211.179 elastic.azure.minewhat.com
" >> /etc/hosts

mongo --eval 'rs.initiate({
	"_id" : "mw",
	"members" : [
		{
			"_id" : 0,
			"host" : "mongodb1.linodefarm.minewhat.com:27017",
      priority: 10
		}
	]
})
'