#!/bin/bash
declare -r version="v1.2.58-20190309"
#################################################################
#       install dialog Mazon OS - $version                      #
#								                                #
#      @utor: Diego Sarzi	    <diegosarzi@gmail.com>          #
#             Vilmar Catafesta 	<vcatafesta@gmail.com>	    	#
#      created: 2019/02/15	    licence: MIT		            #
#      altered: 2019/02/17-25	licence: MIT			        #
#################################################################

#. /lib/lsb/init-functions

# flag dialog exit status codes
: ${D_OK=0}
: ${D_CANCEL=1}
: ${D_HELP=2}
: ${D_EXTRA=3}
: ${D_ITEM_HELP=4}
: ${D_ESC=255}

#hex codigo
barra=$'\x5c'

# sfdisk type
nEFI=1
nBIOS=4
nSWAP=19
nLINUX=20

trancarstderr=2>&-
true=0
TRUE=0
OK=0
ok=0
NOK=1
nok=1
FALSE=1
false=1
falso=1
CANCEL=1
ESC=255
HEIGHT=0
WIDTH=0

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

# flag para disco/particao/formatacao/montagem
: ${LDISK=0}
: ${LPARTITION=0}
: ${LFORMAT=0}
: ${LMOUNT=0}
: ${TARSUCCESS=$false}
: ${STANDALONE=$false}
: ${STARTXFCE4=$true}
: ${xUUIDSWAP=""}
: ${xPARTSWAP=""}
: ${xPARTEFI=""}
: ${lEFI=$false}
: ${LAUTOMATICA=$false}
: ${xLABEL="MAZONOS"}

# usuario/senha/hostmame/group
: ${cuser=""}
: ${cpass=""}
: ${chost="mazonos"}
: ${cgroups="audio,video,netdev"}

# vars
declare -i ok=$true
declare -i grafico=$true
declare -r cshell="/bin/bash"
declare -r calias="mazonos"
declare -r cnick="mazon"
declare -r chome="/home"
declare -r capp="install-mazon"
declare -r cdistro="MazonOS"
declare -r ccabec="$cdistro Linux installer $version"
declare -r ctitle="$cdistro Linux"
declare -r welcome="Welcome to the $ccabec"
declare -r site="$chost.com"
declare -r xemail="root@mazonos.com"
declare -r dir_install="/mnt/$chost"
declare -r url_distro="http://$site/releases/"
declare -r pwd=$PWD
declare -r cfstab=$dir_install"/etc/fstab"
: ${tarball_min=$cnick"_minimal-0.3.tar.xz"}
: ${sha256_min=$cnick"_minimal-0.3.tar.xz.sha256sum"}
: ${tarball_full=$cnick"_beta-1.3.tar.xz"}
: ${sha256_full=$cnick"_beta-1.3.tar.xz.sha256sum"}
: ${FULLINST=$true}
: ${tarball_default=$tarball_full}
: ${sha256_default=$sha256_full}

declare -r wiki=$(cat << _WIKI
Wiki
There are two ways to install, with the install-mazon.sh (dep dialog) script or the manual form as follows:

Pre Requirements:
- Download MazonOS Linux
- An existing Linux distribution or a linux livecd.
- Create root partition using cfdisk or gparted (ext4) and DOS table / - min 20GB

Format partition:
# mkfs.ext4 /dev/sdx(x)
Mount partition in /mnt
# mount /dev/sdx(x) /mnt

Unzip the mazonos file in /mnt:
# tar -xJpvf /xxx/xxx/mazonos.tar.xz -C /mnt

Go to /mnt directory:
# cd /mnt

Mount proc/ dev/ sys and chroot to /mnt:
# mount --type proc /proc proc/
# mount --rbind /dev dev/
# mount --rbind /sys sys/
# mount --rbind /run run/
# chroot /mnt

Once in chroot, let's change the fstab file in /etc/fstab, using vim or nano.

Add your root partition (replace (x)) and save the file.
In case you don't remember which is the root partition, use fdisk -l to see it.
/dev/sdx(x) / ext4 defaults 1 1
- ( BOOT USING MAZONOS GRUB )
- Install grub to your disk:
# grub-install /dev/sd(x)
- Create grub.cfg:
# grub-mkconfig -o /boot/grub/grub.cfg
- Exit chroot and unmount the partitions:
# exit
# umount -Rl /mnt
- Reboot your system and enjoy MazonOS.

- ( DUAL BOOT USING EXISTING GRUB )
- If you want to do a dual boot with your existing system with a working grub, exit
  the chroot with "exit" command and unmount the partitions with:
# exit
# umount -Rl /mnt
# update-grub
- Reboot your system and enjoy MazonOS.

After installing and logging in a login system: root password: root, add a user with:
# useradd -m -G audio,video,netdev username
Add a password with:
# passwd username
# exit

Log in to the system with your new user and password, startx to start.
_WIKI
)

# lib functions script
function police(){
    echo "................_@@@__"
    echo "..... ___//___?____\________"
    echo "...../--o--POLICE------@} ...."
}

function inkey(){
    #read -rsp $'Press enter to continue...\n'
    #read -rsp $'Press escape to continue...\n' -d $'\e'
    #read -rsp $'Press any key to continue...\n' -n 1 key
    # echo $key
    #read -rp $'Are you sure (Y/n) : ' -ei $'Y' key;
    # echo $key
    #read -rsp $'Press any key or wait 5 seconds to continue...\n' -n 1 -t 5;
    #read -rst 0.5; timeout=$?
    # echo $timeout
    #read -rsp $'' -n 1 -t 5;
    #read -n1 -r -p "" lastkey ; timeout=$?
    read -t "$1" -n1 -r -p "" lastkey
}

function sh_partitions(){
    array=($(fdisk -l $sd           \
    | grep "$sd[0-9]"               \
    | awk '{print $1,$5,$6,$7}'     \
    | sed 's/ /_/'g                 \
    | sed 's/.//10'                 \
    | sed 's/./& /9'))
}

