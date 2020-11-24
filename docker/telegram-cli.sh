#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_docker

	cd $CACHE_DIR
	if [ ! -d .telegram-cli ]; then
		mkdir -p .telegram-cli
		chownUser $CACHE_DIR
	fi

	docker run -it --rm -v $CACHE_DIR/.telegram-cli:/home/user/.telegram-cli frankwolf/telegram-cli
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
