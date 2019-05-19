#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

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

install_pinyin_fcitx()
{
	check_apt dbus-x11
	check_apt fonts-wqy-zenhei fonts-wqy-microhei
	check_apt fcitx-frontend-all fcitx-config-gtk2 fcitx-sunpinyin

	check_apt zenity
	im-config -n fcitx

	xinitrc 'fcitx' 'fcitx -d' 
	
	log_y '--Please run fcitx-config-gtk after installed.'
}

install_virtualbox()
{
	check_apt virtualbox
	ratpoisonrc "bind C-v exec virtualbox"
}

install_utils()
{
	check_apt proxychains
	check_apt xclip
	check_apt shutter
	check_apt keynav
	check_apt feh xpdf 

	ratpoisonrc "exec keynav &"
}

install_wallpaper()
{
	check_apt xcompmgr nitrogen

	#exec nitrogen --head=0 --restore --set-zoom-fill
	#exec nitrogen --head=1 --restore --set-zoom-fill
	ratpoisonrc "exec nitrogen --random --set-zoom-fill --restore $DATA_DIR/images"
	ratpoisonrc "exec xcompmgr -c -f -D 5 &"

	mkdir -p $HOME/.config/nitrogen 

	cat > $HOME/.config/nitrogen/bg-saved.cfg <<-EOL
	[xin_0]
	file=${DATA_DIR}/images/skylake.jpg
	mode=5
	bgcolor=#000000
EOL

	set_ini $HOME/.config/nitrogen/nitrogen.cfg
	set_ini nitrogen dirs "$DATA_DIR/images;"
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
	install_terminals
	ratpoisonrc "bind c exec xterm -fa nonaco -fs 10"
	ratpoisonrc "bind C-c exec xterm -rv -fa nonaco -fs 10"
	ratpoisonrc "bind M-c exec lxterminal"
	ratpoisonrc "bind M-C exec tmux"
}

install_ratpoison()
{
	check_apt xinit ratpoison 

	mkdir -p /usr/share/xsessions

	cat > /usr/share/xsessions/ratpoison.desktop <<-EOL
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

install_xscreensaver()
{
	check_apt xscreensaver
	check_apt xscreensaver-data
	check_apt xscreensaver-gl

	set_conf $HOME/.xscreensaver
	set_conf mode one ':'
	set_conf selected 142 ':'

	ratpoisonrc "exec xscreensaver -nosplash"
	ratpoisonrc "bind C-l exec xscreensaver-command -lock"
}


main "$@"; exit $?

