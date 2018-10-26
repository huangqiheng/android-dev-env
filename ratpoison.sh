#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	check_apt_sources
	[ "$1" = 'check' ] || check_update f

	install_ratpoison 	# system
	install_pinyin		# input
	install_sounds		# sound
	install_graphics	# graphic

	install_wallpaper	# appearance
	install_xscreensaver 	# lock

	install_terminal
	install_browser
	install_virtualbox
	install_utils
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

install_virtualbox()
{
	check_apt virtualbox
	ratpoisonrc "bind C-v exec virtualbox"
}

install_utils()
{
	check_apt xclip
}

install_wallpaper()
{
	check_apt xcompmgr nitrogen

	ratpoisonrc "exec nitrogen --restore $DATA_DIR"
	ratpoisonrc "exec xcompmgr -c -f -D 5 &"
}

install_browser()
{
	check_apt firefox chromium-browser
	check_apt ubuntu-restricted-extras

	ratpoisonrc "bind C-f exec firefox"
	ratpoisonrc "bind C-o exec chromium-browser"
}

install_terminal()
{
	check_apt xterm lxterminal
	ratpoisonrc "bind c exec lxterminal"
	ratpoisonrc "bind C-c exec xterm -rv -fa nonaco -fs 10"
	ratpoisonrc "bind M-c exec xterm -fa nonaco -fs 10"
}

install_ratpoison()
{
	check_apt xinit ratpoison 
	
	ratpoisonrc "exec rpws init 6 -k"
	ratpoisonrc "bind M-1 exec rpws 1"
	ratpoisonrc "bind M-2 exec rpws 2"
	ratpoisonrc "bind M-3 exec rpws 3"
	ratpoisonrc "bind M-4 exec rpws 4"
	ratpoisonrc "bind M-5 exec rpws 5"
	ratpoisonrc "bind M-6 exec rpws 6"
}

install_pinyin()
{
	check_apt dbus-x11
	check_apt fonts-wqy-zenhei fcitx-frontend-all fcitx-config-gtk2 fcitx-sunpinyin

	im-config -n fcitx
	log '--Please run fcitx-config-gtk after installed.'

	ratpoisonrc "exec fcitx"
}

install_graphics()
{
	if lspci | grep -i "VGA.*intel"; then 
		check_apt xserver-xorg-video-intel
	fi

	check_apt mesa-utils 
}

install_sounds()
{
	check_apt alsa-base alsa-utils pulseaudio linux-sound-base libasound2

	ratpoisonrc "exec pulseaudio"
}

install_xscreensaver()
{
	check_apt xscreensaver
	ratpoisonrc "exec xscreensaver -nosplash"
	ratpoisonrc "bind C-l exec xscreensaver-command -lock"
}


main "$@"; exit $?

