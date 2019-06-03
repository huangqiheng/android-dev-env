#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh


main () 
{
	cloud_init_remove
	log 'Please reboot.'
}

cloud_init_remove()
{
        if [ ! -d /etc/cloud/ ]; then
                log_y 'cloud-init isnt exists'
                return
        fi

        log_g 'datasource_list: [ None ]' | sudo -s tee /etc/cloud/cloud.cfg.d/90_dpkg.cfg
        apt-get purge -y cloud-init
        rm -rf /etc/cloud/
        rm -rf /var/lib/cloud/
}

maintain()
{
	check_sudo
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
