#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
 check_apt python3-pip
 pip3 install fierce

 fierce --domain baidu.com --dns-servers 8.8.8.8
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

