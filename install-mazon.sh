#!/bin/bash
#
################################################################
#       install dialog Mazon OS - version 1.0       			#
#                                                     			#
#      @utor: Diego Sarzi 		<diegosarzi@gmail.com>			#
#             Vilmar Catafesta 	<vcatafesta@gmail.com>			#
#      created: 2019/02/15          licence: MIT      			#
#      altered: 2019/02/17          licence: MIT      			#
#################################################################

# flag dialog exit status codes
: ${D_OK=0}
: ${D_CANCEL=1}
: ${D_HELP=2}
: ${D_EXTRA=3}
: ${D_ITEM_HELP=4}
: ${D_ESC=255}

CANCEL=1
ESC=255
HEIGHT=0
WIDTH=0

# flag para disco/particao/formatacao/montagem
: ${LDISK=0}
: ${LPARTITION=0}
: ${LFORMAT=0}
: ${LMOUNT=0}

# vars
declare -i ok=0
declare -i falso=1
declare -r ccabec="MazonOS Linux installer v1.0"
declare -r dir_install="/mnt/mazon"
declare -r url_mazon="http://mazonos.com/releases/"
declare -r tarball_min="mazon_minimal-0.2.tar.xz"
declare -r sha256_min="mazon_minimal-0.2.sha256sum"
declare -r tarball_full="mazon_beta-1.2.tar.xz"
declare -r sha256_full="mazon_beta-1.2.sha256sum"
tarball_default=$tarball_full
sh256_default=$sha256_full
declare -r pwd=$PWD
declare -r cfstab=$dir_install"/etc/fstab"
declare -r wiki=$(cat << _EOF
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
- If you want to do a dual boot with your existing system with a working grub, exit the chroot with "exit" command and 
unmount the partitions with:
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
_EOF)

# lib functions script

function mensagem(){
	dialog								\
   		--title 	'MazonOS Linux'		\
		--backtitle	"$ccabec"			\
	   	--infobox 	"$*"				\
	    0 0
}

function tolower(){
	$1 | tr 'A-Z' 'a-z'
}

function toloupper(){
	$1 | tr 'a-z' 'Z-A'
}

function display_result() {
	dialog 	--title 	"$2"			\
    		--no-collapse				\
			--backtitle	"$ccabec"		\
    		--msgbox 	"$1" 			\
			16 80
}

function alerta(){
	dialog 	--clear						\
			--title 	"$1" 			\
			--backtitle	"$ccabec"		\
			--msgbox 	"$2" 			\
			9 60
}

function info(){
	dialog 	--clear 					\
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

function sh_exectar(){
  	cd $dir_install
	which pv
	if [ $? = 127 ]; then   # no which?
	    tar xJpvf $pwd/$tarball_default -C $dir_install
	elif [ $? = 1 ]; then
	    tar xJpvf $pwd/$tarball_default -C $dir_install
	else
		(pv -pteb $pwd/$tarball_default								\
		|tar xJpvf - -C $dir_install ) 2>&1 						\
		|dialog	--backtitle "$ccabec" --gauge "Extracting files..." \
		6 50
	fi
}

function grubinstall(){
	conf "*** GRUB ***" "$cGrubMsgInstall"
	grubyes=$?
	if [ $grubyes = 0 ]; then
		cd $dir_install
	   	mount --type proc /proc proc/
		mount --rbind /sys sys/
	    mount --rbind /dev dev/
	    chroot . /bin/bash -c "grub-install ${part/[0-9]/}"
		chroot . /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"
	    alerta "*** GRUB *** " "$cgrubsuccess"
	fi
	#sh_umountpartition
	sh_finish
}

function sh_fstab(){
	mkdir -p $dir_install/etc >/dev/null
	xuuid=$(blkid | grep $part | awk '{print $3}')
	label="/            ext4     defaults            1     1"
	sed -ir "/<xxx>/ i $xuuid $label" $cfstab
	sed -i 's|/dev/<xxx>|#'$part'|g' $cfstab
	local result=$( cat $cfstab )
	display_result "$result" "$cfstab"
}

function sh_finish(){
	alerta "*** INSTALL ***" "$cfinish"
	exit
}

function sh_wgetdefault(){
	local URL=$url_mazon$tarball_default
	conf "$cmsg005" "\n$cmsgversion"

	local nchoice=$?
	case $nchoice in
		$D_OK)
			#wget -c $URL;;
			wget -c $URL 2>&1 | \
		    	stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | \
        		dialog --title "$plswait" --backtitle "$ccabec" --gauge $URL 7 70
			;;
		$D_CANCEL)
			info $cmsg017
			menuinstall;;
	esac

	mazon=$(ls | grep $tarball_default)
	if [$?='1']; then
		alert " *** CHECK *** " "Not found tarball $tarball_default in ./nPlease select file next screen..."
	   	fmazon=$( dialog --stdout --fselect './' 6 40 )
		quit
	else
		confmulti "$cdlok1" "$cdlok2" "\n[ok] $tarball_default $cdlok3" "$cdlok4"
		local ninit=$?
		case $ninit in
			$D_OK)
				sh_check_install
				;;

			$D_CANCEL)
				info $cancelinst
				menuinstall
				;;
		esac
	fi
}

