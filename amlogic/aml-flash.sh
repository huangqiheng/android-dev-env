#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	check_sudo
	check_apt libusb-dev

	cd $CACHE_DIR
	if [ ! -d aml-linux-usb-burn ]; then
		git clone https://github.com/Stane1983/aml-linux-usb-burn.git
	fi

	cat > /etc/udev/rules.d/70-persistent-usb-ubuntu.rules <<EOL
SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="1b8e", ATTR{idProduct}=="c003", MODE:="0666", SYMLINK+="worldcup"
EOL

	IFS=
	cmd_str=$(cat <<- EOL
	#!/bin/dash
	exec_name=\$(basename \$0)
	soc=\${exec_name##*.}
	current=\$(pwd)
	cd ${CACHE_DIR}/aml-linux-usb-burn
	if [ -f \$1 ]; then
		./aml-flash --debug --img=\$1 --soc=\$soc --wipe --reset=n --parts=all
	fi
	./aml-flash --debug --img=\$current/\$1 --soc=\$soc --wipe --reset=n --parts=all
EOL
)

	echo $cmd_str | make_cmdline 'aml-flash-m8' --
	echo $cmd_str | make_cmdline 'aml-flash-gxl' --
	echo $cmd_str | make_cmdline 'aml-flash-axg' --
	echo $cmd_str | make_cmdline 'aml-flash-txlx' --
}

main "$@"; exit $?
