#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	install_openbox
	install_wallpaper
	install_docker
	auto_login_startx
}

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
	feh --bg-fill $DATA_DIR/images/cyberpunk.jpg
	stuffed_line "$UHOME/.config/openbox/autostart" bash ~/.fehbg &
}

install_docker()
{
	check_apt xcompmgr cairo-dock
	stuffed_line "$UHOME/.config/openbox/autostart" xcompmgr &
	stuffed_line "$UHOME/.config/openbox/autostart" cairo-dock &
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
