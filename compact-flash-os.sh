#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	check_apt libblockdev-crypto2 libblockdev-mdraid2

	handle_fstab
	link_mtab
	set_kernel_behavior
	disable_bash_history
	daily_clean_tmp
	set_apt_env
	set_permanent /permanent
}

set_permanent()
{
	mkdir -p "$1"
	chmod 777 "$1"
}

add_fstab_tmpfs()
{
	target_str="tmpfs $1 tmpfs defaults,noatime 0 0"
	if ! grep -q "$target_str" /etc/fstab; then
		echo $target_str >> /etc/fstab  
	fi
}

disable_swap()
{
	sed -i '/\sswap\s/s/^/#/' /etc/fstab 
}

handle_fstab()
{
	disable_swap

	add_fstab_tmpfs /tmp
	add_fstab_tmpfs /var/tmp
	add_fstab_tmpfs /var/log
	add_fstab_tmpfs /var/mail

	rootLine=$(sed -n "/\s\/\s/p" /etc/fstab)
	IFS=' '; set -- $rootLine
	sed -i "/\s\/\s/s/$4 $5 $6/noatime 0 1/" /etc/fstab
}

link_mtab()
{
	rm -f /etc/mtab
	ln -s /proc/mounts /etc/mtab
}

set_apt_env()
{
	cat >/etc/init.d/apt-tmpfs <<EOL
#!/bin/bash
#
### BEGIN INIT INFO
# Provides:          apt-tmpfs
# Required-Start:
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Create /var/log/apt on tmpfs at startup
# Description:       Create /var/log/apt needed by APT.
### END INIT INFO
#
# main()
#
case "${1:-''}" in
  'start')
   # create the /var/log/apt needed by apt
   mkdir -p /var/log/apt
   chmod 777 /var/log/apt
   ;;
  'stop')
   ;;
  'restart')
   ;;
  'reload'|'force-reload')
   ;;
  'status')
   ;;
  *)
   echo "Usage: $SELF start"
   exit 1
   ;;
esac
EOL
	chmod +x /etc/init.d/apt-tmpfs
	update-rc.d apt-tmpfs defaults 90 10
}

daily_clean_tmp()
{
	cat >/etc/cron.daily/clean-tmp <<EOL
#!/bin/sh
# Cleanup the /tmp directory and keep the 4 last files only
#
# 01/09/2008 - Creation by N. Bernaerts
# 13/07/2012 - No error if /tmp holds less than 4 files (thanks to Konstantin Laufer)
# 14/07/2012 - Properly handle filenames with specific caracters like '(' and ')'

ls /tmp/test/* -t1 | sed '1,4d' | sed 's/\(.*\)/"\1"/g' | xargs rm -f $$.dummy
EOL
}

disable_bash_history()
{
	for bashfile in '/root/.bashrc' "$UHOME/.bashrc"; do
		set_comt $bashfile
		set_comt on '#' 'unset HISTFILE'
		set_comt on '#' 'unset HISTFILESIZE'
		set_comt on '#' 'unset HISTSIZE'
	done
}

set_kernel_behavior()
{
	set_conf /etc/sysctl.conf
	set_conf vm.swappiness 0
	set_conf vm.laptop_mode 0
	set_conf vm.dirty_writeback_centisecs 12000
	set_conf vm.dirty_expire_centisecs 12000
	set_conf vm.dirty_ratio 10
	set_conf vm.dirty_background_ratio 1
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
