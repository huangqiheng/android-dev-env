#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	if [ "$1" = 'sdkman' ]; then
		check_apt zip unzip

		if [ ! -f "$UHOME/.sdkman/bin/sdkman-init.sh" ]; then
			curl -s https://get.sdkman.io | bash
			source "$UHOME/.sdkman/bin/sdkman-init.sh"
		fi
		sdk install kotlin
		exit 0
	fi

	snap install --classic kotlin

}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
