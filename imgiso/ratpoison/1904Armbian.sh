#!/bin/bash

. $(dirname $(dirname $(dirname $(readlink -f $0))))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	nocmd_udpate ratpoison

	# for system
	install_ratpoison
	default_session ratpoison
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

default_session()
{
	if [ "$DESKTOP_SESSION" = "$1" ]; then
		log_y 'session is ready'
		return
	fi

	log_y  "Now has sessions: $(ls /usr/share/xsessions/ | sed 's/.desktop//' | tr '\n' ',' | sed 's/,$//')"

	set_conf '/etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf'
	set_conf user-session "$1"

	log_y  "Set session: $1"
}

main "$@"; exit $?

