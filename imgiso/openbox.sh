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

main () 
{
	install_openbox

	auto_login
	auto_startx

	check_apt  xcompmgr cairo-dock

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