function sh_check_install(){
#	if [ $LDISK -eq 0 ]; then
#		choosedisk
#	fi
	if [ $LPARTITION -eq 0 ]; then
		choosepartition
	fi
	if [ $LFORMAT -eq 0 ]; then
		sh_format
		if [ $? = 1 ]; then
			LPARTITION=0
			menuinstall
		fi
	fi
	if [ $LMOUNT -eq 0 ]; then
		sh_mountpartition
	fi

	confmulti "INSTALL" "\nDir Montagem : $dir_install" "\n    Partição : $part" "\n\nTudo pronto para iniciar a 
instalação. Confirma?"
	local nOk=$?
	case $nOk in
		$D_ESC)
			info $cancelinst
			menuinstall
			;;
		$D_CANCEL)
			info $cancelinst
			menuinstall
			;;
	esac

	sh_exectar
    sh_fstab
	grubinstall
}

function menuinstall(){
	while true
	do
    	resposta=$( dialog												\
		--stdout														\
        --title 		' *** INSTALL CONFIGURATION *** '				\
		--backtitle 	"$ccabec"										\
		--cancel-label	"$buttonback"									\
		--menu			"$cmsg004"										\
		0 70 0															\
	   	full			"$cmsgfull"										\
		minimal			"$cmsgmin"										\
		quit			"$cmsgquit"										)
#		custom			'Choose softwares. (GIMP, QT5, LIBREOFFICE...)'

		exit_status=$?
		case $exit_status in
			$ESC)
				scrmain
				;;
			$CANCEL)
				scrmain
				;;
		esac

		case "$resposta" in
		full)
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
					loop
					;;
				$CANCEL)
					loop
					;;
			esac

			case "$resfull" in
				# TROCAR POR /MNT *********************
			XFCE4)
				tarball_default=$tarball_full
				cmsgversion=$cmsg016
				sh_wgetdefault
				echo "ck-launch-session dbus-launch --exit-with-session startxfce4" > $dir_install/mnt/etc/skel/.xinitrc
				break
				;;

			i3WM)
				tarball_default=$tarball_full
				cmsgversion=$cmsg016
				sh_wgetdefault
				echo "ck-launch-session dbus-launch --exit-with-session i3" > $dir_install/etc/skel/.xinitrc
				break
				;;
			esac
			;;

		minimal)
			tarball_default=$tarball_min
			cmsgversion=$cmsg015
			sh_wgetdefault
			#sh_check_install
			#sh_mountpartiton
			#sh_exectar
			#grubinstall;
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
		quit)
			scrend 0
			;;
		esac
	done

	# grub install
	#######################
   	#grubinstall
	#sh_finish
	#clear
}