function arraylen(){
    #arraylength=${#array[@]}
    arraylength=${#"$1"[@]}
}

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


function confirma(){
    [ "$1" -ne 0 ] && { conf "INFO" "$2"; return $?;}
}

function msg(){
    if [ $grafico -eq $true ]; then
        dialog              \
        --no-collapse       \
        --title     "$1"    \
        --infobox   "\n$2"  \
        6 60
    else
        log_info_msg "$2"
    fi

}

function mensagem(){
    dialog                  \
   	--title 	"$ctitle"   \
	--backtitle	"$ccabec"   \
	--infobox 	"$*"        \
    6 60
}

function tolower(){
	$1 | tr 'A-Z' 'a-z'
}

function toloupper(){
	$1 | tr 'a-z' 'Z-A'
}

function display_result() {
	local xbacktitle=$ccabec

	if [ "$3" != "" ] ; then
		xbacktitle="$3"
	fi

	dialog 	--title 	"$2"			\
            --beep                      \
    		--no-collapse				\
            --no-cr-wrap                \
			--backtitle	"$xbacktitle"	\
    		--msgbox 	"$1" 			\
			25 80
}

function alerta(){
	dialog 								        \
			--title 	"$1" 			        \
			--backtitle	"$ccabec"		        \
			--msgbox 	"$2\n$3\n$4\n$5\n$6"  \
			10 60
}

function info(){
	dialog 			 					\
            --beep                      \
    		--no-collapse				\
            --no-cr-wrap                \
			--title 	"$cmsg002"		\
			--backtitle	"$ccabec"		\
			--msgbox 	"$*" 			\
			10 60
}

function conf(){
    dialog								\
			--title 	"$1" 			\
			--backtitle	"$ccabec"		\
			--yes-label "$yeslabel"		\
			--no-label  "$nolabel"		\
			--yesno 	"$2" 			\
			10 100
			return $?
}

function confmulti(){
    dialog								\
			--title 	"$1" 			\
			--backtitle	"$ccabec"		\
			--yes-label "$yeslabel"		\
			--no-label  "$nolabel"		\
			--yesno 	"$*" 			\
			10 100
			return $?
}

function inkey(){
    dialog								\
			--title 	"$2" 			\
			--backtitle	"$ccabec"		\
			--pause 	"$2" 			\
			0 0 "$1"
}

function quit(){
	[ $? -ne 0 ] && { clear ; exit ;}
}

# functions script

function sh_choosepackage(){
    pkt=($(cat index.html \
        | grep .xz.sha256sum \
        | awk '{print $2}' \
        | sed 's/<a href=\"//g' \
        | cut -d'"' -f3 | sed 's/>//g' \
        | sed 's/<\/a//g' \
        | sed 's/.sha256sum//g'))

    if echo "${pkt[0]}" | grep 'minimal' >/dev/null
    then
		tarball_min="${pkt[0]}"
		sha256_min="${pkt[0]}.sha256sum"
		tarball_full="${pkt[1]}"
		sha256_full="${pkt[1]}.sha256sum"
    else
		tarball_min="${pkt[1]}"
		sha256_min="${pkt[1]}.sha256sum"
		tarball_full="${pkt[0]}"
		sha256_full="${pkt[0]}.sha256sum"
    fi
    sh_delpackageindex
	return 0
}


function sh_delpackageindex(){
    ret=`log_info_msg "$cmsgdelpackageindex"`
    msg "INFO" "$ret"
    rm -f index.html* > /dev/null 2>&1
    evaluate_retval
    return $?

}

function sh_wgetpackageindex(){
    ret=`log_info_msg "$cmsg_wget_package_index"`
    msg "INFO" "$ret"
    wget $url_distro > /dev/null 2>&1
    evaluate_retval
    return $?
}

function sh_testarota(){
    cinfo=`log_info_msg "$cmsgtestarota"`
    msg "INFO" "$cinfo"
    ping -c 2 $site > /dev/null 2>&1
    evaluate_retval
    return $?
}

function sh_delsha256sum(){
    cinfo=`log_info_msg "$cmsgdelsha256"`
	msg "INFO" "$info"
    rm -f $sha256_default* > /dev/null 2>&1
    evaluate_retval
    return $?
}

function sh_wgetsha256sum(){
	sh_delsha256sum
	clinksha=$url_distro$sha256_default
    ret=`log_info_msg "$cmsggetshasum"`
    msg "INFO" "$ret"
    wget -q $clinksha > /dev/null 2>&1
    evaluate_retval
    return $?
}

function sh_deltarball(){
    cinfo=`log_info_msg "$cmsgdeltarball"`
    msg "INFO" "$info"
    rm -f $tarball_default* > /dev/null 2>&1
    evaluate_retval
    return $?
}

function sh_testsha256sum(){
    cinfo=`log_info_msg "$cmsgtestsha256sum"`
    msg "INFO" "$cinfo"
    #result=`sha256sum -c $sha256_default`
    sha256sum -c $sha256_default > /dev/null 2>&1
    evaluate_retval
    return $?
}

function sh_confhost(){
	cinfo=`log_info_msg "$cmsgaddhost"`
    msg "INFO" "$cinfo"
	if [ "$chost" != "$calias" ]; then
		echo $chost > $dir_install/etc/hostname
	    return $?
	fi
}

function sh_adduser(){
	if [ "$cuser" != " " ]; then
		if [ $FULLINST = $false ]; then
			cgroups="audio,video"
		fi

		if [ $LMOUNT -eq 0 ]; then
			sh_mountpartition
		fi

		sh_initbind
		cinfo=`log_info_msg "$cmsgadduser"`
	    msg "INFO" "$cinfo"
	    chroot . /bin/bash -c "useradd -m -G $cgroups $cuser -p $cpass > /dev/null 2>&1"
	    chroot . /bin/bash -c "(echo $cuser:$cpass) | chpasswd -m > /dev/null 2>&1"
	    evaluate_retval
		sh_confhost
	fi
}

function sh_confadduser(){
	# open fd
	exec 3>&1
	dialog 															\
			--separate-widget	$'\n'								\
			--cancel-label 		"$buttonback"						\
			--backtitle 		"$cmsgusermanager"					\
			--title 			"USERADD" 							\
			--form 				"$ccreatenewuser"					\
	12 50 0 														\
		"Username : " 1 1 "$cuser"        1 13 10 0 				\
		"Password : " 2 1 "$cpass"        2 13 20 0 				\
		"Hostname : " 3 1 "$chost"        3 13 20 0					\
	2>&1 1>&3 | {
		read -r cuser
		read -r cpass
		read -r chost

		sh_adduser
	}

	# close fd
	exec 3>&-
}

function sh_confstartx(){
	if [ $FULLINST = $true ]; then
		if [ $STARTXFCE4 = $true ]; then
			echo "ck-launch-session dbus-launch --exit-with-session startxfce4" > $dir_install/etc/skel/.xinitrc
		else
			echo "ck-launch-session dbus-launch --exit-with-session i3" > $dir_install/etc/skel/.xinitrc
		fi
	fi
}

function sh_tailexectar(){
    {
	    tar xJpvf $pwd/$tarball_default -C $dir_install
        nret=$?
    } > out &
    dialog  --title "**TAR**"                   \
        --begin 10 10 --tailboxbg out 25 120    \
        --and-widget                            \
        --begin 3 10 --msgbox "Exit" 5 30
    return $nret
}

function sh_pvexectar(){
    (pv -n $pwd/$tarball_default													\
    |tar xJpf - -C $dir_install ) 2>&1 												\
    |dialog	--title "** TAR **" --backtitle "$ccabec" --gauge "\n$cmsg_extracting" 	\
    7 60
}


function sh_exectar(){
	local nret
  	cd $dir_install

    if [ $grafico -eq $true ]; then
	    test -e /usr/bin/pv
	    if [ $? = $false ] ; then
            sh_tailexectar
            nret=$?
    	else
            sh_pvexectar
            nret=$?
    	fi
    else
        sh_tailexectar
        nret=$?
	fi
	if [ $ret <> $true ]; then
	    alerta "*** TAR *** " "$cmsgerrotar!"
		TARSUCCESS=$false
		return $TARSUCCESS
	fi
	sh_confstartx
	TARSUCCESS=$true
	return $TARSUCCESS
}

function sh_initbind(){
    local xproc="--type proc /proc $dir_install/proc/"
	local xsys="--rbind /sys $dir_install/sys/"
    local xdev="--rbind /dev $dir_install/dev/"
    local xrun="--rbind /run $dir_install/run/"
    local lproc=$false
    local lsys=$false
    local ldev=$false
    local lrun=$false

	cd $dir_install
	mkdir -p $dir_install/home > /dev/null 2>&1
	mkdir -p $dir_install/proc > /dev/null 2>&1
	mkdir -p $dir_install/sys > /dev/null 2>&1
	mkdir -p $dir_install/dev > /dev/null 2>&1
	mkdir -p $dir_install/run > /dev/null 2>&1
	mkdir -p $dir_install/boot/EFI > /dev/null 2>&1

   	mensagem "mount $xproc"
   	mount $xproc > /dev/null 2>&1
    lresultbind=$true
    if [ $? = 0 ] ; then lproc="OK"; else lproc="FAIL" lresultbind=$false; fi

	mensagem "mount $xsys"
	mount $xsys > /dev/null 2>&1
    if [ $? = 0 ] ; then lsys="OK"; else lsys="FAIL" lresultbind=$false; fi

    mensagem "mount $xdev"
    mount $xdev > /dev/null 2>&1
    if [ $? = 0 ] ; then ldev="OK"; else ldev="FAIL" lresultbind=$false; fi

    mensagem "mount $xrun"
    mount $xrun > /dev/null 2>&1
    if [ $? = 0 ] ; then lrun="OK"; else lrun="FAIL" lresultbind=$false; fi

    xstrbind="mount $xproc : $lproc    \
            \nmount $xsys : $lsys     \
            \nmount $xdev : $ldev     \
            \nmount $xrun : $lrun"
}


function sh_bind(){
    if [ $# -lt 1 ] ; then
    	if [ $STANDALONE = $true ]; then
    		conf "*** BIND ***" "\n$cinitbind?"
    		bindyes=$?
    		if [ $bindyes = $false ]; then
    		    alerta "*** BIND *** " "$cancelbind"
    			STANDALONE=$false
    			return $STANDALONE
        		fi
    	fi
   	fi

	if [ $LPARTITION -eq 0 ]; then
		choosepartition
		if [ $LPARTITION -eq 0 ]; then
			info "\n$cancelinst"
			return 1
		fi
	fi

	if [ $LMOUNT -eq 0 ]; then
		sh_mountpartition
	fi

    xstrbind=""
    lresultbind=$false
	sh_initbind
    if [ $lresultbind = $true ]; then
         cmsgbindresult="BIND OK"
    else cmsgbindresult="BIND FAIL"; fi

    if [ $# -lt 1 ] ; then
    	if [ $STANDALONE = $true ]; then
            alerta "*** BIND ***" "$xstrbind" "\n$cmsgbindresult";
    		STANDALONE=$false
    	fi
	fi
}

function sh_efi(){
	local result=$(fdisk $sd -l | grep EFI | cut -c1-11)
	xPARTEFI=$result
    lEFI=$false

	if [ "$result" != "" ] ; then
        lEFI=$true
	fi
}

function grubinstall(){
	if [ $LAUTOMATICA = $false ]; then
    	conf "*** GRUB ***" "$cGrubMsgInstall"
    	grubyes=$?
    	LDISK=0
    else
        grubyes=0
        LDISK=1
    fi
	if [ $grubyes = $true ]; then
		if [ $LDISK -eq 0 ]; then
			choosedisk "GRUB"
			if [ $LDISK -eq 0 ]; then
				info "\n$ccancelgrub"
				return 1
			fi
		fi

		if [ $LPARTITION -eq 0 ]; then
			choosepartition "grub"
			if [ $LDISK -eq 0 ]; then
				info "\n$ccancelgrub"
				return 1
			fi
		fi
		sh_bind $true
		mensagem "$cmsgwaitgrub: \n\n$sd"
        sh_efi

        if [ $lEFI = $true ]; then
            local nChoiceEFI=$true
        	if [ $LAUTOMATICA = $false ]; then
                conf "** EFI **"                                \
                    "$cmsg_Detectada_particao_EFI: $xPARTEFI    \
                    \n$cmsg_Deseja_instalar_o_GRUB_EFI?         \
                    \n\n$cmsg_Sim_EFI \n$cmsg_Nao_MBR"
                nChoiceEFI=$?
            fi
            if [ $nChoiceEFI = $true ] ; then
                cinfo=`log_info_msg "$cmsg_Desmontando_particao: $sd"`
                msg "INFO" "$cinfo"
                umount -f -rl $xPARTEFI 2> /dev/null
                evaluate_retval

                cinfo=`log_info_msg "$cmsg_Formatando_particao: $sd"`
                msg "INFO" "$cinfo"
                mkfs.fat -F32 $xPARTEFI 2> /dev/null
                evaluate_retval

                cinfo=`log_info_msg "$cmsg_Montando_particao: $sd"`
                msg "INFO" "$cinfo"
    	        mount $xPARTEFI $dir_install/boot/EFI 2> /dev/null
                evaluate_retval

                cinfo=`log_info_msg "$cmsg_Instalando_GRUB_EFI_na_particao: $sd"`
                msg "INFO" "$cinfo"
            	chroot . /bin/bash -c "grub-install                 \
                                        --target=x86_64-efi         \
                                        --efi-directory=/boot/EFI   \
                                        --bootloader-id=mazon       \
                                        --recheck">/dev/null 2>&1
                evaluate_retval
            else
                cinfo=`log_info_msg "$cmsg_install_grub_disk: $sd"`
                msg "INFO" "$cinfo"
                chroot . /bin/bash -c "grub-install $sd" > /dev/null 2>&1
                evaluate_retval
            fi
         else
            cinfo=`log_info_msg "$cmsg_install_grub_disk: $sd"`
            msg "INFO" "$cinfo"
            chroot . /bin/bash -c "grub-install $sd" > /dev/null 2>&1
            evaluate_retval
        fi
	    chroot . /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg" > /dev/null 2>&1
        echo "set menu_color_normal=green/black"  >> $dir_install/boot/grub/grub.cfg 2> /dev/null
        echo "set menu_color_highlight=white/red" >> $dir_install/boot/grub/grub.cfg 2> /dev/null
    	if [ $LAUTOMATICA = $false ]; then
    	    alerta "*** GRUB *** " "$sd" "\n\n$cgrubsuccess"
        fi
	else
		info "\n$ccancelgrub"
	fi

	if [ $STANDALONE = $false ]; then
		sh_finish
	fi
	#sh_umountpartition
}

function sh_fstab(){
    cinfo=`log_info_msg "$cmsgAlterar_FSTAB"`
    msg "INFO" "$cinfo"
	if [ $LAUTOMATICA = $false ]; then
    	if [ $STANDALONE = $true ]; then
    		conf "*** FSTAB ***" "\n$cmsgAlterar_FSTAB?"
    		fstabyes=$?
    		if [ $fstabyes = $false ]; then
    			STANDALONE=$false
    			return $STANDALONE
    		fi
    	fi
    	if [ $LPARTITION -eq 0 ]; then
	    	choosepartition
    		if [ $LPARTITION -eq 0 ]; then
    			info "\n$cancelinst"
    			return 1
    		fi
    	fi
    	if [ $LMOUNT -eq 0 ]; then
    		sh_mountpartition
    	fi
    fi

	mkdir -p $dir_install/etc >/dev/null
	xuuid=$(blkid | grep $part | awk '{print $3}')
	label="/            ext4     defaults            1     1"
	sed -ir "/<xxx>/ i $xuuid $label" $cfstab
	sed -i 's|/dev/<xxx>|#'$part'|g' $cfstab

	if [ $xUUIDSWAP != "" ]; then
		label="swap         swap     pri=1               0     0"
		sed -ir "/<yyy>/ i $xUUIDSWAP $label" $cfstab
		sed -i 's|/dev/<yyy>|'$xPARTSWAP'|g' $cfstab
	fi

	if [ $STANDALONE = $true ]; then
		nano $cfstab
		local result=$( cat $cfstab )
		display_result "$result" "$cfstab"
		STANDALONE=$false
	else
    	if [ $LAUTOMATICA = $false ]; then
	    	local result=$( cat $cfstab )
    		display_result "$result" "$cfstab"
	    	STANDALONE=$false
        fi
	fi
}

function sh_finish(){
	alerta "*** INSTALL ***" "$cfinish"
    clear
	exit 0
}

function sh_wgettarball(){
	local URL=$url_distro$tarball_default

	wget -c $URL 2>&1 														\
	| stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' 	\
	| dialog --title "$plswait" --backtitle "$ccabec" --gauge "\n\n$URL" 9 70
	return $?
}

function sh_wgetdefault(){
	sh_testarota
	if [ $? = $false ]; then
		info "\n$cmsgnoroute"
		menuinstall
	fi
	sh_delpackageindex
	sh_wgetpackageindex
    sh_choosepackage

	if [ $FULLINST = $true ]; then
		tarball_default=$tarball_full
		sha256_default=$sha256_full
	else
		tarball_default=$tarball_min
		sha256_default=$sha256_min
	fi

	local URL=$url_distro$tarball_default
	local clinksha=$url_distro$sha256_default
	local sumtest=$false

	test -e $tarball_default
	local nfound=$?

	if [ $nfound = $true ]; then
		test -e $clinksha
		if [ $? = $true ]; then
			sh_testsha256sum
			if [ $? = $false ]; then
				sh_testarota
				if [ $? = $false ]; then
					info "\n$cmsgnoroute"
					menuinstall
				fi
				sh_wgetsha256sum
				if [ $? = $false ]; then
					info "\n$cmsgerrodlsha1 $clinksha!\n$cmsgerrodlsha2"
					menuinstall
				fi
			fi
			sumtest=$true
		else
			sh_testarota
			if [ $? = $false ]; then
				info "\n$cmsgnoroute"
				menuinstall
			fi

			sh_wgetsha256sum
			if [ $? = $false ]; then
				info "\n$cmsgerrodlsha1 $clinksha!\n$cmsgerrodlsha2"
				menuinstall
			fi

			sh_testsha256sum
			if [ $? = $false ]; then
				confmulti "*** SHA256 ***" "\n$tarball_default" "\n\n$cmsgcorrdlnew"
				if [ $? = $false ]; then
					menuinstall
				else
					#sh_deltarball
					sh_wgettarball
					sh_wgetsha256sum
					sh_testsha256sum
					if [ $? = $false ]; then
						info "\n$cmsg_corr_rep"
						menuinstall
					fi
				fi
			fi
			sumtest=$true
		fi
	else
		sh_testarota
		if [ $? = $false ]; then
			info "\n$cmsgnoroute"
			menuinstall
		fi
	fi

	if [ $sumtest = $false ]; then
        if [ $LAUTOMATICA = $true ]; then
    		sh_wgetsha256sum
			sh_wgettarball
			sh_testsha256sum
        else
    		conf "$cmsgBaixar_pacote_de_instalacao" "\n$cmsgversion"
    		local nchoice=$?
    		case $nchoice in
    			$D_OK)
    				#wget -c $URL;;
    				sh_wgetsha256sum
    				sh_wgettarball
    				sh_testsha256sum
    				if [ $? = $false ]; then
        				confmulti "*** SHA256 ***" "\n$tarball_default" "\n\n$cmsgcorrdlnew"
    					if [ $? = $false ]; then
    						menuinstall
    					else
    						#sh_deltarball
    						sh_wgettarball
    						sh_wgetsha256sum
    						sh_testsha256sum
    						if [ $? = $false ]; then
    							info "\n$cmsg_corr_rep"
    							menuinstall
    						fi
    					fi
    				fi
    				;;

    			$D_CANCEL)
    				info $cmsg017
    				menuinstall;;
    		esac
        fi
	fi

    if [ $LAUTOMATICA = $false ]; then
        confmulti "$cdlok1" "$cdlok2" "\n[OK] $tarball_default $cdlok3" "$cshaok" "$cdlok4"
       	local ninit=$?
   		case $ninit in
    		$D_OK)
	    		sh_check_install
   				;;

    		$D_CANCEL)
   				info "\n$cancelinst"
   				menuinstall
    			;;
   		esac
   	else
  		sh_check_install
   	fi
}

