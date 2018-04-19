#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_update f
	install_ratpoison
	install_terminal
	install_browser
	install_pulseaudio
	install_pinyin
	install_astrill
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

ratpoisonrc()
{
	echo_file=$HOME/.ratpoisonrc
	if grep -iq "$1" $echo_file; then
		return 1
	fi
	echo "$1" >> $echo_file
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
	check_apt fonts-wqy-zenhei fcitx-frontend-all fcitx-imlist fcitx-sunpinyin

	im-config -n fcitx

	if cmd_exists fcitx-imlist; then
		fcitx-imlist -s "fcitx-keyboard-us"
	fi

	ratpoisonrc "exec fcitx"
}

install_pulseaudio()
{
	check_apt alsa-base alsa-utils pulseaudio linux-sound-base libasound2

	ratpoisonrc "exec pulseaudio"
}


install_astrill()
{
	if cmd_exists /usr/local/Astrill/astrill; then
		echo "astrill has been installed."
		return
	fi

	cd $CACHE_DIR

	if [ ! -f "astrill-setup-linux64.sh" ]; then
		wget https://astrill4u.com/downloads/astrill-setup-linux64.sh
	fi

	if [ ! -f "astrill-setup-linux64.sh" ]; then
		log 'FIXME: download astrill failure'
		return
	fi

	set_comt $CACHE_DIR/astrill-setup-linux64.sh
	set_comt off '#' 'read x'

	bash astrill-setup-linux64.sh

	ratpoisonrc "bind C-a exec /usr/local/Astrill/astrill"
}

main "$@"; exit $?

