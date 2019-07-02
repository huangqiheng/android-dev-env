#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

install_openbox() 
{
	check_apt xinit openbox obconf

	cat > /usr/share/xsessions/openbox.desktop <<-EOL
	[Desktop Entry]
	Encoding=UTF-8
	Name=openbox
	Comment=Start openbox as your window manager
	Exec=openbox
	Icon=
	Type=Application
EOL
}

install_wallpaper()
{
	check_apt feh
	feh --bg-scale $DATA_DIR/images/forest.jpg
	handle_rc "$UHOME/.config/openbox/autostart" sh ~/.fehbg &
}

install_docker()
{
	check_apt xcompmgr cairo-dock
	handle_rc "$UHOME/.config/openbox/autostart" xcompmgr &
	handle_rc "$UHOME/.config/openbox/autostart" cairo-dock &
}

main () 
{
	install_openbox
	install_wallpaper
	install_docker
	auto_login_startx
}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