function sh_check_install(){
	if [ $LDISK -eq 0 ]; then
		choosedisk
	fi
	if [ $LPARTITION -eq 0 ]; then
		choosepartition
		if [ $LPARTITION -eq 0 ]; then
			info "\n$cancelinst"
			return 1
		fi
	fi
	if [ $LFORMAT -eq 0 ]; then
		sh_format
		if [ $? = $false ]; then
			LPARTITION=0
			menuinstall
		fi
	fi

	if [ $LMOUNT -eq 0 ]; then
		sh_mountpartition
	fi

	if [ $LAUTOMATICA = $false ]; then
    	confmulti "** INSTALL ** " "\n Mount : $dir_install" "\n  Part : $part" "\n\n$cmsg_all_ready"
    	local nOk=$?
    	case $nOk in
    		$D_ESC)
    			info "\n$cancelinst"
    			menuinstall
    			;;
    		$D_CANCEL)
    			info "\n$cancelinst"
    			menuinstall
    			;;
    	esac
    fi

	sh_exectar
	if [ $? = 1 ]; then
		conf "*** ERRO ***" "$cmsg_erro_tar_continue"
		local nOk1=$?
		case $nOk1 in
		$D_ESC)
			info "\n$cancelinst"
			menuinstall
			;;
		$D_CANCEL)
			info "\n$cancelinst"
			menuinstall
			;;
		esac
	fi
    sh_fstab
	sh_initbind

	if [ $LAUTOMATICA = $false ]; then
    	conf "*** ADDUSER ***" "\n$cconfusernow?"
    	if [ $? = $true ]; then
    		sh_confadduser
    	fi
    fi
	grubinstall
}

