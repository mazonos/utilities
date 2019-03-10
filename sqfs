#!/bin/bash

: ${distro="mazonos"}
: ${label="MAZONOS"}
export XHOME=$HOME
export BASE=$XHOME/$distro"-live"
export LIVE=$XHOME/$distro"-live/cd/live"
export GRUB=$XHOME/$distro"-live/cd/boot/grub"
export ISOLINUX=$XHOME/$distro"-live/cd/boot/isolinux"
export WORK=$XHOME/$distro"-live/work/rootfs"
export WORKDEV=$XHOME/$distro"-live/work/rootfs/dev"
export WORKDEVPTS=$XHOME/$distro"-live/work/rootfs/dev/pts"
export WORKPROC=$XHOME/$distro"-live/work/rootfs/proc"
export WORKSYS=$XHOME/$distro"-live/work/rootfs/sys"
export WORKMEDIA=$XHOME/$distro"-live/work/rootfs/media"
export WORKTMP=$XHOME/$distro"-live/work/rootfs/tmp"

NORMAL="\\033[0;39m"         # Standard console grey
SUCCESS="\\033[1;32m"        # Success is green
WARNING="\\033[1;33m"        # Warnings are yellow
FAILURE="\\033[1;31m"        # Failures are red
INFO="\\033[1;36m"           # Information is light cyan
BRACKET="\\033[1;34m"        # Brackets are blue

# Use a colored prefix
BMPREFIX="     "
SUCCESS_PREFIX="${SUCCESS}  *  ${NORMAL}"
FAILURE_PREFIX="${FAILURE}*****${NORMAL}"
WARNING_PREFIX="${WARNING} *** ${NORMAL}"
SKIP_PREFIX="${INFO}  S  ${NORMAL}"

SUCCESS_SUFFIX="${BRACKET}[${SUCCESS}  OK  ${BRACKET}]${NORMAL}"
FAILURE_SUFFIX="${BRACKET}[${FAILURE} FAIL ${BRACKET}]${NORMAL}"
WARNING_SUFFIX="${BRACKET}[${WARNING} WARN ${BRACKET}]${NORMAL}"
SKIP_SUFFIX="${BRACKET}[${INFO} SKIP ${BRACKET}]${NORMAL}"

BOOTLOG=/run/bootlog
KILLDELAY=3
SCRIPT_STAT="0"

# Set any user specified environment variables e.g. HEADLESS
[ -r /etc/sysconfig/rc.site ]  && . /etc/sysconfig/rc.site

