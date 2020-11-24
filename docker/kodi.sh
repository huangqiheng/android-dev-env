#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	check_docker

	select_subpath $CACHE_DIR/Kodi "$1"
	DataDir="$CACHE_DIR/Kodi/$FUNC_RESULT"
	ContainerName=$(rm_space "$FUNC_RESULT")

	chownUser $CACHE_DIR

	docker run --rm -it --name="$ContainerName" \
		--privileged \
		-v $DataDir:/config/.kodi \
		-e PGID=$(id -u $RUN_USER) -e PUID=$(id -g $RUN_USER) \
		-e TZ=timezone \
		-p 8080:8080 \
		-p 9090:9090 \
		-p 9777:9777/udp \
		milaq/kodi-headless:leia

	self_cmdline
}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
