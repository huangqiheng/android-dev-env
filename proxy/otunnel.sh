#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

LISTEN_PORT=21000

main () 
{
	if [ "X$1" = 'Xsource' ]; then
		otunnel_from_source
	else
		otunnel_from_docker
	fi
}

otunnel_from_docker()
{
	if cmd_exists 'otunnel'; then
		log_y 'otunnel is build'
		return
	fi

	cd $CACHE_DIR
	git clone https://github.com/ooclab/otunnel
	cd otunnel

	check_docker
	./build-by-docker.sh
	cp ./otunnel /usr/local/bin/

	cd config
	cp otunnel-listen.service /lib/systemd/system/
	cp otunnel-connect.service /lib/systemd/system/
}

otunnel_from_source()
{
	if cmd_exists 'otunnel'; then
		log_y 'otunnel is ready'
		return
	fi

	check_apt git golang-go

	export GOPATH=${GOPATH:-$HOME/go}
	go get -v github.com/ooclab/otunnel
	cd $GOPATH/src/github.com/ooclab/otunnel
	make
	ln -sf $GOPATH/bin/otunnel /usr/local/bin/

	cd "$GOPATH/src/github.com/ooclab/otunnel/config"
	cp otunnel-listen.service /lib/systemd/system/
	cp otunnel-connect.service /lib/systemd/system/
}

listen_service_exit()
{
	install_otunnel
	THE_SECRET=$(echo "$(date)OTUNNEL-SECRET" | md5sum | awk '{print $1}')
	set_conf /lib/systemd/system/otunnel-listen.service
	set_conf ExecStart "/usr/local/bin/otunnel listen :${LISTEN_PORT} -d -s ${THE_SECRET}"

	systemctl daemon-reload
	systemctl enable  otunnel-listen
	systemctl restart otunnel-listen
	exit 0
}

connect_service_exit()
{
	install_otunnel

	set_conf /lib/systemd/system/otunnel-connect.service
	set_conf ExecStart "/usr/local/bin/otunnel connect ${SERVER_IP}:${LISTEN_PORT} -d -s ${THE_SECRET} -t \"r:127.0.0.1:22::50022\""

	systemctl daemon-reload
	systemctl enable  otunnel-connect
	systemctl restart otunnel-connect
	exit 0
}

maintain()
{
	nocmd_udpate otunnel
	[ "$1" = 'help' ] && show_help_exit
	[ "$1" = 'server' ] && listen_service_exit 
	[ "$1" = 'client' ] && connect_service_exit
}

show_help_exit()
{
	cat << EOL
	./otunnel.sh help
	./otunnel.sh 		//build otunnel from docker
	./otunnel.sh source   	//build otunnel from source
	./otunnel.sh server
	./otunnel.sh client
EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