## Screen Dimensions
# Find current screen size
if [ -z "${COLUMNS}" ]; then
   COLUMNS=$(stty size)
   COLUMNS=${COLUMNS##* }
fi

# When using remote connections, such as a serial port, stty size returns 0
if [ "${COLUMNS}" = "0" ]; then
   COLUMNS=80
fi

## Measurements for positioning result messages
COL=$((${COLUMNS} - 8))
WCOL=$((${COL} - 2))

## Set Cursor Position Commands, used via echo
SET_COL="\\033[${COL}G"      # at the $COL char
SET_WCOL="\\033[${WCOL}G"    # at the $WCOL char
CURS_UP="\\033[1A\\033[0G"   # Up one line, at the 0'th char
CURS_ZERO="\\033[0G"

function timespec()
{
   STAMP="$(echo `date +"%b %d %T %:z"` `hostname`) "
   return 0
}

function log_success_msg()
{
    /bin/echo -n -e "${BMPREFIX}${@}"
    /bin/echo -e "${CURS_ZERO}${SUCCESS_PREFIX}${SET_COL}${SUCCESS_SUFFIX}"

    # Strip non-printable characters from log file
    logmessage=`echo "${@}" | sed 's/\\\033[^a-zA-Z]*.//g'`

    timespec
    /bin/echo -e "${STAMP} ${logmessage} OK" >> ${BOOTLOG}

    return 0
}

function log_success_msg2()
{
    /bin/echo -n -e "${BMPREFIX}${@}"
    /bin/echo -e "${CURS_ZERO}${SUCCESS_PREFIX}${SET_COL}${SUCCESS_SUFFIX}"

    echo " OK" >> ${BOOTLOG}

    return 0
}

function log_failure_msg()
{
    /bin/echo -n -e "${BMPREFIX}${@}"
    /bin/echo -e "${CURS_ZERO}${FAILURE_PREFIX}${SET_COL}${FAILURE_SUFFIX}"

    # Strip non-printable characters from log file

    timespec
    logmessage=`echo "${@}" | sed 's/\\\033[^a-zA-Z]*.//g'`
    /bin/echo -e "${STAMP} ${logmessage} FAIL" >> ${BOOTLOG}

    return 0
}

function log_failure_msg2()
{
    /bin/echo -n -e "${BMPREFIX}${@}"
    /bin/echo -e "${CURS_ZERO}${FAILURE_PREFIX}${SET_COL}${FAILURE_SUFFIX}"

    echo "FAIL" >> ${BOOTLOG}

    return 0
}

function log_warning_msg()
{
    /bin/echo -n -e "${BMPREFIX}${@}"
    /bin/echo -e "${CURS_ZERO}${WARNING_PREFIX}${SET_COL}${WARNING_SUFFIX}"

    # Strip non-printable characters from log file
    logmessage=`echo "${@}" | sed 's/\\\033[^a-zA-Z]*.//g'`
    timespec
    /bin/echo -e "${STAMP} ${logmessage} WARN" >> ${BOOTLOG}

    return 0
}

function log_skip_msg()
{
    /bin/echo -n -e "${BMPREFIX}${@}"
    /bin/echo -e "${CURS_ZERO}${SKIP_PREFIX}${SET_COL}${SKIP_SUFFIX}"

    # Strip non-printable characters from log file
    logmessage=`echo "${@}" | sed 's/\\\033[^a-zA-Z]*.//g'`
    /bin/echo "SKIP" >> ${BOOTLOG}

    return 0
}

function log_info_msg()
{
    /bin/echo -n -e "${BMPREFIX}${@}"

    # Strip non-printable characters from log file
    logmessage=`echo "${@}" | sed 's/\\\033[^a-zA-Z]*.//g'`
    timespec
    /bin/echo -n -e "${STAMP} ${logmessage}" >> ${BOOTLOG}

    return 0
}

function log_info_msg2()
{
    /bin/echo -n -e "${@}"

    # Strip non-printable characters from log file
    logmessage=`echo "${@}" | sed 's/\\\033[^a-zA-Z]*.//g'`
    /bin/echo -n -e "${logmessage}" >> ${BOOTLOG}

    return 0
}

function evaluate_retval()
{
	local error_value="${?}"

	if [ ${error_value} = 0 ]; then
		log_success_msg2
	else
		log_failure_msg2
   	fi
	return ${error_value}
}

function is_true()
{
   [ "$1" = "1" ] || [ "$1" = "yes" ] || [ "$1" = "true" ] ||  [ "$1" = "y" ] ||
   [ "$1" = "t" ]
}

function replicate(){
    for counter in $(seq 1 $2);
    do
        printf "%s" $1
    done
}

function maxcol(){
    if [ -z "${COLUMNS}" ]; then
       COLUMNS=$(stty size)
       COLUMNS=${COLUMNS##* }
    fi
    return $COLUMNS
}

function inkey(){
    read -t "$1" -n1 -r -p "" lastkey
}


function sh_main(){
    log_info_msg "mkdir -p $LIVE"
    mkdir -p $LIVE
    evaluate_retval

    log_info_msg "mkdir -p $GRUB"
    mkdir -p $GRUB
    evaluate_retval

    log_info_msg "mkdir -p $ISOLINUX"
    mkdir -p $ISOLINUX
    evaluate_retval

    log_info_msg "mkdir -p $WORK"
    mkdir -p $WORK
    evaluate_retval

    log_info_msg "rsync -av Aguarde, sincronizando diretorios..."
    rsync -av 				\
    --one-file-system 		\
    --exclude=/proc/* 		\
    --exclude=/etc/bashrc	\
    --exclude=/dev/* 		\
    --exclude=/sys/* 		\
    --exclude=/tmp/* 		\
    --exclude=/media/* 		\
    --exclude=/mnt/* 		\
    --exclude=/lost+found 	\
    --exclude=/chili 		\
    --exclude=/harbour 		\
    --exclude=/tools		\
    --exclude=/jhalfs		\
    --exclude=/mazon		\
    --exclude=/mazonos		\
    --exclude=/sources		\
    --exclude=/home/*		\
    --exclude=/usr/src/*	\
    --exclude=/var/log/journal/*	\
    --exclude=/packages		\
    --exclude=$BASE 		\
    / 						\
    $WORK > /dev/null 2>&1
    evaluate_retval

    log_info_msg "mount --bind /dev $WORKDEV"
    mount --bind /dev "$WORKDEV"
    evaluate_retval

    log_info_msg "mount -t devpts none $WORKDEVPTS"
    mount -t devpts none "$WORKDEVPTS"
    evaluate_retval

    log_info_msg "mount -t devpts none $WORKDEVPTS"
    mount --bind /proc "$WORKPROC"
    evaluate_retval

    log_info_msg "mount --bind /sys $WORKSYS"
    mount --bind /sys "$WORKSYS"
    evaluate_retval

    log_info_msg "mount --bind /media $WORKMEDIA"
    mount --bind /media "$WORKMEDIA"
    evaluate_retval

    log_info_msg "mount --bind /tmp $WORKTMP"
    mount --bind /tmp "$WORKTMP"
    evaluate_retval

    cp sqfs2 $WORK/root

    # Entrar no sistema chroot.
    log_info_msg "chroot $WORK /bin/bash"
    chroot $WORK /bin/bash -c "sh /root/sqfs2"
    evaluate_retval

    # FAZER AS MODIFICAÇÕES NECESSÁRIAS NO SISTEMA DE TRABALHO 
    # OU COPIE E EXECUTE sqfs2 no chroot

    #depmod -a $(uname -r)
    #mkinitramfs $(uname -r)

    #cp -Rf /home/vcatafesta/* /etc/skel/
    #chown -R root.root /etc/skel

    #for i in `cat /etc/passwd | awk -F":" '{print $1}'`
    #do
    #uid=`cat /etc/passwd | grep "^${i}:" | awk -F":" '{print $3}'`
    #[ "$uid" -gt "999" -a "$uid" -ne "65534" ] && userdel --force ${i} 2>/dev/null
    #done

    # Apague os arquivos que não são necessários no LiveCD e que podem atrapalhar o processo de inicialização:

    #for i in "/etc/hosts /etc/hostname /etc/resolv.conf /etc/timezone /etc/fstab /etc/mtab /etc/shadow /etc/shadow- \
    #/etc/gshadow /etc/gshadow- /etc/gdm/gdm-cdd.conf /etc/gdm/gdm.conf-custom /etc/X11/xorg.conf /boot/grub/menu.lst \
    #/boot/grub/device.map"
    #do
    #rm $i
    #done 2>/dev/null

    #find /var/run /var/log /var/mail /var/spool /var/lock /var/backups /var/tmp -type f -exec rm {}
    #\;
    #rm -r /tmp/* /root/* /home/* 2>/dev/null

    # Criar arquivos em branco no lugar de alguns dos arquivos que foram apagados no passo anterior,
    # para que o sistema não acuse sua falta e sua inicialização possa ocorrer normalmente:

    #for i in dpkg.log lastlog mail.log syslog auth.log daemon.log faillog lpr.log mail.warn
    #user.log boot debug mail.err \
    #messages wtmp bootstrap.log dmesg kern.log mail.info
    #do
    #	touch /var/log/${i}
    #done

    # Resta fazer só mais uma alteração. Para fazê-la, no entanto, precisamos sair do sistema de trabalho:

    #exit

    # A última alteração consiste em apagar o arquivo que contém o histórico dos comandos que
    # você executou nos passos anteriores. Não só não há necessidade de quem for usar o LiveCD saber desses
    # comandos como também o historico de comandos estar limpo causa a impressão de que o sistema nunca 
    # foi usado.

    # continando no sistema host

    log_info_msg "rm -f $WORK/root/.bash_history"
    rm -f $WORK/root/.bash_history 2> /dev/null
    evaluate_retval

    log_info_msg "umount -rl $WORKPTS"
    umount -rl "$WORKPTS" 2> /dev/null
    evaluate_retval

    log_info_msg "umount -rl $WORKDEV"
    umount -rl "$WORKDEV" 2> /dev/null
    evaluate_retval

    log_info_msg "umount -rl $WORKPROC"
    umount -rl "$WORKPROC" 2> /dev/null
    evaluate_retval

    log_info_msg "umount -rl $WORKSYS"
    umount -rl "$WORKSYS" 2> /dev/null
    evaluate_retval

    log_info_msg "umount -rl $WORKMEDIA"
    umount -rl "$WORKMEDIA" 2> /dev/null
    evaluate_retval

    log_info_msg "umount -rl $WORKTMP"
    umount -rl "$WORKTMP" 2> /dev/null
    evaluate_retval

    # A execução desses comandos é de extrema importância.

    log_info_msg "cp -vp $WORK/boot/vmlinuz-$(uname -r) $BASE/cd/boot/vmlinuz"
    cp -vp $WORK/boot/vmlinuz-$(uname -r) $BASE/cd/boot/vmlinuz 2> /dev/null
    evaluate_retval

    log_info_msg "cp -vp $WORK/boot/initrd.img-$(uname -r) $BASE/cd/boot/initrd.gz"
    cp -vp $WORK/boot/initrd.img-$(uname -r) $BASE/cd/boot/initrd.gz 2> /dev/null
    evaluate_retval

    log_info_msg "cp -vp $WORK/boot/memtest86+.bin $BASE/cd/boot/memtest"
    cp -vp $WORK/boot/memtest86+.bin $BASE/cd/boot/memtest 2> /dev/null
    evaluate_retval

    log_info_msg "Copiando syslinux.bin"
    find /boot -iname 'isolinux.bin' -exec cp -v {} $ISOLINUX \;
    evaluate_retval

    if [ $? != "0" ]; then
        find /usr/lib/syslinux/ -iname 'isolinux.bin' -exec cp -v {} $ISOLINUX \;
        evaluate_retval
    fi

    log_info_msg "Copiando vesamenu.c32"
    find /boot -iname 'vesamenu.c32' -exec cp -v {} $ISOLINUX \;
    evaluate_retval
    if [ $? != "0" ]; then
        find /usr/lib/syslinux/ -iname 'vesamenu.c32' -exec cp -v {} $ISOLINUX \;
        evaluate_retval
    fi

    log_info_msg "Copiando menu.c32"
    find /boot -iname 'menu.c32'     -exec cp -v {} $ISOLINUX \;
    evaluate_retval
    if [ $? != "0" ]; then
        find /usr/lib/syslinux/ -iname 'menu.c32'     -exec cp -v {} $ISOLINUX \;
        evaluate_retval
    fi

    log_info_msg "cat > $GRUB/menu.lst"
    cat > $GRUB/menu.lst << "_EOF_"
    # By default, boot the first entry.
    default 0

    # Boot automatically after 30 secs.
    timeout 30

    color cyan/blue white/blue

    title Start Linux in Graphical Mode
    kernel /boot/vmlinuz BOOT=live boot=live nopersistent rw quiet splash
    initrd /boot/initrd.gz

    title Start Linux in Safe Graphical Mode
    kernel /boot/vmlinuz BOOT=live boot=live xforcevesa rw quiet splash
    initrd /boot/initrd.gz

    title Start Linux in Text Mode
    kernel /boot/vmlinuz BOOT=live boot=live nopersistent textonly rw quiet
    initrd /boot/initrd.gz

    title Start Persistent Live CD
    kernel /boot/vmlinuz BOOT=live boot=live persistent rw quiet splash
    initrd /boot/initrd.gz

    title Start Linux Graphical Mode from RAM
    kernel /boot/vmlinuz BOOT=live boot=live toram nopersistent rw quiet splash
    initrd /boot/initrd.gz

    title Memory Test
    kernel /boot/memtest

    title Boot the First Hard Disk
    root (hd0)
    chainloader +1

_EOF_

    evaluate_retval

    log_info_msg "cat > $ISOLINUX/isolinux.cfg"
    cat > $ISOLINUX/isolinux.cfg << "_ISO_"
    #DEFAULT vesamenu.c32
    DEFAULT menu.c32
    TIMEOUT 300
    PROMPT 0

    LABEL live
      MENU LABEL ^Start LFS Linux in Graphical Mode
      KERNEL /boot/vmlinuz
      INITRD /boot/initrd.gz
      APPEND boot=live

    LABEL safe
      MENU LABEL Start Linux in Safe ^Graphical Mode
      KERNEL /boot/vmlinuz BOOT=live boot=live nopersistent textonly rw
      INITRD /boot/initrd.gz

    LABEL text_only
      MENU LABEL Start Linux in ^Text Mode
      KERNEL /boot/vmlinuz
      INITRD /boot/initrd.gz
      APPEND BOOT=live boot=live nopersistent textonly rw quiet

    LABEL persistent
      MENU LABEL Start ^Persistent Live CD
      KERNEL /boot/vmlinuz
      INITRD /boot/initrd.gz
      APPEND BOOT=live boot=live persistent rw quiet splash

    LABEL from_ram
      MENU LABEL Start Linux Graphical Mode from ^RAM
      KERNEL /boot/vmlinuz
      INITRD /boot/initrd.gz
      APPEND BOOT=live boot=live toram nopersistent rw quiet splash

    LABEL memtest
      MENU LABEL ^Memory test
      KERNEL /boot/memtest
      APPEND -

    LABEL hd
      MENU LABEL Boot from first ^hard disk
      LOCALBOOT 0x80
      APPEND -

_ISO_

    evaluate_retval

    echo -e ""
    maxcol; replicate "=" $?
    log_info_msg "Iniciando a criacao do filesystem SQUASHFS"
    evaluate_retval

    log_info_msg "mksquashfs $WORK $LIVE/filesystem.squashfs"
    mksquashfs $WORK $LIVE/filesystem.squashfs -noappend
    evaluate_retval

    log_info_msg "cd $BASE/cd && find . -type f -print0 | xargs -0 md5sum | tee $BASE/cd/md5sum.txt"
    cd $BASE/cd && find . -type f -print0 | xargs -0 md5sum | tee $BASE/cd/md5sum.txt
    evaluate_retval

    log_info_msg "cd $BASE/cd"
    cd $BASE/cd
    evaluate_retval

    echo -e ""
    maxcol; replicate "=" $?
    log_info_msg "Iniciando a criacao da ISO"
    evaluate_retval

    log_info_msg "mkisofs"
    mkisofs	-b boot/isolinux/isolinux.bin 		\
    		-c boot/isolinux/boot.cat 			\
    		-no-emul-boot 						\
    		-boot-info-table 					\
    		-V $label	 						\
    		-cache-inodes -r -J -l -v			\
    		-o "$XHOME"/live-cd.iso 			\
    		/home/vcatafesta/$distro-live/cd
    evaluate_retval
}
clear
echo -e ""
maxcol; replicate "=" $?
log_info_msg "Iniciando a criacao da ISO LIVE"
evaluate_retval
maxcol; replicate "=" $?
sh_main