function menuinstall(){
	while true
	do
    	resposta=$( dialog												\
		--stdout														\
        --title 		"$cmsgPacotes_disponiveis"						\
		--backtitle 	"$ccabec"										\
		--cancel-label	"$buttonback"									\
		--menu			"\n$cmsg004"									\
		0 70 0															\
	   	FULL			"$cmsgfull"										\
		MINIMAL			"$cmsgmin"										)
#		custom			'Choose softwares. (GIMP, QT5, LIBREOFFICE...)'

		exit_status=$?
		case $exit_status in
			$ESC)
                if [ $LAUTOMATICA = $true ]; then
                    return 1
                fi
				scrmain
				;;
			$CANCEL)
                if [ $LAUTOMATICA = $true ]; then
                    return 1
                fi
				scrmain
				;;
		esac

		case "$resposta" in
		FULL)
			resfull=$(dialog									\
			--stdout											\
			--backtitle 	"$ccabec"							\
			--cancel-label	"$buttonback"						\
			--title			'FULL INSTALATION'					\
			--menu			"$cchooseX:"						\
			0 0 0                               		    	\
			XFCE4			"$cxfce4"							\
			i3WM			"$ci3wm"							)

			exit_status=$?
			case $exit_status in
				$ESC)
                    if [ $LAUTOMATICA = $true ]; then
                        return 1
                    fi
					loop
					;;
				$CANCEL)
                    if [ $LAUTOMATICA = $true ]; then
                        return 1
                    fi
					loop
					;;
			esac

			case "$resfull" in
				# TROCAR POR /MNT *********************
			XFCE4)
				FULLINST=$true
				STARTXFCE4=$true
				cmsgversion=$cmsg016
                if [ $LAUTOMATICA = $true ]; then
                    return 0
                fi
				sh_wgetdefault
				break
				;;

			i3WM)
				FULLINST=$true
				STARTXFCE4=$false
				cmsgversion=$cmsg016
                if [ $LAUTOMATICA = $true ]; then
                    return 0
                fi
				sh_wgetdefault
				break
				;;
			esac
			;;

		MINIMAL)
			FULLINST=$false
			cmsgversion=$cmsg015
            if [ $LAUTOMATICA = $true ]; then
                return 0
            fi
			sh_wgetdefault
			;;

		custom)
			rescustom=$(dialog --stdout                 					\
            --separate-output                       						\
            --checklist 'Choose install softwares:' 						\
            0 0 0                                   						\
			LIBREOFFICE  			'Office suite free' 				OFF	\
			GIMP 		 			'GNU Image Manipulation Program' 	OFF	\
			INKSCAPE 	 			'Draw freely' 						OFF	\
			QT5 		 			'Framework' 						OFF \
			SUBLIME_TEXT 			'Text editor for code' 				OFF \
			VLC 		 			'Player video' 						OFF \
            OPENJDK 	 			'Open Java' 						OFF \
            TELEGRAM 	 			'Communicator' 						OFF	\
            SIMPLESCREENRECORDER	'Recorder desktop' 					OFF	)

			# create choose softwares vars
			libre= ; gimp= ; inkscape= ; qt5= ; sublime_text= ; vlc= ; openjdk= ; telegram=
			echo "$rescustom" | while read LINHA
          	do
				if [ $LINHA = "LIBREOFFICE" ]; then
					libre="--exclude-from=/tmp/libre.exclude"
				elif [ $LINHA = "GIMP" ]; then
					gimp="--exclude-from=/tmp/gimp.exclude"
				elif [ $LINHA = "INKSCAPE" ]; then
					inkscape="--exclude-from=/tmp/inkscape.exclude"
				elif [ $LINHA = "QT5" ]; then
					qt5="--exclude-from=/tmp/qt5.exclude"
				elif [ $LINHA = "SUBLIME_TEXT" ]; then
					sublime_text="--exclude-from=/tmp/sublime_text.exclude"
				elif [ $LINHA = "VLC" ]; then
					vlc="--exclude-from=/tmp/vlc.exclude"
				elif [ $LINHA = "OPENJDK" ]; then
					openjdk="--exclude-from=/tmp/openjdk.exclude"
				elif [ $LINHA = "TELEGRAM" ]; then
					telegram="--exclude-from=/tmp/telegram.exclude"
				elif [ $LINHA = "SIMPLESCREENRECORDER" ]; then
					ssr="--exclude-from=/tmp/ssr.exclude"
				fi
			done
           	;;
		esac
	done

	# grub install
	#######################
   	#grubinstall
	#sh_finish
}

function sh_checkdisk(){
	dsk=$(df -h | grep "$sd" | awk '{print $1, $2, $3, $4, $5, $6, $7}')
	#dsk=$(df | grep $sd | cut -c 1-})
	#dsk=$(df -h | grep ^$sd)
	#dsk=$(df -h | grep "$sd")

	local nchoice=0
	if [ "$dsk" <> " " ]; then
		conf "$cwarning" "\n$cmsg_all_mounted_part\n\n$dsk\n\n$cmsg_dismount"
		nchoice=$?
		if [ $nchoice = 0 ]; then
			for i in $(seq 1 10); do
				umount -f -rl $sd$i 2> /dev/null
			done
		fi
	fi
	return $nchoice
}

