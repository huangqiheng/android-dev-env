#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	if ! cmd_exists x11docker; then
		check_sudo
		check_apt curl
		curl -fsSL https://raw.githubusercontent.com/mviereck/x11docker/master/x11docker | /bin/bash -s -- --update
	fi

	show_help_exit
}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL
Xfce4 Terminal 				x11docker x11docker/xfce xfce4-terminal
GLXgears with hardware acceleration  	x11docker --gpu x11docker/xfce glxgears
Kodi media center with hardware 	x11docker --gpu --pulseaudio --share ~/Videos erichough/kodi.
XaoS fractal generator 			x11docker patricknw/xaos
Telegram messenger with persistent	x11docker --home xorilog/telegram
Firefox with shared Download folder. 	x11docker --share $HOME/Downloads jess/firefox
Tor browser 				x11docker jess/tor-browser
Chromium browser 			x11docker -- jess/chromium --no-sandbox
VLC media player 			x11docker --pulseaudio --share=$HOME/Videos jess/vlc

FVWM (based on Alpine, 22.5 MB) 	x11docker --desktop x11docker/fvwm
Fluxbox (based on Debian, 87 MB) 	x11docker --desktop x11docker/fluxbox
Lumina (based on Void Linux) 		x11docker --desktop x11docker/lumina
LXDE 					x11docker --desktop x11docker/lxde
LXQt 					x11docker --desktop x11docker/lxqt
Xfce 					x11docker --desktop x11docker/xfce
CDE Common Desktop Environment 		x11docker --desktop --init=systemd --cap-default x11docker/cde
Mate 					x11docker --desktop x11docker/mate
Enlightenment (based on Void Linux) 	x11docker --desktop --gpu --runit x11docker/enlightenment
Trinity (successor of KDE 3) 		x11docker --desktop x11docker/trinity
Cinnamon 				x11docker --desktop --gpu --dbus-system x11docker/cinnamon
deepin (3D desktop from China) 		x11docker --desktop --gpu --init=systemd x11docker/deepin
LiriOS (based on Fedora) 		x11docker --desktop --gpu lirios/unstable
KDE Plasma 				x11docker --desktop --gpu x11docker/plasma
KDE Plasma as nested Wayland compositor x11docker --gpu x11docker/plasma startplasmacompositor
LXDE with wine and PlayOnLinux 		x11docker --desktop --home --pulseaudio x11docker/lxde-wine
EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
