#!/usr/bin/env bash
help()
{
    echo "This script installs cassa on Ubuntu"
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
# JDK
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

# most common need
sudo apt-get -y install unzip
sudo apt-get -y install make
sudo apt-get -y install build-essential maven2
sudo apt-get -y install uuid-dev libtool
sudo apt-get -y install git pkg-config autoconf automake
sudo apt-get -y install python-setuptools python-pip
sudo apt-get -y install lynx
sudo pip install supervisor
sudo apt-get -y install software-properties-common
sudo apt-get install -y python-software-properties python g++ make

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

#goto local Directory
cd /usr/local


#Cassandra
#Installing Cassandra
echo "deb http://pavan_minewhat.com:nrbvidzc7NzIfWL@debian.datastax.com/enterprise stable main" | tee -a /etc/apt/sources.list.d/datastax.sources.list
curl -L https://debian.datastax.com/debian/repo_key | apt-key add -

apt-get update --yes

apt-get install --yes dse-full=4.5.1-1 dse=4.5.1-1 dse-hive=4.5.1-1 dse-pig=4.5.1-1 dse-demos=4.5.1-1 dse-libsolr=4.5.1-1 dse-libtomcat=4.5.1-1 dse-libsqoop=4.5.1-1 dse-liblog4j=4.5.1-1 dse-libmahout=4.5.1-1 dse-libhadoop-native=4.5.1-1 dse-libcassandra=4.5.1-1 dse-libhive=4.5.1-1 dse-libpig=4.5.1-1 dse-libhadoop=4.5.1-1 dse-libspark=4.5.1-1  ## Installs DataStax Enterprise and DataStax Agent.
apt-get install dse-full=4.5.1-1 opscenter --yes ## Installs DataStax Enterprise, DataStax Agent, and OpsCenter.

#configuring cassandra
#most of the configurations are part of the package script (enterprise)
swapoff --all
sed -i 's/Test Cluster/CAICluster/' /etc/dse/cassandra/cassandra.yaml

#device queue settings
echo noop > /sys/block/sdb/queue/scheduler
echo 0 > /sys/block/sdb/queue/read_ahead_kb
echo 0 > /sys/block/sdb/queue/rotational

#Setting the SSH keep alive values
#echo "#server side keep alive settings" >>  /etc/ssh/sshd_config
#echo "ServerAliveInterval 300" >> /etc/ssh/sshd_config
#echo "ServerAliveCountMax 3" >>  /etc/ssh/sshd_config

#start Cassa
sudo service dse start

# setup startup and shutdown scripts
sudo -u ubuntu cp -r /home/ubuntu/minewhat/server2/scripts/machinescripts/cai/cassa/* /home/ubuntu/
sudo cp /home/ubuntu/minewhat/server2/scripts/mwinit /etc/init.d/mwinit
sudo chmod +x /etc/init.d/mwinit
sudo chmod +x /home/ubuntu/startupscripts/basic.sh
sudo chmod +x /home/ubuntu/shutdownscripts/basic.sh
sudo update-rc.d mwinit defaults 10

