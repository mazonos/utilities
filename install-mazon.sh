#!/bin/bash
#
################################################################
#       install dialog Mazon OS - version 0.0.1       			#
#                                                     			#
#      @utor: Diego Sarzi 		<diegosarzi@gmail.com>			#
#             Vilmar Catafesta 	<vcatafesta@gmail.com>			#
#      created: 2019/02/15          licence: MIT      			#
#      altered: 2019/02/18          licence: MIT      			#
#################################################################

#functions script
# Define the dialog exit status codes
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

#flag para disco/particao/montagem
: ${LDISK=0}
: ${LPARTITION=0}
: ${LMOUNT=0}
: ${LFORMAT=0}

ok=0
falso=1
dir_install="/mnt/mazon"
tarball_min="mazon_minimal-0.2.tar.xz"
tarball_full="mazon_beta-1.2.tar.xz"
tarball_default=$tarball_full
url_mazon="http://mazonos.com/releases/"
pwd=$PWD
cfstab=$dir_install"/etc/fstab"

wiki(){
cstr=$(cat << _EOF
Wiki
There are two ways to install, with the install-mazon.sh (dep dialog) script or the manual form as follows:

Pre Requirements: 
- Download MazonOS
- An existing Linux distribution or a linux livecd. 
- Create root partition using cfdisk or gparted (ext4) and DOS table / - min 20GB

Format partition: 
# mkfs.ext4 /dev/sdx(x)
Mount partition in /mnt:
# mount /dev/sdx(x) /mnt

Unzip the mazonos file in / mnt:
# tar -xJpvf /xxx/xxx/mazonos.tar.xz -C /mnt

Go to /mnt directory:
# cd /mnt

Mount proc / dev / sys and chroot to /mnt:
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
}

mensagem(){
	dialog                                  \
   		--title 'MazonOS Linux'     		\
		--backtitle	"$ccabec"				\
	   	--infobox "$*"    					\
	    0 0
}

tolower(){
	$1 | tr 'A-Z' 'a-z'
}

toloupper(){
	$1 | tr 'a-z' 'Z-A'
}

display_result() {
	dialog 	--title "$2" 			\
    		--no-collapse 			\
			--backtitle	"$ccabec"	\
    		--msgbox "$1" 			\
			16 80
}

alerta(){
	dialog 	--clear 				\
			--title 	"$1" 		\
			--backtitle	"$ccabec"	\
			--msgbox 	"$2" 		\
			5 40
}

info(){
	dialog 	--clear 				\
			--title 	"$cmsg002"	\
			--backtitle	"$ccabec"	\
			--msgbox 	"$*" 		\
			5 40
}

conf(){
    dialog	--clear					\
			--title 	"$1" 		\
    		--no-collapse 			\
			--backtitle	"$ccabec"	\
			--yesno 	"$2" 		\
			10 100
}

quit(){
	[ $? -ne 0 ] && { clear ; exit ;}
}

tarfull(){
	which pv
	if [ $? = 1 ]; then
    	tar xJpvf $mazon -C /mnt
	else
		(pv -n $mazon | tar xJpvf - -C /mnt ) \
       		2>&1 | dialog --backtitle "$ccabec" --gauge "Extracting files..." 6 50
	fi
}

grubinstall(){
	grubyes=$(conf ' *** GRUB *** ' 'Would you like to install grub?\n\n*Remembering that we do not yet have dual boot support in our grub.\nIf use dualboot, use the grub from its other distribution with:\n# update-grub')
	if [ $grubyes = 'yes' ]; then
		cd $dir_install
	   	mount --type proc /proc proc/
		mount --rbind /sys sys/
	    mount --rbind /dev dev/
	    chroot . /bin/bash -c "grub-install ${part/[0-9]/}"
		chroot . /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"
	    scrfstab
	    alerta "*** GRUB *** " "ok! grub successfully installed"
		finish
	else
		alerta ' *** GRUB ERROR ***' 'ops, error install grub. please check bugs'
      	exit
	fi
}

scrfstab(){
	mkdir -p $dir_install/etc >/dev/null
	xuuid=$(blkid | grep $part | awk '{print $3}')
	label="/            ext4     defaults            1     1"
	sed -ir "/<xxx>/ i $xuuid $label" $cfstab
	sed -i 's|/dev/<xxx>|#'$part'|g' $cfstab
	local result=$( cat $cfstab )
	display_result "$result" "$cmsg011"
}

finish(){
	alerta 	' *** INSTALL COMPLETE *** '	\
			'Install Complete! Good vibes.\nModify /mnt/etc/fstab and reboot.\n\nSend bugs - root@mazonos.com'
	exit
}

dlwgetdefault(){
	local URL=$url_mazon$tarball_default
	conf ' *** DOWNLOAD *** ' "$cmsgversion"

	local nchoice=$?
	case $nchoice in
		$D_OK)
			#wget -c $URL;;
			wget -c "$URL" 2>&1 | \
		    	stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | \
        		dialog --title "Please wait, Downloading..." --backtitle "$ccabec" --gauge $URL 7 70
			;;
		$D_CANCEL)
			info $cmsg017
			exit;;
	esac

	mazon=$(ls | grep $tarball_default)
	if [$?='1']; then
		alert " *** CHECK *** " "Not found tarball $tarball_default in ./nPlease select file next screen..."
	   	fmazon=$( dialog --stdout --fselect './' 6 40 )
		quit
	else
		conf "*** DOWNLOAD *** " "[ok] Download completed successfully.\n[ok] $mazon found.\n\nStart the installation now?"
		local ninit=$?
		case $ninit in
			$D_OK)scrinstallmin;;
		esac
	fi
}