function sh_checkdisk(){
	dsk=$(df -h | grep "$sd" | awk '{print $1, $2, $3, $4, $5, $6, $7}')
	#dsk=$(df | grep $sd | cut -c 1-})
	#dsk=$(df -h | grep ^$sd)
	#dsk=$(df -h | grep "$sd")

	local nchoice=0
	if [ "$dsk" <> " " ]; then
		conf "** AVISO **" "\nO disco selecionado contém partições montadas.\n\n$dsk\n\nDesmontar?"
		nchoice=$?
		if [ $nchoice = 0 ]; then
			for i in $(seq 1 10); do
				umount -rl $sd$i 2> /dev/null
			done
		fi
	fi
	return $nchoice
}

function sh_checksimple(){
	local sdsk=$(df -h | grep "$sd" | awk '{print $1, $2, $3, $4, $5, $6, $7}')

	local nchoice=0
	if [ "$sdsk" <> " " ]; then
		alerta "** AVISO **" "\nSó para lembrar que o disco contém partições montadas.\n\n$sdsk"
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
		conf "** AVISO **" "\nA partição está montada.\n\n$cpart\n\nDesmontar?"
		nchoice=$?
		if [ $nchoice = 0 ]; then
			umount -rl $part 2> /dev/null
			LMOUNT=0
		fi
	fi
	return $nchoice
}

function choosedisk(){
	# escolha o disco a ser particionado // Choose disk to be parted
	################################################################
	#disks=( $(fdisk -l | egrep -o '^/dev/sd[a-z]'| sed "s/$/ '*' /") )
	LDISK=0
	disks=($(ls /dev/sd* | grep -o '/dev/sd[a-z]' | cat | sort | uniq | sed "s/$/ '*' /"))
	sd=$(dialog --clear 														\
				--backtitle	 	"$ccabec"					 					\
				--cancel-label 	"$buttonback"									\
				--menu 			"$cmsg009" 0 50 0 "${disks[@]}" 2>&1 >/dev/tty 	)

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

	if [ $sd <> 0 ]; then
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
						alerta "CHOOSEDISK" "Necessário desmontar particao para reparticionar automaticamente."
						choosedisk
					fi
					conf "$cmsg020" "$cmsg020\n$cmsg014"
					local nb=$?
					case $nb in
						$D_OK)
							echo "label: dos" | echo ";" | echo "id=83" | sfdisk --force $sd >/dev/null
							LDISK=1
							local result=$( fdisk -l $sd )
						    display_result "$result" "$csmg013"
							;;
					esac
					;;
	    	esac
	fi
	#choosepartition
	#if [ $sd <> 0 ]; then
	#cfdisk $sd
	#fi
}

function sh_umountpartition(){
	mensagem "Aguarde, Desmontando particao de trabalho."
	umount -rl $part 2> /dev/null
	LMOUNT=0
	cd $pwd
	#menuinstall
}

function sh_mountpartition(){
	mensagem "Aguarde, criando diretorio de trabalho."
	mkdir -p $dir_install
	mensagem "Aguarde, Montando particao de trabalho."

	while true
	do
		mount $part $dir_install 2> /dev/null
		if [ $? = 32 ]; then # monta?
			conf "** MOUNT **" "Particao já montada. Tentar?"
            if [ $? = 0 ]; then
				loop
			fi
           	LMOUNT=0
			break
		fi
		if [ $? = 1 ]; then # fail?
			conf "** MOUNT **" "Falha de montagem da partição. Tentar?"
            if [ $? = 0 ]; then
				loop
			fi
           	LMOUNT=0
			break
		fi
		break
	done
	LMOUNT=1
	mensagem "Aguarde, Entrando no diretorio de trabalho."
	cd $dir_install
	#menuinstall
}

