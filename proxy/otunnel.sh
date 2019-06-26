#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

LISTEN_PORT=21000

main () 
{
	otunnel_from_download_exit
}

otunnel_from_docker_exit()
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

	print_next_exit
}

otunnel_from_download_exit()
{
	local OPTIONS='
	 1) otunnel_darwin_386
	 2) otunnel_darwin_amd64
	 3) otunnel_freebsd_386
	 4) otunnel_freebsd_amd64
	 5) otunnel_freebsd_arm
	 6) otunnel_linux_386
	 7) otunnel_linux_amd64
	 8) otunnel_linux_arm
	 9) otunnel_linux_mips
	10) otunnel_linux_mips64
	11) otunnel_linux_mips64le
	12) otunnel_linux_mipsle
	13) otunnel_linux_s390x
	14) otunnel_netbsd_386
	15) otunnel_netbsd_amd64
	16) otunnel_netbsd_arm
	17) otunnel_openbsd_386
	18) otunnel_openbsd_amd64
	19) otunnel_windows_386.exe
	20) otunnel_windows_amd64.exe
'
	IFS=''
	echo $OPTIONS

	read -p 'Select the platform to download: ' user_select

	if ! is_range "$user_select" 1 20; then
		log_r 'Integer in range only'
		exit 2
	fi
	selected=$(echo "$OPTIONS" | sed -n "$(expr ${user_select} + 1)p" | awk '{print $2}')

	cd $CACHE_DIR
	if [ ! -d otunnel ]; then
		git clone https://github.com/ooclab/otunnel
	fi

	cd otunnel
	url="https://dl.ooclab.com/otunnel/1.3.1/$selected"
	wget "$url" -O otunnel
	chmod a+x otunnel
	cp ./otunnel /usr/local/bin/

	if ! otunnel -h >/dev/null 2>&1; then
		log_r 'The download is not compatible with this machine'
		rm -f /usr/local/bin/otunnel
		exit 2
	fi

	cd config
	cp otunnel-listen.service /lib/systemd/system/
	cp otunnel-connect.service /lib/systemd/system/

	print_next_exit
}

print_next_exit()
{
	log_y 'The otunnel is ready'
	log_y 'Next:'
	log_y '   sh ./otunnel.sh server'
	log_y '   sh ./otunnel.sh client'
	exit 0
}

otunnel_from_source_exit()
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

	cp $GOPATH/bin/otunnel /usr/local/bin/
	cd "$GOPATH/src/github.com/ooclab/otunnel/config"
	cp otunnel-listen.service /lib/systemd/system/
	cp otunnel-connect.service /lib/systemd/system/

	print_next_exit
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
	[ "$1" = 'dock' ] && otunnel_from_docker_exit
	[ "$1" = 'source' ] && otunnel_from_source_exit
	[ "$1" = 'download' ] && otunnel_from_download_exit
}

show_help_exit()
{
	cat << EOL
	./otunnel.sh help
	./otunnel.sh		// default is download
	./otunnel.sh download 	// get otunnel from download
	./otunnel.sh docker 	// build otunnel from docker
	./otunnel.sh source   	// build otunnel from source
	./otunnel.sh server	// run as service
	./otunnel.sh client	// run as service
EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
