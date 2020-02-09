#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	check_docker

	select_subpath $CACHE_DIR/TelegramDesktop "$1"
	TelegramHome="$CACHE_DIR/TelegramDesktop/$FUNC_RESULT"
	TeleName=$(rm_space "telegram-$FUNC_RESULT")

	chownUser $CACHE_DIR

	docker run --rm -it --name $TeleName \
		--hostname=$(hostname) \
		--device /dev/snd \
		-e DISPLAY=unix$DISPLAY \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		-v "/home/$(whoami)/.Xauthority:/home/user/.Xauthority" \
		-v /etc/localtime:/etc/localtime:ro \
		-v $TelegramHome:/home/user/.local/share/TelegramDesktop/ \
		xorilog/telegram

	self_cmdline tg
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