function choosepartition(){
	# escolha a particao a ser instalada // Choose install partition
	################################################################
	#partitions=( $(blkid | cut -d: -f1 | sed "s/$/ '*' /") )
	#partitions=( $(ls $sd* | grep -o '/dev/sd[a-z][0-9]' | sed "s/$/ '*' /") )
	LPARTITION=0
	partitions=( $(fdisk -l | sed -n /sd[a-z][0-9]/p | awk '{print $1,$5}'))
	part=$(dialog 														\
			--clear	 													\
			--backtitle	 	"$ccabec"					 				\
			--cancel-label	"$buttonback"								\
			--menu 			'Choose partition for installation mazonOS:' \
			0 50 0 														\
			"${partitions[@]}" 2>&1 >/dev/tty 							)

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

function sh_format(){
	# deseja formatar?
	sh_checkpartition
    local nmontada=$?
	local format=1

	if [ $nmontada = 0 ] ; then
		LFORMAT=0
	    conf " *** FORMAT *** " "\n   $cmsg020 \n\n   $cmsg021 $part ?"
		format=$?
		if [ $format = 0 ] ; then
	    	# WARNING! FORMAT PARTITION
		    #######################
			umount -rl $part 2> /dev/null
	        mkfs -F -t ext4 -L "MAZONOS" $part > /dev/null
			local nfmt=$?
			if [ $nfmt = 0 ] ; then
				alerta "MKFS" "Formatacao terminada com sucesso."
				LFORMAT=1
			else
				alerta "MKFS" "Erro na Formatacao."
				LFORMAT=0
				return 1
			fi
		else
			LFORMAT=0
		fi
	fi
	return $format
}

function dlmenu(){
	while true
	do
		dl=$(dialog 										\
			--clear                                 		\
			--stdout                                		\
			--backtitle 	"$ccabec"						\
			--title 		' *** MazonOS INSTALL *** v1.0'	\
			--cancel-label	"$buttonback"					\
	        --menu  		'Choose package to download:'   \
	        0 0 0                                 			\
	        1 "$cmsg018" 				 					\
	        2 "$cmsg019"  									\
		   	3 "$cmsg000"   									)

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
		    case $dl in
				1)	tarball_default=$tarball_full
					cmsgversion=$cmsg016
					sh_wgetdefault
					;;
				2) 	tarball_default=$tarball_min
					cmsgversion=$cmsg015
					sh_wgetdefault
					;;
				3) 	clear; exit;;
			esac
	done
}

scrmain(){
	while true
	do
		clear
		# primeira tela // hello
		##########################
		sd=$(ls /dev/sd*)
		main=$(dialog 														\
				--stdout                                                  	\
				--backtitle 	"$ccabec"									\
				--title 		"$cmsg001"						  			\
				--cancel-label	"$buttonback"								\
		        --menu 			"$cmsg003\n\n$cmsg004" 		 				\
		        0 0 0                                 						\
		        1 "$cmsg005"  												\
		        2 "$cmsg006"						  						\
		        3 "$cmsg007"												\
			   	4 "Install"	   					     						\
			   	5 "$cmsgquit"						     					)

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
					5) scrend 0;;
				esac
	done
}

pt_BR(){
	lang="pt_BR"
	buttonback="Voltar"
	cmsg000="Sair"
	cmsg001="MazonOS Linux INSTALL v1.0"
	cmsg002="MazonOS Linux"
	cmsg003="Bem-vindo ao instalador do MazonOS"
	cmsg004="Escolha uma opção:"
	cmsg005="Baixar pacote de instalacao"
	cmsg006="Particionar Disco"
	cmsg007="Escolher partição para instalar"
	cmsg008="Sair do instalador"
	cmsgquit="Sair do instalador"
	cmsg009="Escolha o disco para particionar:"
	cmsg010="Escolha o tipo:"
	cmsg011="Particionamento manual usando cfdisk"
	cmsg012="Experiente"
	cexpert="Experiente"
	cnewbie="Novato"
	cmsg013="Particionamento automatico (sfdisk)"
	cmsg014="Tem certeza?"
	cmsg015='A versão mínima não inclui o Xorg e DE.\nVocê gostaria de baixar o MazonOS minimal?'
	cmsg016='Você gostaria de baixar o MazonOS full?'
	cmsg017='Download cancelado!'
	cancelinst="Instalacao cancelada!"
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
	cdlok2="\n[ok] Download concluído com sucesso."
	cdlok3="encontrado."
	cdlok4="\n\nIniciar a instalação agora?"
    plswait="Por favor aguarde, baixando pacote..."
	cfinish="Instalação completa! Boas vibes.\nReboot para iniciar com MazonOS Linux. \n\nEnviar bugs root@mazonos.com"
	cgrubsuccess="OK! GRUB instalado com sucesso!"
	cGrubMsgInstall="Você gostaria de instalar o GRUB? \
					\n\n*Lembrando que ainda não temos suporte a dual boot. \
					\nSe precisar de dual boot, use o grub de outra distribuição com:\n# update-grub"
	cchooseX="Escolha o seu ambiente de Desktop:"
	cxfce4="Clássico e poderoso!"
	ci3wm="Desktop para caras avançados B)."
	cmsgmin="Instalação mínima, sem X"
   	cmsgfull="Instalação completa. *8.2G de disco (Xfce4 ou i3wm)"
}

