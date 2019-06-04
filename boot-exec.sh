#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_sudo

	cat > /lib/systemd/system/bootexec.service <<EOL
[Unit]
Description=linux transparent proxy script
Requires=network.target network-online.target
After=network.target network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=/bin/bash -c "until ping -nq -c1 -W1 114.114.114.114 &>/dev/null; do :; done"
ExecStart=/usr/local/bin/ss-tproxy start
ExecStop=/usr/local/bin/ss-tproxy stop

[Install]
WantedBy=multi-user.target
EOL
	check_service bootexec
}

main "$@"; exit $?


