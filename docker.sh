#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

empty_exit "$1" 'container name'

ContainerName="$1"
ImageName='ubuntu'
ContainerHome="$RUN_DIR/dockerHome/$ContainerName"; 

main () 
{
	check_image $ImageName

	local containerId=$(get_containerId)

	if [ "X$containerId" = 'X' ]; then
		mkdir -p "$ContainerHome"
		shortId=$(docker run --net host --detach \
			--hostname "$ContainerName" \
			-v "$ContainerHome:/home" \
			--name "$ContainerName" "$ImageName")
		log_g "container is first running ($ContainerName: $shortId)"
	else
		shortId=$(docker start "$containerId")
		log_g "container is ready ($ContainerName: $shortId)"
	fi
}

get_containerId()
{
	local containerId=$(docker ps -aq --filter=ancestor=$ImageName --filter=volume=$ContainerHome)
	echo $containerId
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