function sh_checksimple(){
	local sdsk=$(df -h | grep "$sd" | awk '{print $1, $2, $3, $4, $5, $6, $7}')

	local nchoice=0
	if [ "$sdsk" <> " " ]; then
		alerta "$cwarning" "\n$cmsg_alert_mount\n\n$sdsk"
	fi
	return $nchoice
}

function sh_checkpartition(){
	cpart=$(df -h | grep "$part" | awk '{print $1, $2, $3, $4, $5, $6, $7}')
	#dsk=$(df | grep $part | cut -c 1-})
	#dsk=$(df -h | grep ^$part)
	#dsk=$(df -h | grep "$part")

	local nchoice=0
	if [ "$cpart" <> " " ]; then
		conf "$cwarning" "\n$cmsg_conf_dismount\n\n$cpart\n\n$cmsg_dismount"
		nchoice=$?
		if [ $nchoice = $true ]; then
			umount -f -rl $part 2> /dev/null
			LMOUNT=0
		fi
	fi
	return $nchoice
}

function sh_partnewbie(){
    cinfo=`log_info_msg "$cmsg_prepare_disk $sd"`
    msg "INFO" "$cinfo"
    local xMEMSWAP=$(free | grep Mem | awk '{ print $2}')
	if [ $xMEMSWAP = "" ] ; then
		xMEMSWAP = "2G" ]
	fi
    sfdisk -f --delete $sd > /dev/null 2>&1
	echo "label: gpt" | sfdisk --force $sd > /dev/null 2>&1
	echo "size=400M, type=$nEFI" | sfdisk -a --force $sd > /dev/null 2>&1
	echo "size=1M, type=$nBIOS" | sfdisk -a --force $sd > /dev/null 2>&1
	echo "size=$xMEMSWAP, type=$nSWAP" | sfdisk -a --force $sd > /dev/null 2>&1
	echo ";" | sfdisk -a --force $sd > /dev/null 2>&1
    evaluate_retval
	LDISK=1
    if [ $LAUTOMATICA = $true ]; then
        part=$sd"4"
        LPARTITION=1
    fi
    return $?
}

function choosedisk(){
while true
do
	# escolha o disco a ser particionado // Choose disk to be parted
	################################################################
	#disks=( $(fdisk -l | egrep -o '^/dev/sd[a-z]'| sed "s/$/ '*' /") )
	#disks=( $(fdisk -l | cut -dk -f2 | grep -o /sd[a-z]))
	#disks=($(ls /dev/sd* | grep -o '/dev/sd[a-z]' | cat | sort | uniq | sed "s/$/ '*' /"))
	disks=($(fdisk -l | sed -n /sd[a-z]':'/p | awk '{print $2,$3$4}' | cut -d',' -f1 | sed 's/://g'|sort))
	LDISK=0
	local xmsg=$cdisco
	if [ $1 = "GRUB" ] ; then
		xmsg=$1
	fi
	sd=$(dialog 		 															\
				--title 		"$xmsg"								  				\
				--backtitle	 	"$ccabec"					 						\
				--cancel-label 	"$buttonback"										\
				--menu 			"\n$cmsg009" 0 50 0 "${disks[@]}" 2>&1 >/dev/tty 	)

	exit_status=$?
	case $exit_status in
		$ESC)
            if [ $LAUTOMATICA = $true ]; then
                return 1
            fi
			scrmain
			;;
		$CANCEL)
            if [ $LAUTOMATICA = $true ]; then
                return 1
            fi
			scrmain
			;;
	esac

	if [ $1 = "SEE" ] ; then
		local result=$( fdisk -l $sd )
		display_result "$result" "$csmg013" "$cmsg_part_disk"
		continue
	fi

	if [ $1 = "GRUB" ] ; then
		LDISK=1
		return 0
	fi

	if [ $sd <> 0 ]; then
        if [ $LAUTOMATICA = $true ]; then
            return 0
        fi
 		typefmt=$(dialog \
	    	--stdout 													\
	    	--title     	"$cmsg009" 									\
			--cancel-label	"$buttonback"								\
	    	--menu		 	"$cmsg010"		 							\
	    	0 0 0 														\
	    	"$cexpert"  	"$cmsg011"							 	 	\
	    	"$cnewbie"     	"$cmsg013"				   		     		)

			case "$typefmt" in
				$cexpert)
					sh_checksimple
					cfdisk $sd
					LDISK=1
					local result=$( fdisk -l $sd )
				    display_result "$result" "$cmsg011"
					;;

				$cnewbie)
					sh_checkdisk
					local nmontada=$?
					if [ $nmontada = 1 ]; then
						alerta "CHOOSEDISK" "$cmsg_nec_dismount"
						choosedisk
					fi
					conf "$cmsg020" "\n$cmsg020\n$cmsg014"
					local nb=$?
					case $nb in
						$D_OK)
                            sh_partnewbie
							local result=$( fdisk -l $sd )
						    display_result "$result" "$csmg013"
							;;
					esac
					;;
	    	esac
	fi
	break
done
}

function sh_umountpartition(){
	mensagem "$cmsg_umount_partition"
	umount -rl $part 2> /dev/null
	LMOUNT=0
	cd $pwd
	#menuinstall
}

function sh_mountpartition(){
	mensagem "$cmsg_create_dir"
	mkdir -p $dir_install 2> /dev/null
	mensagem "$cmsg_mount_partition"

	while true
	do
		umount -f -rl $part 2> /dev/null
		mount $part $dir_install 2> /dev/null
		if [ $? = 32 ]; then # monta?
			conf "** MOUNT **" "$cmsg_try_mount_partition"
            if [ $? = 0 ]; then
				#loop
				continue
			fi
           	LMOUNT=0
			break
		fi
		if [ $? = 1 ]; then # fail?
			conf "** MOUNT **" "$cmsg_mount_failed"
            if [ $? = 0 ]; then
				#loop
				continue
			fi
           	LMOUNT=0
			break
		fi
		break
	done
	LMOUNT=1
    if [ $LAUTOMATICA = $false ]; then
    	mensagem "$cmsg_enter_work_dir"
    fi
	cd $dir_install
}

function choosepartition(){
	# escolha a particao a ser instalada // Choose install partition
	################################################################
	#partitions=( $(blkid | cut -d: -f1 | sed "s/$/ '*' /") )
	#partitions=( $(ls $sd* | grep -o '/dev/sd[a-z][0-9]' | sed "s/$/ '*' /") )
	LPARTITION=0
	#partitions=( $(fdisk -l | cut -dk -f2 | grep -o /sd[a-z][0-9]))
   	#partitions=( $(fdisk -l $sd | sed -n /sd[a-z][0-9]/p | awk '{print $1,$5}'))
    #partitions=($(fdisk $sd -o Device,Type,Size|sed -n /sd[a-z][0-9]/'s/  /+/p'|sed 's/ /_/'g|sed 's/+/ /g'))
    #devices=($(fdisk -l -o Device|sed -n '/sd[a-z][0-9]/'p))
    #partitions=($(fdisk -l|sed -n '/sd[a-z][0-9]/'p|awk '{printf "%0s [%0s]__%0s_%0s\n", $1,$5,$7,$6}'))
    local array=()
    local n=0
    local y=0

    if [ $LDISK -eq 0 ]; then
        local typesize=($(fdisk -l -o device,type,size | sed -n '/sd[a-z][0-9]/'p | sed 's/ /_/g'|sort))
        local devices=($(fdisk -l -o Device|sed -n '/sd[a-z][0-9]/'p|sort))
        local partitions=($(fdisk -l|sed -n '/sd[a-z][0-9]/'p|awk '{printf "%0s [%0s]__%0s_%0s\n", $1,$5,$7,$6}'))
    else
        local typesize=($(fdisk -l $sd -o device,type,size | sed -n '/sd[a-z][0-9]/'p | sed 's/ /_/g'|sort))
        local devices=($(fdisk -l $sd -o Device|sed -n '/sd[a-z][0-9]/'p|sort))
        local partitions=($(fdisk -l $sd|sed -n '/sd[a-z][0-9]/'p|awk '{printf "%0s [%0s]__%0s_%0s\n", $1,$5,$7,$6}'))
    fi

    for i in ${devices[@]}
    do
        array[((n++))]=$i
        array[((n++))]=${typesize[((y++))]}
    done

	part=$(dialog 														\
			--title 		"$cparticao"					  			\
			--backtitle	 	"$ccabec"					 				\
			--cancel-label	"$buttonback"								\
			--menu 			"\n$cmsg007:"								\
			0 65 0 														\
			"${array[@]}" 2>&1 >/dev/tty 							    )

	exit_status=$?
	case $exit_status in
		$ESC)
			LPARTITION=0
			#scrend 1
			#exit 1
			scrmain
			;;
		$CANCEL)
			LPARTITION=0
			#scrend 0
			scrmain
			;;
	esac
	LPARTITION=1
	#sh_format
	#sh_mountpartition
}

