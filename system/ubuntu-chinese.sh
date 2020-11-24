#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	echo 'en_US' > $HOME/.config/user-dirs.locale

	set_conf $HOME/.config/user-dirs.dirs
	set_conf XDG_DESKTOP_DIR "\$HOME/Desktop"
	set_conf XDG_DOWNLOAD_DIR "\$HOME/Download"
	set_conf XDG_TEMPLATES_DIR "\$HOME/Template"
	set_conf XDG_PUBLICSHARE_DIR "\$HOME/Public"
	set_conf XDG_DOCUMENTS_DIR "\$HOME/Document"
	set_conf XDG_MUSIC_DIR "\$HOME/Music"
	set_conf XDG_PICTURES_DIR "\$HOME/Picture"
	set_conf XDG_VIDEOS_DIR "\$HOME/Video"
}

main "$@"; exit $?