scrinstallmin(){
	conf "*** INSTALL " "The minimal version does not come from Xorg and IDE.\nDo you confirm?"
	local nchoice=$?
	case $nchoice in
		$D_OK)
			info "$LDISK"
			if [ $LDISK -eq 0 ]; then
				info "choosedisk"
				choosedisk
			fi
			if [ $LPARTITION -eq 0 ]; then
				choosepartition
			fi
			if [ $LFORMAT -eq 0 ]; then
				scrformat
			fi
			if [ $LMOUNT -eq 0 ]; then
				mountpartition
			fi
    		cd $dir_install
        	tar -xJpvf $pwd/$tarball_min -C $dir_install
			grubinstall
			break
			;;
	esac
}

scrinstall(){
	while true
	do
    	resposta=$( dialog --stdout                         			\
        	--title 	' *** INSTALL CONFIGURATION *** '  				\
           	--menu 		'Choose your option:'              				\
           	0 70 0                                       				\
	   		full       '*8.2G Free disk (Xfce4 or i3wm)' 				\
           	minimal    'Minimall install, not X.'        				\
           	custom     'Choose softwares. (GIMP, QT5, LIBREOFFICE...)'	\
           	quit       'Exit install'									)

		 # sair com cancelar ou esc
		clear
		quit

		case "$resposta" in
			full)	resfull=$(dialog --stdout                   \
					--title 'FULL INSTALATION'  	            \
					--menu 'Choose your Desktop Enviroment:' 	\
                        0 0 0                                   \
                        XFCE4 'Classic and powerfull!' 			\
                        i3WM  'Desktop for advanceds guys B).'	)

						case "$resfull" in
                        	# TROCAR POR /MNT *********************
                            XFCE4) 	dlwgetdefault
	             					tarfull
                                    echo "ck-launch-session dbus-launch --exit-with-session startxfce4" > /mnt/etc/skel/.xinitrc
									break
									;;

							i3WM) 	downloadwget "https://sourceforge.net/projects/mazonos/files/latest/download"
                            		tarfull
                                    echo "ck-launch-session dbus-launch --exit-with-session i3" > /mnt/etc/skel/.xinitrc
									break ;;
                        esac ;;

			minimal)
				tarball_default=$tarball_min
				cmsgversion=$cmsg015
				dlwgetdefault
				scrinstallmin
				;;

			custom) 	rescustom=$(dialog --stdout                 			\
                        	--separate-output                       			\
                        	--checklist 'Choose install softwares:' 			\
                        	0 0 0                                   			\
							LIBREOFFICE  'Office suite free' OFF    			\
                        	GIMP 		 'GNU Image Manipulation Program' OFF  	\
                        	INKSCAPE 	 'Draw freely' OFF                     	\
                        	QT5 		 'Framework' OFF 						\
                        	SUBLIME_TEXT 'Text editor for code' OFF 			\
                        	VLC 		 'Player video' OFF 					\
                        	OPENJDK 	 'Open Java' OFF 						\
                        	TELEGRAM 	 'Communicator' OFF 					\
                        	SIMPLESCREENRECORDER 'Recorder desktop' OFF)

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
				exit
				;;
		esac
	done

	# grub install
	#######################
   	grubinstall
	finish
	clear
}