function sh_mkswap(){
	local result=$(fdisk $sd -l | grep swap | cut -c1-11)
	xPARTSWAP=$result

	if [ "$result" != "" ] ; then
		xUUIDSWAP=$(mkswap $result | grep UUID | awk '{print $3 }')
	fi
}

function sh_domkfs(){
    # WARNING! FORMAT PARTITION
    #######################
    umount -rl $part 2> /dev/null
    mkfs -F -t ext4 -L "$xLABEL" $part > /dev/null 2>&1
    local nchoice=$?
    if [ $nchoice = $true ]; then
        LFORMAT=1
    else
        LFORMAT=0
    fi
    return $nchoice
}

function sh_format(){
	sh_checkpartition
    local nmontada=$?
	local format=1

	if [ $nmontada = 0 ] ; then
		LFORMAT=0
	    conf " *** FORMAT *** " "\n   $cmsg020 \n\n   $cmsg021 $part ?"
		format=$?
		if [ $format = 0 ] ; then
            do_mkfs
			local nfmt=$?
			if [ $nfmt = 0 ] ; then
				sh_mkswap
				alerta "MKFS" "$cmsg_mkfs_ok"
				LFORMAT=1
			else
				alerta "MKFS" "$cmsg_mkfs_error."
				LFORMAT=0
				return 1
			fi
		else
			LFORMAT=0
		fi
	fi
	return $format
}

function scrmain(){
	while true
	do
		sd=$(ls /dev/sd*)
		main=$(dialog 														\
				--stdout                                                  	\
				--backtitle 	"$ccabec"									\
				--title 		"$cmsg001"						  			\
				--cancel-label	"$buttonback"								\
		        --menu 			"\n\n$cmsg004" 	 							\
		        0 0 0                                 						\
		        1 "$cmsgBaixar_pacote_de_instalacao"						\
		        2 "$cmsg006"						  						\
		        3 "$cmsg007"												\
			   	4 "Install"	   					     						\
			   	5 "$ctools"							     					)

				exit_status=$?
				case $exit_status in
					$ESC)
						#scrend 1
						#exit 1
						init
						;;
					$CANCEL)
						#scrend 0
						init
						;;
				esac
		        case $main in
					1) menuinstall;;
					2) choosedisk;;
					3) choosepartition;;
					4) menuinstall;;
					5) sh_tools;;
				esac
	done
}

function pt_BR(){
	lang="pt_BR"
	buttonback="Voltar"
	cmsg000="Sair"
	cmsg001=$ccabec
	cmsg002=$ctitle
	cmsg003="Bem-vindo ao instalador do $cdistro"
	cmsg004="Escolha uma opção:"
	cmsgBaixar_pacote_de_instalacao="Baixar pacote de instalacao"
	cmsg006="Particionar Disco"
	cmsg007="Escolher partição para instalar"
	cmsg008="Sair do instalador"
	cmsgquit="Sair do instalador"
	cmsg009="Escolha o disco:"
	cmsg010="Escolha o tipo:"
	cmsg011="Particionamento manual usando cfdisk"
	cmsg012="Experiente"
	cexpert="Experiente"
	cnewbie="Novato"
	cmsg013="Particionamento automatico (sfdisk)"
	cmsg014="Tem certeza?"
	cmsg015="A versão mínima não inclui o Xorg e DE.\nVocê gostaria de baixar o $cdistro minimal?"
	cmsg016="Você gostaria de baixar o $cdistro full?"
	cmsg017='Download cancelado!'
	cancelinst="Instalacao cancelada!"
	cancelbind="Chroot cancelado!"
	cmsgversion=$cmsg015
	cmsg018="Baixar pacote full (X)"
	cmsg019="Baixar pacote minimal"
	cmsg020="** AVISO ** Todos os dados serão perdidos!"
	cmsg021="Formatar partição"
	menuquit="Sair"
	menustep="Passo a passo"
	yeslabel="Sim"
	nolabel="Não"
	cdlok1="*** DOWNLOAD *** "
	cdlok2="\n[OK] Download concluído com sucesso."
	cdlok3="encontrado."
	cdlok4="\n\nIniciar a instalação agora?"
	cshaok="\n[OK] Checksum verificado com sucesso."
    plswait="Por favor aguarde, baixando pacote..."
	cfinish="Instalação completa! Boas vibes.\nReboot para iniciar com $cdistro Linux.\n\nBugs? $xemail"
	cgrubsuccess="GRUB instalado com sucesso!"
	ccancelgrub="Instalação do GRUB cancelada!"
	cmsgInstalar_GRUB="Instalar GRUB"
	cmsgAlterar_FSTAB="Alterar FSTAB"
	cinitbind="Iniciar BIND"
	cconfuser="Configurar usuario e senha"
	cconfusernow="Configurar usuário e senha agora"
	ccreatenewuser="Criar um novo usuário"
	#cGrubMsgInstall="Você gostaria de instalar o GRUB? \
	#				\n\n*Lembrando que ainda não temos suporte a dual boot. \
	#				\nSe precisar de dual boot, use o grub de outra distribuição com:\n# update-grub"
	cGrubMsgInstall="Você gostaria de instalar o GRUB?"
	cchooseX="Escolha o seu ambiente de Desktop:"
	cxfce4="Clássico e poderoso!"
	ci3wm="Desktop para caras avançados B)."
	cmsgmin="Instalação mínima, sem X"
   	cmsgfull="Instalação completa. *8.2G de disco (Xfce4 ou i3wm)"
	cwgeterro0="Sem problemas"
	cwgeterro1="Erro genérico"
	cwgeterro2="Erro de parse"
	cwgeterro3="Erro de I/IO no arquivo"
	cwgeterro4="Falha na rede"
	cwgeterro5="Falha na verificação do certificado SSL"
	cwgeterro6="Falha na autenticação (usuário ou senha)"
	cwgeterro7="Erro de protocolo"
	cwgeterro8="Servidor enviou uma respostar de erro"
	cerrotar0="Sucesso"
	cerrotar1="Árvore de diretório ruim, não conseguiu extrair um arquivo solicitado, \
   			   \narquivo de entrada igual ao arquivo de saída, falha ao abrir o arquivo de entrada, \
			   \nnão foi possível criar um  link, tabela link  malloc  falhouSucesso"
	cerrotar2="Erro de internacionalização que nunca deveria ocorrer, erro de checksum"
	cerrotar5="Erro de checksum"
	cerrotar9="(EBADF) - Erro lendo /etc/default/tar, fim de volume mal colocado"
	cerrotar12="(ENOMEM) – falha na alocação de memória para buffer"
	cerrotar22="(EINVAL) – invocação ruim (erros de sintaxe do arqumento),\
                \nparâmetros ruins para opções(ENOMEM) – falha na alocação de memória para buffer"
	cerrotar28="(ENOSPC) – arquivo muito grande para um volume"
	cerrotar78="(ENAMETOOLONG) - cwd name muito longo"
	cerrotar171="(ETOAST) – unidade de fitas on fire"
	ctools="Ferramentas/Configurações"
	cmsgtestarota="Aguarde, testando rota para o servidor $cdistro..."
	cmsgdelsha256="Aguarde, excluindo SHA256SUM antigo..."
	cmsgusermanager="Gerenciamento de usuários $cdistro Linux"
	cmsgPacotes_disponiveis="Pacotes disponiveis"
    cmsggetshasum="Aguarde, baixando sha256sum novo..."
	cmsgdelpackageindex="Aguarde, excluindo indice antigo..."
    cmsgdeltarball="Aguarde, excluindo tarball antigo..."
    cmsgtestsha256sum="Aguarde, testando sha256sum"
	cmsgadduser="Aguarde, criando usuario..."
	cmsgaddhost="Aguarde, setando hostname..."
    cmsgerrotar="Erro na descompatacao do pacote"
	cmsgwaitgrub="Aguarde, instalando o GRUB no disco"
	cmsgnoroute="Ops, sem rota para o servidor da $cdistro!\nVerifique sua internet."
	cmsgerrodlsha1="Ops, erro no download de !\nVerifique sua internet."
	cmsgerrodlsha2="Verifique sua internet."
	cmsgcorrdlnew="Ops, Pacote ou SHA256 corrompido. \nBaixar novamente o pacote?"
	cmsg_corr_rep="Ops, Pacote ou SHA256 corrompido. \nFavor repetir a operação!"
	cmsg_erro_tar_continue="Erro na descompactação do pacote. \nDeseja ainda prosseguir?"
	cmsg_all_ready="Tudo pronto para iniciar a instalação. Confirma?"
    cmsg_wget_package_index="Aguarde, baixando indice dos pacotes..."
	cmsg_nec_dismount="Necessário desmontar particao para reparticionar automaticamente."
	cwarning="** AVISO **"
	cmsg_alert_mount="Só para lembrar que o disco contém partições montadas."
	cmsg_conf_dismount="A partição está montada."
	cmsg_dismount="Desmontar?"
	cmsg_all_mounted_part="O disco selecionado contém partições montadas."
	cmsg_umount_partition="Aguarde, Desmontando particao de trabalho."
	cmsg_create_dir="Aguarde, criando diretorio de trabalho."
	cmsg_mount_partition="Aguarde, Montando particao de trabalho."
	cmsg_try_mount_partition="Particao já montada. Tentar?"
	cmsg_mount_failed="Falha de montagem da partição. Repetir?"
	cmsg_enter_work_dir="Aguarde, Entrando no diretorio de trabalho."
	cmsg_mkfs_ok="Formatacao terminada com sucesso."
	cmsg_mkfs_error="Erro na Formatacao."
	cdisco="DISCO"
	cparticao="PARTIÇÃO"
	cmsg_extracting="Aguarde, extraindo arquivos..."
	cmsg_part_disk="Visualizar partições do disco"
    cmsg_prepare_disk="Aguarde, preparando o disco:"
    cmsg_install_grub_disk="Instalando GRUB no disco"
    cmsg_Detectada_particao_EFI="Detectada partição EFI"
    cmsg_Deseja_instalar_o_GRUB_EFI="Deseja instalar o GRUB EFI"
    cmsg_Sim_EFI="Sim=EFI"
    cmsg_Nao_MBR="Não=MBR"
    cmsg_Desmontando_particao="Desmontando partição"
    cmsg_Formatando_particao="Formatando partição"
    cmsg_Montando_particao="Montando partição"
    cmsg_Instalando_GRUB_EFI_na_particao="Instalando GRUB EFI na partição"
	cmsgInstalacao_Automatica="Instalacao Automatica"
    cmsgInstalacao_Automatica_cancelada="Instalacao Automatica cancelada"
    cmsgErro_na_formatacao="Erro na formatação"
    cmsgErro_no_particionamento="Erro no particionamento"
}

