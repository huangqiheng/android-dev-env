#!/bin/bash

. ./functions.sh

main () 
{
	nocmd_udpate ratpoison

	# for system
	install_ratpoison
	install_pinyin_fcitx
	install_wallpaper
	install_xscreensaver

	# for routine
	install_terminal
	install_browser
	install_utils_mini

	# for work
	install_telegram
	install_libreoffice

	chownHome
}

main "$@"; exit $?

