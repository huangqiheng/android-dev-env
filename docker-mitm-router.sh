#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh


ImageName='brannondorsey/mitm-router'

main () 
{
	if ! cmd_exists docker; then
		log_y 'Please install docker'
		exit 1
	fi

	cd $RUN_DIR

	if [ ! -d mitm-router ]; then
		git clone https://github.com/${ImageName}
	fi
	cd mitm-router

	if [ $(docker images | grep -c "$ImageName") -eq 0 ]; then
		docker build . -t "$ImageName"
	fi

	local containerId=$(docker ps -aq --filter=ancestor=$ImageName)

	if [ "X$containerId" = 'X' ]; then
		docker run -it --net host --privileged \
		  -e MAC="unchanged" \
		  -e AP_IFACE="wlan0" \
		  -e INTERNET_IFACE="eth0" \
		  -e SSID="CYLON-BASESTAR" \
		  -e PASSWORD="SoSayWeAll" \
		  -v "$(pwd)/data:/root/data" \
		  "$ImageName"
	else
		docker start -i "$containerId"
	fi
}

start_container_exit()
{
	local containerId=$(docker ps -aq --filter=ancestor=$ImageName)
	docker start -i "$containerId"
	exit 0
}

stop_container_exit()
{
	local containerId=$(docker ps -aq --filter=ancestor=$ImageName)
	docker stop $containerId
	exit 0
}

getshell_exit()
{
	local containerId=$(docker ps -aq --filter=ancestor=$ImageName)
	docker exec -it "$containerId" /bin/bash
	exit 0
}

hostapd_issue_exit()
{
	local mac=$(iface_to_mac wlan0)
	set_ini '/etc/NetworkManager/NetworkManager.conf'
	set_ini 'keyfile' 'unmanaged-devices' "mac:$mac"
	set_ini 'device' 'wifi.scan-rand-mac-address' 'no'

	systemctl restart NetworkManager

	airmon-ng check kill

	exit 0
}

maintain()
{
	case "$1" in
	'bash'|'shell'|'sh') 
		getshell_exit
		;;
	'start'|'open'|'run')
		start_container_exit
		;;
	'stop'|'close'|'shutdown')
		stop_container_exit
		;;
	'hostapd')
		hostapd_issue_exit
		;;
	'help')
		show_help_exit
		;;
	esac
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
