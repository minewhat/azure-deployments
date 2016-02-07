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
MONGO_IP="127.0.0.1"
sudo apt-get update --yes
# installing GIT
sudo apt-get --yes --force-yes install git

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