function en_US(){
	lang="en_US"
	buttonback="Back"
	cmsg000="Exit"
	cmsg001=$ccabec
	cmsg002=$ctitle
	cmsg003=$welcome
	cmsg004="Choose an option:"
	cmsgBaixar_pacote_de_instalacao="Download installation package"
	cmsg006="Partition Disk"
	cmsg007="Choose partition to install"
	cmsg008="Quit the installer"
	cmsgquit="Quit the installer"
	cmsg009="Choose the disk:"
	cmsg010="Choose type:"
	cmsg011="Manual partitioning using cfdisk"
	cmsg012="Expert"
	cexpert="Expert"
	cnewbie="Newbie"
	cmsg013="Automatic partitioning (sfdisk)"
	cmsg014="Are you sure?"
	cmsg015="The minimum version does not include Xorg and DE. \nWould you like to download $cdistro minimal?"
	cmsg016='Would you like to download $cdistro full?'
	cmsgversion=$cmsg015
	cmsg017='Download canceled!'
	cancelinst="Installation canceled!"
	cancelbind="Chroot canceled!"
	cmsg018="Download full package (X)"
	cmsg020="** NOTICE ** Will data will be lost!"
	cmsg021="Format partition"
	menuquit="Quit"
	menustep="Step by step"
	yeslabel="Yes"
	nolabel="No"
	cdlok1="*** DOWNLOAD ***"
	cdlok2="\n[OK] Download completed successfully."
	cdlok3="found."
	cdlok4="\n\nStart the installation now?"
	cshaok="\n[OK] Checksum successfully verified."
    plswait="Please wait, Downloading package..."
	cfinish="Install Complete! Good vibes. \nReboot to start with $cdistro Linux. \n\nBugs? $xemail"
	cgrubsuccess="GRUB successfully installed!"
	ccancelgrub="Installing grub canceled!"
	cmsgInstalar_GRUB="Install GRUB"
	cmsgAlterar_FSTAB="Change FSTAB"
	cinitbind="Start BIND"
	cconfuser="Configure user and password"
	cconfusernow="Configure user and password now"
	ccreatenewuser="Create a new user"
	#cGrubMsgInstall="Would you like to install grub? \
    #  				\n\n*Remembering that we do not yet have dual boot support. \
    #				\nIf use dualboot, use the grub from its other distribution with:\n# update-grub"
	cGrubMsgInstall="Would you like to install grub?"
	cchooseX="Choose your Desktop Environment:"
	cxfce4="Classic and powerfull!"
	ci3wm="Desktop for avanced guys B)."
	cmsgmin="Minimum installation, not X"
   	cmsgfull="Complete installation. *8.2G disk (Xfce4 or i3wm)"
	cwgeterro0="Sem problemas"
	cwgeterro1="Erro genérico"
	cwgeterro2="Erro de parse"
	cwgeterro3="Erro de I/IO no arquivo"
	cwgeterro4="Falha na rede"
	cwgeterro5="Falha na verificação do certificado SSL"
	cwgeterro6="Falha na autenticação (usuário ou senha)"
	cwgeterro7="Erro de protocolo"
	cwgeterro8="Servidor enviou uma respostar de erro"
	cerrotar0="Sucesso"
	cerrotar1="Árvore de diretório ruim, não conseguiu extrair um arquivo solicitado, \
   			   \narquivo de entrada igual ao arquivo de saída, falha ao abrir o arquivo de entrada, \
			   \nnão foi possível criar um  link, tabela link  malloc  falhouSucesso"
	cerrotar2="Erro de internacionalização que nunca deveria ocorrer, erro de checksum"
	cerrotar5="Erro de checksum"
	cerrotar9="(EBADF) - Erro lendo /etc/default/tar, fim de volume mal colocado"
	cerrotar12="(ENOMEM) – falha na alocação de memória para buffer"
	cerrotar22="(EINVAL) – invocação ruim (erros de sintaxe do arqumento),\
                \nparâmetros ruins para opções(ENOMEM) – falha na alocação de memória para buffer"
	cerrotar28="(ENOSPC) – arquivo muito grande para um volume"
	cerrotar78="(ENAMETOOLONG) - cwd name muito longo"
	cerrotar171="(ETOAST) – unidade de fitas on fire"
	ctools="Tools/Settings"
	cmsgtestarota="Please wait, testing route to the $cdistro server..."
	cmsgdelsha256="Please wait, deleting old SHA256SUM..."
	cmsgusermanager="$cdistro Linux user management"
	cmsgPacotes_disponiveis="Available packages"
    cmsggetshasum="Please wait, download sha256sum new..."
	cmsgdelpackageindex="Please wait, deleting old index..."
    cmsgdeltarball="Please wait, deleting old tarball..."
    cmsgtestsha256sum="Wait, testing sha256sum"
	cmsgadduser="Please wait, creating user..."
	cmsgaddhost="Please wait, setting hostname..."
    cmsgerrotar="Error in package unpacking"
	cmsgwaitgrub="Please wait, installing grub to disk"
	cmsgnoroute="Oops, no route to the $cdistro server! \nCheck your internet."
	cmsgerrodlsha1="Ops, error downloading of"
	cmsgerrodlsha2="Check your internet."
	cmsgcorrdlnew="Ops, corrupted package or SHA256. \nDownload the package again?"
	cmsg_corr_rep="Ops, corrupted package or SHA256. \nPlease retry the operation!"
	cmsg_erro_tar_continue="Error in decompressing the package. \nDo you want to continue?"
	cmsg_all_ready="All ready to begin the installation. Do you confirm?"
    cmsg_wget_package_index="Wait, downloading package index..."
	cmsg_nec_dismount="Need to dismount partition to repartition automatically."
	cwarning="** WARNING **"
	cmsg_alert_mount="Just to remember that the disk contains mounted partitions."
	cmsg_conf_dismount="The partition is mounted."
	cmsg_dismount="Disassemble?"
	cmsg_all_mounted_part="The selected disk contains mounted partitions."
	cmsg_umount_partition="Please wait, dismantling the working partition."
	cmsg_create_dir="wait, creating working directory."
	cmsg_mount_partition="Please wait, setting up workpart."
	cmsg_try_mount_partition="Partition already mounted. Try?"
	cmsg_mount_failed="Partition mount failed. Repeat?"
	cmsg_enter_work_dir="Please wait, entering the work directory."
	cmsg_mkfs_ok="Formation completed successfully."
	cmsg_mkfs_error="Formatting error."
	cdisco="DISK"
	cparticao="PARTITION"
	cmsg_extracting="Wait, Extracting files..."
	cmsg_part_disk="View disk partitions"
    cmsg_prepare_disk="Wait, preparing the disk:"
    cmsg_install_grub_disk="Installing grub on disk"
    cmsg_Detectada_particao_EFI="Detected EFI partition"
    cmsg_Deseja_instalar_o_GRUB_EFI="Do you want to install EFI grub"
    cmsg_Sim_EFI="Yes=EFI"
    cmsg_Nao_MBR="No=MBR"
    cmsg_Desmontando_particao="Unmounting partition"
    cmsg_Formatando_particao="Formatting partition"
    cmsg_Montando_particao="Mounting partition"
    cmsg_Instalando_GRUB_EFI_na_particao="Installing EFI grub on partition"
	cmsgInstalacao_Automatica="Automatic installation"
    cmsgInstalacao_Automatica_cancelada="Automatic installation canceled"
    cmsgErro_na_formatacao="Error in formatting"
    cmsgErro_no_particionamento="Partitioning error"
}

