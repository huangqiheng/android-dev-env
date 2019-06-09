#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	show_help_exit
}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL
------- 找回启动菜单 -------

1）ls命令。找出那个分区安装了系统
	ls 				//显示所有分区
	ls (hd0,msdos*)/boot/grub	//测试某分区是否有安装grub

2）设定root和prefix。设定以那个分区作为“主分区”，以及那个目录去寻找grub
	set root=(hd0,msdos6)
	set prefix=(hd0,msdos6)/boot/grub	//上面第1步骤所找到的

3）载入normal模块启动菜单。
	insmod /boot/grub/x86_64-efi/normal.mod //载入normal模块
	normal				//启动normal模块

------- 手动引导 -------
1）指定包含vmlinuz和initrd的目录
	root (hd0,8)

2）指定包含了/sbin/init即挂载了/的分区
	kernel =/boot/vmlinuz-2.6.18-274.el5 ro root=/dev/sda8

3）指定内核镜像，和启动
	initrd /boot/initrd-2.6.xxx.img	//据说可省略
	boot

------- 进系统后更新到/boot/grub/grub.cfg中 -------
	update-grub2
	grub-install /dev/sda

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
