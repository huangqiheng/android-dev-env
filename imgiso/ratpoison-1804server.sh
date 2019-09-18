#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $EXEC_DIR/ratpoison-functions.sh

main () 
{
	check_apt_sources
	nocmd_udpate ratpoison

	install_ratpoison 	# system
	install_pinyin_fcitx 	# input
	install_sounds		# sound
	install_graphics	# graphic

	install_wallpaper	# appearance
	install_xscreensaver 	# lock

	install_terminal
	install_browser
	install_virtualbox
	install_utils

	chownHome
}

check_apt_sources()
{
	line_count=$(grep "main restricted universe multiverse" /etc/apt/sources.list | wc -l)

	if [ $line_count -gt 3 ]; then
		log 'sources.list is ok'
		return
	fi

	full_sources
}

main "$@"; exit $?

