#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	logger "before system shutdown"
}

enable_service()
{
	check_sudo

	local this_param="$1"
	local this_file=$(basename $THIS_SCRIPT)
	local this_name=${this_file%.*}

	cat > /lib/systemd/system/${this_name}.service <<- EOL
	[Unit]
	Description=Script run before shutdown
	DefaultDependencies=no
	After=final.target

	[Service]
	Type=oneshot
	ExecStart=/bin/dash ${THIS_SCRIPT}

	[Install]
	WantedBy=final.target
	EOL

	systemctl enable ${this_name}
	systemctl start ${this_name}
}

enable_service()
{
	check_sudo

	local this_file=$(basename $THIS_SCRIPT)
	local this_name=${this_file%.*}

	systemctl stop ${this_name}
	systemctl disable ${this_name}
	unlink /lib/systemd/system/${this_name}.service 2>/dev/null
}

install_routine()
{

}

maintain()
{
	[ "$1" = 'install' ] && install_routine && exit
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
