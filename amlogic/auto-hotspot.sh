#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

root_dir=/media/${RUN_USER}/ROOTFS
shadow_file=${root_dir}/etc/shadow

apssid="${APSSID:-ArmbianHotspot}"
appass="${APPASS:-DontConnectMe}"
appass="${1:-$appass}"

rootpass="${ROOTPASS:-armbianrootpass}"
rootpass="${2:-$rootpass}"

main () 
{
	if [ ! -d $root_dir ]; then
		log_y 'Please plug in the armbian sd card'
		exit 1
	fi

	if [ ! "X$1" = 'X' ]; then
		rootpass="$1"
	fi

	auto_login_root "$rootpass"
	entry_code
}

auto_login_root()
{
	encpass=$(echo "$1" | mkpasswd --method=SHA-512 --stdin)
	sed -i 's,^\(root:\)[^:]*\(:.*\)$,\1'"$encpass"'\2,' $shadow_file

	rm -f ${root_dir}/root/.not_logged_in_yet

	cat > ${root_dir}/lib/systemd/system/getty@tty1.service.d/20-autologin.conf <<-EOL
	[Service]
	ExecStart=
	ExecStart=-/sbin/agetty --autologin root --noclear %I \$TERM
EOL
}

entry_code()
{
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
