#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

MONGOD_ADMIN_USER=admin
MONGOD_ADMIN_PASS=admin
MONGOD_USER=nodebb
MONGOD_PASS=nodebbpw
NODEBB_PATH=/var/www/nodebb
BACKUP_DB=$UHOME/nodebb.mongodb.archive
BACKUP_UPLOADS=$UHOME/nodebb.uploads.tar.gz

main () 
{
	setup_nodejs
	setup_mongodb
	setup_nodebb
	setup_plugins

	run
}

run()
{
	$NODEBB_PATH/nodebb build
	chown -R nodebb:nodebb $NODEBB_PATH
	systemctl start nodebb
}

setup_plugins()
{
	check_apt openjdk-8-jre solr-tomcat

	setup_plugin nodebb-plugin-designer
	setup_plugin nodebb-plugin-solr
	setup_plugin nodebb-plugin-blog-comments
	setup_plugin nodebb-plugin-custom-pages
	setup_plugin nodebb-plugin-ns-awards
	setup_plugin nodebb-plugin-cash
	setup_plugin nodebb-plugin-mentions
	setup_plugin nodebb-plugin-beep
	setup_plugin nodebb-plugin-topic-badges
	setup_plugin nodebb-plugin-poll
}

setup_plugin()
{
	npm install "$1"
	$NODEBB_PATH/nodebb activate "$1"
}

setup_nodebb()
{
	check_apt git build-essential

	mkdir -p $NODEBB_PATH
	git clone -b v1.8.x https://github.com/NodeBB/NodeBB.git $NODEBB_PATH
	cd $NODEBB_PATH

	adduser --system --group nodebb

	./nodebb setup

	chown -R nodebb:nodebb $NODEBB_PATH

	cat > /lib/systemd/system/nodebb.service <<EOL
[Unit]
Description=NodeBB
Documentation=https://docs.nodebb.org
After=system.slice multi-user.target mongod.service

[Service]
Type=forking
User=nodebb

StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=nodebb

WorkingDirectory=${NODEBB_PATH}
ExecStart=/usr/bin/env node loader.js
Restart=always

[Install]
WantedBy=multi-user.target
EOL
	systemctl enable nodebb
}

setup_mongodb()
{
	if command_exists /usr/bin/mongod; then
		log "mongod has been installed"
		return
	fi

	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
	echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list

	check_update
	check_apt mongodb-org

	systemctl enable mongod
	service mongod stop

	rm -rf /var/lib/mongodb/*
	cat > /etc/mongod.conf <<'EOF'
storage:
  dbPath: /var/lib/mongodb
  directoryPerDB: true
  journal:
    enabled: true
  engine: "wiredTiger"

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 127.0.0.1
  maxIncomingConnections: 100

security:
  authorization: enabled
EOF

	systemctl start mongod
	sleep 5

	echo "Adding admin user"
	mongo admin <<'EOF'
use admin
var adminuser = {
  "user" : "${MONGOD_ADMIN_USER}",
  "pwd" : "${MONGOD_ADMIN_PASS}",
  "roles" : [{
  	"role": "readWriteAnyDatabase", 
	"db": "admin"
    },{
	"role" : "userAdminAnyDatabase",
	"db" : "admin"
  }]
}
db.createUser(adminuser);

use nodebb 
var user = {
  "user" : "${MONGOD_USER}",
  "pwd" : "${MONGOD_PASS}",
  "roles" : [{
  	"role": "readWrite", 
	"db": "nodebb"
    },{
	"role" : "clusterMonitor",
	"db" : "admin"
  }]
}
db.createUser(user);
exit
EOF

	systemctl restart mongod 
}

setup_nodejs()
{
	if command_exists /usr/bin/node; then
		log "node has been installed"
		return
	fi

	curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
	check_apt nodejs
}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit
	[ "$1" = 'upgrade' ] && nodebb_upgrade_exit
}

nodebb_upgrade_exit()
{
	mongodump -u $MONGOD_ADMIN_USER -p $MONGOD_ADMIN_PASS --gzip --archive=$BACKUP_DB

	systemctl stop mongod nodebb 

	cd $NODEBB_PATH/public
	tar -czf $BACKUP_UPLOADS ./uploads

	cd $NODEBB_PATH

	now_release=$(git rev-parse --abbrev-ref HEAD)
	latest_release=$(get_latest_release 'NodeBB/NodeBB')

	echo "from version: ${now_release} to ${latest_release}"

	git fetch
	git checkout $latest_release
	git merge origin/$latest_release

	./nodebb upgrade

	chown -R nodebb:nodebb $NODEBB_PATH
	systemctl start mongod nodebb 

	exit 0
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}


maintain "$@"; main "$@"; exit $?
