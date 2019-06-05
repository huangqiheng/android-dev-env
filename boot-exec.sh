#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_sudo

	if ! cmd_exists bootexec; then
		make_cmdline bootexec <<-EOF
		#!/bin/dash
EOF
	fi

	stuffed_line '/usr/local/bin/bootexec' "$@" 

	if [ ! -f /lib/systemd/system/bootexec.service ]; then
		cat > /lib/systemd/system/bootexec.service <<EOL
[Unit]
Description=linux exec scripts on boot after online
Requires=network.target network-online.target
After=network.target network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=/bin/bash -c "until ping -nq -c1 -W1 114.114.114.114 &>/dev/null; do :; done"
ExecStart=/usr/local/bin/bootexec

[Install]
WantedBy=multi-user.target
EOL
	fi

	check_service bootexec
}

main "$@"; exit $?


