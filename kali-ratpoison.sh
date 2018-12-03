#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	[ "$1" = 'check' ] || check_update f

	install_ratpoison 	# system
	install_pinyin		# input

	install_wallpaper	# appearance
	install_xscreensaver 	# lock

	install_terminal
	install_browser
	install_virtualbox
	install_utils
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

	#exec nitrogen --head=0 --restore --set-zoom-fill
	#exec nitrogen --head=1 --restore --set-zoom-fill
	ratpoisonrc "exec nitrogen --set-zoom-fill --restore $DATA_DIR"
	ratpoisonrc "exec xcompmgr -c -f -D 5 &"
}

install_browser()
{
	if ! cmd_exists chromium; then
		check_apt chromium  chromium-l10n
	fi

	ratpoisonrc "bind C-f exec firefox"
	ratpoisonrc "bind C-o exec chromium"
}

install_terminal()
{
	check_apt xterm 
	check_apt lxterminal
	check_apt tmux

	ratpoisonrc "bind c exec lxterminal"
	ratpoisonrc "bind C-c exec xterm -rv -fa nonaco -fs 10"
	ratpoisonrc "bind M-c exec tmux"
}

install_ratpoison()
{
	check_apt ratpoison 

	cat > /usr/share/xsessions/ratpoison.desktop <<EOL
[Desktop Entry]
Encoding=UTF-8
Name=Ratpoison
Comment=Start Ratpoison as your window manager
Exec=ratpoison
Icon=
Type=Application
EOL
	
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
	check_apt ibus ibus-pinyin
	check_apt fcitx-frontend-all fcitx-config-gtk2 fcitx-sunpinyin
	check_apt fonts-wqy-zenhei 

	im-config -n fcitx
	log_red '--Please run fcitx-config-gtk after installed.'

	ratpoisonrc "exec fcitx"
}


install_xscreensaver()
{
	check_apt xscreensaver
	ratpoisonrc "exec xscreensaver -nosplash"
	ratpoisonrc "bind C-l exec xscreensaver-command -lock"
}


main "$@"; exit $?

