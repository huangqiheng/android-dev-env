#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $EXEC_DIR/ratpoison-functions.sh

main () 
{
	nocmd_udpate ratpoison

	install_ratpoison 	# system
	install_pinyin_fcitx 	# input

	install_wallpaper	# appearance
	install_xscreensaver 	# lock

	install_terminal
	install_browser
	install_virtualbox
	install_utils

	chownHome
}

main "$@"; exit $?

