#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

main () 
{
	check_apt gnome-tweak-tool
	check_apt gir1.2-gtop-2.0 gir1.2-networkmanager-1.0 gir1.2-clutter-1.0
	check_apt gnome-shell-extension-system-monitor

}

main "$@"; exit $?
