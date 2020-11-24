#!/bin/bash

. functions.sh

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

