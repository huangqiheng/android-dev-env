#!/bin/bash 
ROOT_DIR=`dirname $(readlink -f $0)`

main() 
{
	check_update

	case "$1" in
	'nload')
		check_apt nload 
		nload
		;;
	'iftop')
		check_apt iftop
		iftop -n
		;;
	'iptraf')
		check_apt iptraf iptraf-ng
		iptraf
		;;
	'nethogs')
		check_apt nethogs
		nethogs
		;;
	'bmon')
		check_apt bmon
		bmon
		;;
	'slurm')
		check_apt slurm
		slurm -s -i $2 #eth0
		;;
	'tcptrack')
		check_apt tcptrack
		tcptrack
		;;
	'vnstat')
		check_apt vnstat
		service vnstat status
		vnstat -l -i $2 #eth0
		;;
	'bwm-ng')
		check_apt bwm-ng
		bwm-ng -o curses2
		;;
	'cbm')
		check_apt cbm
		cbm
		;;
	'speedometer')
		check_apt speedometer
		speedometer -r $2 -t $2 #eth0
		;;
	'pktstat')
		check_apt pktstat
		pktstat -i $2 -nt #eth0
		;;
	'netwatch')
		check_apt netwatch
		netwatch -e $2 -nt #eth0
		;;
	'trafshow')
		check_apt trafshow
		trafshow -i $2 tcp #eth0 
		;;
	'netload')
		check_apt netload
		netload $2 #eth0
		;;
	'ifstat')
		check_apt ifstat
		ifstat -t -i $2 0.5 #eth0 
		;;
	'dstat')
		check_apt dstat
		dstat -nt
		;;
	'collectl')
		check_apt collectl
		collectl -sn -oT -i0.5
		;;
	esac
}

#-------------------------------------------------------
#		basic functions
#-------------------------------------------------------

check_update()
{
	if [ $(whoami) != 'root' ]; then
	    echo "This script should be executed as root or with sudo:"
	    echo "	sudo $0"
	    exit 1
	fi

	local last_update=`stat -c %Y  /var/cache/apt/pkgcache.bin`
	local nowtime=`date +%s`
	local diff_time=$(($nowtime-$last_update))

	local repo_changed=0

	if [ $# -gt 0 ]; then
		for the_param in "$@"; do
			local the_ppa=$(echo $the_param | sed 's/ppa:\(.*\)/\1/')

			if [ ! -z $the_ppa ]; then 
				if ! grep -q "^deb .*$the_ppa" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
					add-apt-repository -y $the_param
					repo_changed=1
					break
				else
					log "repo ${the_ppa} has already exists"
				fi
			fi
		done
	fi 

	if [ $repo_changed -eq 1 ] || [ $diff_time -gt 604800 ]; then
		apt update -y
	fi

	if [ $diff_time -gt 6048000 ]; then
		apt upgrade -y
	fi 
}

check_apt()
{
	for package in "$@"; do
		if [ $(dpkg-query -W -f='${Status}' ${package} 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
			apt install -y "$package"
		else
			log "${package} has been installed"
		fi
	done
}

log() 
{
	echo "$@"
	#logger -p user.notice -t install-scripts "$@"
}

cmd_exists() 
{
    type "$1" > /dev/null 2>&1
}

main "$@"; exit $?