function scrend(){
	#info "By"
	#clear
	exit $1
}

function sh_checkroot(){
	if [ "$(id -u)" != "0" ]; then
		alerta "$cdistro Linux installer" "\nYou should run this script as root!"
		scrend 0
	fi
}

function sh_testdialog(){
    local xswap_grafico=$grafico
	grafico=$false
    clear
	cinfo=`log_info_msg "Wait, verifying dialog..."`
    msg "INFO" "$cinfo"
    test -e /usr/bin/dialog > /dev/null 2>&1
    evaluate_retval

	if [ $? = $false ]; then
		echo "You must install the dialog package to run $capp"
		echo "Voce deve instalar o pacote dialog para executar o $capp!"
		scrend 1
	fi
	grafico=$xswap_grafico
}


function init(){
	sh_testdialog
	sh_checkroot
	while true; do
		i18=$(dialog													\
			--stdout                                                  	\
			--backtitle	 	"$ccabec"				                    \
			--title 		"$welcome"				                    \
			--cancel-label	"Exit"	 									\
	        --menu			'\nChoose the language of the installer:'	\
	        0 80 0                                 						\
	        1 'Português'						 						\
	       	2 'English'							  						\
		   	3 'Wiki'													)

			exit_status=$?
			case $exit_status in
				$ESC)
                    clear
					scrend 1
					;;
				$CANCEL)
                    clear
					scrend 0
					;;
			esac
			case $i18 in
				1)
					pt_BR
					scrmain
					;;
				2)
					en_US
					scrmain
					;;
				3)
					dialog --no-collapse --title "$cdistro Wiki" --msgbox "$wiki" 0 0
					;;
			esac
	done
}

function sh_packagedisp(){
	sh_testarota
	if [ $? = $false ]; then
		info "\n$cmsgnoroute"
		menuinstall
	fi
	sh_delpackageindex
	sh_wgetpackageindex

    pkt=($(cat index.html               \
        | grep .xz                      \
        | awk '{print $2, $5}'          \
        | sed 's/<a href=\"//g'         \
        | cut -d'"' -f3                 \
        | sed 's/>//g'                  \
        | sed 's/<\/a//g' ))

     sd=$(dialog 				                                \
                 --backtitle     "$ccabec"                      \
                 --title         "$ccabec"                      \
                 --cancel-label  "Voltar"                       \
                 --menu          "\n$cmsgPacotes_disponiveis:"	\
			     0 50 0											\
                "${pkt[@]}" 2>&1 >/dev/tty						)

     exit_status=$?
     case $exit_status in
         $ESC)
             #scrend 1
             #exit 1
             #scrmain
             ;;
         $CANCEL)
             #scrend 0
             #scrmain
            ;;
     esac
}


sh_tools(){
	while true
	do
		tools=$(dialog 														\
				--stdout                                                  	\
				--backtitle 	"$ccabec"									\
				--title 		"$cmsg001"						  			\
				--cancel-label	"$buttonback"								\
		        --menu 			"\n\n$cmsg004" 		 						\
		        0 0 0                                 						\
		        1 "$cmsgInstalar_GRUB"					    				\
		        2 "$cmsgAlterar_FSTAB"				  						\
		        3 "$cinitbind"												\
		        4 "$cconfuser"												\
		        5 "$cmsgPacotes_disponiveis"								\
		        6 "$cmsg_part_disk"											\
		        7 "$cmsgInstalacao_Automatica"							    )

				exit_status=$?
				case $exit_status in
					$ESC)
						#scrend 1
						#exit 1
						scrmain
						;;
					$CANCEL)
						#scrend 0
						scrmain
						;;
				esac
		        case $tools in
					1) STANDALONE=$true; grubinstall;;
					2) STANDALONE=$true; sh_fstab;;
					3) STANDALONE=$true; LDISK=0; LPARTITION=0; sh_bind;;
					4) STANDALONE=$true; sh_confadduser;;
					5) sh_packagedisp;;
					6) choosedisk "SEE";;
					7) sh_automated_install;;
				esac
	done
}

function zeravar(){
    : ${LDISK=0}
    : ${LPARTITION=0}
    : ${LFORMAT=0}
    : ${LMOUNT=0}
    : ${LAUTOMATICA=$false}
}
function sh_automated_install(){
    confmulti "$cmsgInstalacao_Automatica"                  \
        "\nNeste modo a instalação será toda automatizada"  \
        "bastando escolher o pacote e o disco destino"      \
        "\n\nDeseja continuar e escolher o tipo de instalação e disco destino?"

    local nChoice=$?
    if [ $nChoice = $false ]; then
        LAUTOMATICA=$false
        sh_tools
    fi
    LAUTOMATICA=$true
    menuinstall
    nChoice=$?
    if [ $nChoice = $false ]; then
        info "$cmsgInstalacao_Automatica" "\n$Instalacao_Automatica_cancelada"
        zeravar
        sh_tools
    fi
    choosedisk
    nChoice=$?
    if [ $nChoice = $false ]; then
        info "$cmsgInstalacao_Automatica" "\n$Instalacao_Automatica_cancelada"
        zeravar
        sh_tools
    fi

    conf "$cmsgInstalacao_Automatica" "\nTudo pronto para iniciar a instalação. Continuar?"
    nChoice=$?
    if [ $nChoice = $false ]; then
        info "$cmsgInstalacao_Automatica" "\n$Instalacao_Automatica_cancelada"
        zeravar
        sh_tools
    fi
    sh_partnewbie
    nChoice=$?
    if [ $nChoice = $false ]; then
        info "$cmsgInstalacao_Automatica" "\n$Erro_no_particionamento!\n\n$Instalacao_Automatica_cancelada"
        zeravar
        sh_tools
    fi
    sh_domkfs
    nChoice=$?
    if [ $nChoice = $false ]; then
        info "$cmsgInstalacao_Automatica" "\n$Erro_na_formatacao!\n\n$Instalacao_Automatica_cancelada"
        zeravar
        sh_tools
    fi
    sh_wgetdefault
}

# Init - configuracao inicial
init

:<<'LIXO'
Passagem padrão original de Lorem Ipsum, usada desde o século XVI.

"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure 
dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non 
proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
'LIXO'