sh_checkdisk(){
	#dsk=($(df | grep ^$sd | awk '{print $1 $2, $3}'))
	dsk=($(df | grep $sd | cut -c 1-}))
	#dsk=($(df -h | grep ^$sd))
	#dsk=($(df -h | grep $sd))
	conf "** AVISO **" "\nO disco selecionado contém partições montadas.\n\n$dsk\n\nDesmontar?"
	display_result "** AVISO **" "\nO disco selecionado contém partições montadas.\n\nDesmontar?" $dsk
}


choosedisk(){
	# escolha o disco a ser particionado // Choose disk to be parted
	################################################################
	#disks=( $(fdisk -l | egrep -o '^/dev/sd[a-z]'| sed "s/$/ '*' /") )
	$LDISK=0
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
		sh_checkdisk



 		typefmt=$(dialog \
	    	--stdout 													\
	    	--title     	"$cmsg009" 									\
			--cancel-label	"$buttonback"								\
	    	--radiolist 	"$cmsg010"		 							\
	    	0 0 0 														\
	    	"$cmsg012"  "$cmsg011"								 on 	\
	    	newbie      "$cmsg013"					   		     off	)

			case "$typefmt" in
				$cmsg012)
					cfdisk --color=always $sd
					$LDISK=1
					local result=$( fdisk -l $sd )
				    display_result "$result" "$cmsg011"
					;;

				newbie)
					conf "$cmsg020" "$cmsg020\n$cmsg014"
					local nb=$?
					case $nb in
						$D_OK)
							echo "label: dos" | echo ";" | echo "id=83" | sfdisk --force $sd >/dev/null
							$LDISK=1
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

mountpartition(){
	# Partition mount
	#################
	alert $part
	mensagem "Aguarde, criando diretorio de trabalho."
	mkdir -p $dir_install
	mensagem "Aguarde, Montando particao de trabalho."
	mount $part $dir_install
	$LMOUNT=1
	mensagem "Aguarde, Entrando no diretorio de trabalho."
	cd $dir_install
	#scrinstall
}

choosepartition(){
	# escolha a particao a ser instalada // Choose install partition
	################################################################
	#partitions=( $(blkid | cut -d: -f1 | sed "s/$/ '*' /") )
	#partitions=( $(ls $sd* | grep -o '/dev/sd[a-z][0-9]' | sed "s/$/ '*' /") )
	$LPARTITION=0
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
			$LPARTITION=0
			#scrend 1
			#exit 1
			scrmain
			;;
		$CANCEL)
			$LPARTITION=0
			#scrend 0
			scrmain
			;;
	esac
	$LPARTITION=1
	scrformat
	#mountpartition
}

scrformat(){
	# deseja formatar?
	$LFORMAT=0
	format=
    conf " *** FORMAT *** " "\n   $cmsg020 \n\n   $cmsg021 $part ?" && format="yes"
	if [ $format='yes' ] ; then
    	# WARNING! FORMAT PARTITION
	    #######################
		umount $part >/dev/null
        mkfs -t ext4 -L "MAZONOS" $part
		$LFORMAT=1
	else
		$LFORMAT=0
	fi
}

