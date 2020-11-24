#!/bin/dash
. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)
#--------------------------------------------------------------------------------#

main() 
{
	if ! cmd_exists flatpak; then
		check_udpate_once
		check_apt flatpak gnome-software-plugin-flatpak
		flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
		flatpak install flathub net.meijn.onvifviewer
	fi

	flatpak run net.meijn.onvifviewer
}

#---------------------------------------------------------------------------------#
main_entry $@
