#!/bin/bash

. $(dirname $(dirname $(dirname $(readlink -f $0))))/basic_functions.sh

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
	install_utils

	# for work
	install_skype
	install_telegram
	install_whatsapp
	install_libreoffice
	install_virtualbox

	chownHome
}

main "$@"; exit $?

