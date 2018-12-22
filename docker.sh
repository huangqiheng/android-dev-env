#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

ImageName='rastasheep/ubuntu-sshd'

main () 
{
	empty_exit "$1" 'container name'
	local containerName="$1"

	install_docker

	if ! docker images --all | grep -q "$ImageName"; then
		docker pull "$ImageName"
	fi

	local containerHome="$RUN_DIR/dockerHome/$containerName"; mkdir -p "$containerHome"
	local imageId=$(docker images -q "$ImageName")

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
