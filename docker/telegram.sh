#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_docker

	cd $CACHE_DIR
	mkdir -p .TelegramDesktop
	chownUser $CACHE_DIR

	docker run --rm -it --name telegram \
		--hostname=$(hostname) \
		--device /dev/snd \
		-e DISPLAY=unix$DISPLAY \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		-v "/home/$(whoami)/.Xauthority:/home/user/.Xauthority" \
		-v /etc/localtime:/etc/localtime:ro \
		-v $CACHE_DIR/.TelegramDesktop:/home/user/.local/share/TelegramDesktop/ \
		xorilog/telegram
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