dlmenu(){
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
					dlwgetdefault
					;;
				2) 	tarball_default=$tarball_min
					cmsgversion=$cmsg015
					dlwgetdefault
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
			   	4 "$cmsg008"						     					\
			   	5 "$menustep"		   					     				\
			   	6 "Install"	   					     						)

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
					1) dlmenu;;
					2) choosedisk;;
					3) choosepartition;;
					4) scrend 0;;
					5) choosedisk; choosepartition; dlmenu;;
					6) scrinstall;;
				esac
	done
}

pt_BR(){
	ccabec="MazonOS Linux installer v1.0"
	buttonback="Voltar"
	cmsg000="Sair"
	cmsg001="*** MazonOS INSTALL v1.0 ***"
	cmsg002="MazonOS Linux"
	cmsg003="Bem-vindo ao instalador do MazonOS"
	cmsg004="Escolha uma opção:"
	cmsg005="Baixar pacote de instalacao"
	cmsg006="Particionar Disco"
	cmsg007="Escolher partição para instalar"
	cmsg008="Sair do instalador"
	cmsg009="Escolha o disco para particionar:"
	cmsg010="Escolha o tipo:"
	cmsg011="Particionamento manual usando cfdisk"
	cmsg012="Experiente"
	cmsg013="Particionamento automatico (sfdisk)"
	cmsg014="Tem certeza?"
	cmsg015='Voce gostaria de baixar o MazonOS minimal?'
	cmsg016='Voce gostaria de baixar o MazonOS full?'
	cmsg017='Download cancelado!'
	cmsgversion=$cmsg015
	cmsg018="Baixar pacote full (X)"
	cmsg019="Baixar pacote minimal"
	cmsg020="** AVISO ** Todos os dados serão perdidos!"
	cmsg021="Formatar partição"
	menuquit="Sair"
	menustep="Passo a passo"
}

en_US(){
	ccabec="MazonOS Linux installer v1.0"
	buttonback="Back"
	cmsg000="Exit"
	cmsg001="*** MazonOS INSTALL v1.0 ***"
	cmsg002="MazonOS Linux"
	cmsg003="Welcome to the MazonOS installer"
	cmsg004="Choose an option:"
	cmsg005="Download installation package"
	cmsg006="Partition Disk"
	cmsg007="Choose partition to install"
	cmsg008="Quit the installer"
	cmsg009="Choose the disk to partition:"
	cmsg010="Choose type:"
	cmsg011="Manual partitioning using cfdisk"
	cmsg012="Expert"
	cmsg013="Automatic partitioning (sfdisk)"
	cmsg014="Are you sure?"
	cmsg015='Would you like to download MazonOS minimal?'
	cmsg016='Would you like to download MazonOS full?'
	cmsgversion=$cmsg015
	cmsg017='Download canceled!'
	cmsg018="Download full package (X)"
	cmsg020="** NOTICE ** Will data will be lost!"
	cmsg021="Format partition"
	menuquit="Quit"
	menustep="Step by step"
}

scrend(){
	info "By"
	clear
	exit $1
}

choosetypeuser(){
	while true; do
		i18=$(dialog													\
			--clear														\
			--stdout                                                  	\
			--backtitle	 	"$ccabec"					 				\
			--title 		'Bem-vindo ao MazonOS install v1.0'			\
			--cancel-label	"Encerrar" 									\
	        --menu			'\nEscolha o idioma do instalador:\n'		\
	        0 80 0                                 						\
	        1 'Português'						 						\
	       	2 'English'							  						\
		   	3 'Wiki'													\
		   	4 "$menuquit"												)

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
					dialog --no-collapse --title "MazonOS Wiki" --textbox wiki 0 0
					;;
				4)
					scrend 0
					;;
			esac
	done
}

init(){
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
					dialog --no-collapse --title "MazonOS Wiki" --textbox wiki 0 0
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

