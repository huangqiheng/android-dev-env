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
		log_g "container is created ($ContainerName)"
		docker run \
			--interactive --tty \
			--net=host \
			--privileged \
			--hostname "$ContainerName" \
			--volume "$ContainerHome:/home" \
			--volume "$THIS_DIR:/root/install-scripts" \
			--name "$ContainerName" \
			"$ImageName" /bin/bash
		return 0
	fi

	if ! is_container_running; then
		log_g "container is opened ($ContainerName: $containerId)"
		docker start -ai "$containerId"
		return 0
	fi

	log_g "container is ready ($ContainerName: $containerId)"
	docker exec -it "$containerId" /bin/bash
}

is_container_running()
{
	[ $(docker inspect -f '{{.State.Running}}' $ContainerName) = 'true' ]
}

get_pid()
{
	docker inspect -f '{{.State.Pid}}' "$(get_containerId)"
}

get_containerId()
{
	docker ps -aq --filter=ancestor=$ImageName --filter=volume=$ContainerHome
}

stop_container_exit()
{
	docker stop "$(get_containerId)"
	exit 0
}

remove_container_exit()
{
	local containerId="$(get_containerId)"
	docker stop "$containerId" >/dev/null
	docker rm "$containerId"  >/dev/null
	exit 0
}

getshell_exit()
{
	docker exec -it "$(get_containerId)" /bin/bash
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
	shift
	case "$1" in
	'bash'|'shell'|'sh') 
		getshell_exit
		;;
	'stop'|'close'|'shutdown')
		stop_container_exit
		;;
	'rm'|'remove'|'clean')
		remove_container_exit
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
