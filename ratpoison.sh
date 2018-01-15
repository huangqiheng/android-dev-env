#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_update
	install_ratpoison
	install_xterm
	install_firefox
	install_pulseaudio
	install_pinyin
	install_astrill
}

install_firefox()
{
	check_apt firefox
	check_apt ubuntu-restricted-extras

	ratpoisonrc "bind C-f exec firefox"
}

install_xterm()
{
	check_apt xterm
	ratpoisonrc "bind c exec xterm -rv -fa nonaco -fs 10"
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
	fcitx-imlist -s "fcitx-keyboard-us"

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

	local THIS_DIR=/tmp/install-scripts
	mkdir -p $THIS_DIR 
	cd $THIS_DIR

	if [ ! -f "astrill-setup-linux64.sh" ]; then
		wget https://astrill4u.com/downloads/astrill-setup-linux64.sh
	fi

	set_comt $THIS_DIR/astrill-setup-linux64.sh
	set_comt off '#' 'read x'

	bash astrill-setup-linux64.sh

	ratpoisonrc "bind C-a exec /usr/local/Astrill/astrill"
}

main "$@"; exit $?

