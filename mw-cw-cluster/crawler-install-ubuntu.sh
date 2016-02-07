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
GIT_AUTH="username:password"
MONGO_IP="127.0.0.1"
#Loop through options passed
while getopts :git:mongo:h optname; do
    log "Option $optname set with value ${OPTARG}"
  case $optname in
    git) #set cluster name
      GIT_AUTH=${OPTARG}
      ;;
    mongo) #static discovery endpoints
      MONGO_IP=${OPTARG}
      ;;
    h) #show help
      help
      exit 2
      ;;
    \?) #unrecognized option - show help
      echo -e \\n"Option -${BOLD}$OPTARG${NORM} not allowed."
      help
      exit 2
      ;;
  esac
done

sudo apt-get --yes --force-yes  install git
# create mount folder
sudo mkdir -p /raid1
# give read/write permission to all users
sudo chmod -R a+w /raid1
sudo chown -R ubuntu:ubuntu /raid1
sudo apt-get -y install unzip
sudo apt-get -y install make
sudo apt-get -y install build-essential maven2
sudo apt-get -y install uuid-dev libtool
sudo apt-get -y install git pkg-config autoconf automake
sudo apt-get -y install python-setuptools python-pip
sudo apt-get -y install lynx
sudo apt-get -y install software-properties-common
sudo apt-get --yes install python-software-properties python g++ make
sudo apt-get --yes install python-lxml
sudo pip install supervisor
sudo pip install pymongo==2.6.3
sudo pip install elasticsearch
sudo pip install redis
sudo pip install cassandra-driver
sudo pip install mandrill
sudo pip install jinja2
sudo pip install arrow
sudo pip install boto
sudo pip install blist
sudo pip install simplejson
sudo pip install moment
sudo pip install kafka-python==0.9.4
sudo pip install git+git://github.com/sumitkumar1209/superlanceadds
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
sudo pip install aerospike
sudo pip install beautifulsoup4
sudo pip install -U nltk
sudo apt-get --yes install python-numpy python-scipy
sudo pip install spacy
sudo python -m spacy.en.download --force all
sudo pip install -U scikit-learn
sudo pip install python-amazon-simple-product-api==2.0.1
sudo pip install pyquery==1.2.10

sudo mkdir -p /home/ubuntu/minewhat
sudo chmod -R a+w /home/ubuntu/minewhat
sudo chown -R ubuntu:ubuntu /home/ubuntu/minewhat
cd /home/ubuntu/minewhat
sudo -u ubuntu git clone https://$GIT_AUTH@github.com/minewhat/workers.git
cd workers/configs
cp supervisord.conf /etc/

echo "
[program:wo_crawlerWorker]
command=/usr/bin/python /home/ubuntu/minewhat/workers/workers/crawlerWorker.py
user=ubuntu
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups = 1
autostart=false
autorestart=true
startsecs=10
stopsignal=KILL
logfile = /raid1/supervisorlogs/program:crawlerWorker.log
logfile_maxbytes = 50MB
logfile_backups=1
" >> /etc/supervisord.conf

echo "
$MONGO_IP  mongodbdomain1.linodefarm.minewhat.com
$MONGO_IP  mongodbdomain2.linodefarm.minewhat.com
$MONGO_IP  mongodb1.linodefarm.minewhat.com
$MONGO_IP  mongodb1.linodefarm.minewhat.com
" >> /etc/hosts

sudo service supervisord restart
supervisorctl update
supervisorctl start