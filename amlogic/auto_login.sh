#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

root_dir=/media/${RUN_USER}/ROOTFS
shadow_file=${root_dir}/etc/shadow

main () 
{
	if [ ! -d $root_dir ]; then
		log_y 'Please plug in the armbian sd card'
		exit 1
	fi

	if [ "X$ARMROOTPASS" = 'X' ]; then
		log_y 'Please set ARMROOTPASS in config.sh'
		exit 2
	fi

	encpass=$(echo "$ARMROOTPASS" | mkpasswd --method=SHA-512 --stdin)
	sed -i 's,^\(root:\)[^:]*\(:.*\)$,\1'"$encpass"'\2,' $shadow_file

	rm -f ${root_dir}/root/.not_logged_in_yet

	cat > ${root_dir}/lib/systemd/system/getty@tty1.service.d/20-autologin.conf <<-EOL
	[Service]
	ExecStart=
	ExecStart=-/sbin/agetty --autologin root --noclear %I \$TERM
EOL

	handle_rc "${root_dir}/root/.bashrc" 'entry_point.sh' "if [ \"\$(tty)\" = \"/dev/tty1\" ]; then sh /root/entry_point.sh; fi"

	cat > "${root_dir}/root/entry_point.sh" <<-EOL
	#!/bin/dash
	while true; do
		ifconfig -a
		iwconfig
	don
EOL
}

main "$@"; exit $?