en_US(){
	lang="en_US"
	buttonback="Back"
	cmsg000="Exit"
	cmsg001="MazonOS Linux INSTALL v1.0"
	cmsg002="MazonOS Linux"
	cmsg003="Welcome to the MazonOS installer"
	cmsg004="Choose an option:"
	cmsg005="Download installation package"
	cmsg006="Partition Disk"
	cmsg007="Choose partition to install"
	cmsg008="Quit the installer"
	cmsgquit="Quit the installer"
	cmsg009="Choose the disk to partition:"
	cmsg010="Choose type:"
	cmsg011="Manual partitioning using cfdisk"
	cmsg012="Expert"
	cexpert="Expert"
	cnewbie="Newbie"
	cmsg013="Automatic partitioning (sfdisk)"
	cmsg014="Are you sure?"
	cmsg015='The minimum version does not include Xorg and DE. \nWould you like to download MazonOS minimal?'
	cmsg016='Would you like to download MazonOS full?'
	cmsgversion=$cmsg015
	cmsg017='Download canceled!'
	cancelinst="Installation canceled!"
	cmsg018="Download full package (X)"
	cmsg020="** NOTICE ** Will data will be lost!"
	cmsg021="Format partition"
	menuquit="Quit"
	menustep="Step by step"
	yeslabel="Yes"
	nolabel="No"
	cdlok1="*** DOWNLOAD ***"
	cdlok2="\n[ok] Download completed successfully."
	cdlok3="found."
	cdlok4="\n\nStart the installation now?"
    plswait="Please wait, Downloading package..."
	cfinish="Install Complete! Good vibes. \nReboot to start with MazonOS Linux. \n\nSend bugs - root@mazonos.com"
	cgrubsucess="OK! GRUB successfully installed!"
	cGrubMsgInstall="Would you like to install grub? \
					\n\n*Remembering that we do not yet have dual boot support. \
					\nIf use dualboot, use the grub from its other distribution with:\n# update-grub"
	cchooseX="Choose your Desktop Environment:"
	cxfce4="Classic and powerfull!"
	ci3wm="Desktop for avanced guys B)."
	cmsgmin="Minimum installation, not X"
   	cmsgfull="Complete installation. *8.2G disk (Xfce4 or i3wm)"
}

function scrend(){
	#info "By"
	clear
	exit $1
}

function sh_checkroot(){
	if [ "$(id -u)" != "0" ]; then
		alerta "MazonOS Linux installer" "\nVoce deve executar este script como root!"
		scrend 0
	fi
}


function init(){
	sh_checkroot
	while true; do
		i18=$(dialog													\
			--clear														\
			--stdout                                                  	\
			--backtitle	 	"MazonOS Linux installer v1.0"				\
			--title 		'Bem-vindo ao MazonOS install v1.0'			\
			--cancel-label	"Encerrar" 									\
	        --menu			'\nEscolha o idioma do instalador:\n'		\
	        0 80 0                                 						\
	        1 'Português'						 						\
	       	2 'English'							  						\
		   	3 'Wiki'													\
		   	4 'Sair'													)

			exit_status=$?
			case $exit_status in
				$ESC)
					scrend 1
					exit 1
					;;
				$CANCEL)
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
					dialog --no-collapse --title "MazonOS Wiki" --msgbox "$wiki" 0 0
					;;
				4)
					scrend 0
					;;
			esac
	done
}

# Init - configuracao inicial
clear
init

:<<'LIXO'
Passagem padrão original de Lorem Ipsum, usada desde o século XVI.

"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
LIXO
