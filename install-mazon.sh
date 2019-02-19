#!/bin/bash
#######################################################
#       install dialog Mazon OS - version 0.0.1       #
#                                                     #
#      @utor: Diego Sarzi <diegosarzi@gmail.com>      #
#      created: 2019/02/15          licence: MIT      #
#######################################################

# funcoes
quit()
{
        [ $? -ne 0 ] && { clear ; exit ;}
}

finish(){
        dialog --title ' *** INSTALL COMPLETE *** ' --msgbox 'Install Complete! Good vibes.\nModify /mnt/etc/fstab and reboot.\n\nSend bugs - root@mazonos.com' 0 0
exit
}

grubinstall(){
if [ $? = 0 ]; then
        cd /mnt
        mount --type proc /proc proc/
        mount --rbind /sys sys/
        mount --rbind /dev dev/
        chroot . /bin/bash -c "grub-install ${part/[0-9]/}"
        chroot . /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"
        dialog --title ' *** GRUB *** ' --msgbox 'ok! grub installed sucefull' 5 70
else
        dialog --title ' *** GRUB ERROR ***' --msgbox 'ops, error install grub. please check bugs' 5 70
        exit
fi
}

tarfull(){
        which pv
        if [ $? = 1 ]; then
                tar xJpvf $mazon -C /mnt
        else
                (pv -n $mazon | tar xJpvf - -C /mnt ) \
                2>&1 | dialog --gauge "Extracting files..." 6 50
        fi
}

downloadwget(){
local URL=$1
download=
dialog --title ' *** DOWNLOAD *** '  --yesno 'Would you like to download mazon-lasted.tar.xz?' 5 55 && download='yes'
if [ $download = 'yes' ]; then
        wget $URL
        #wget "$URL" 2>&1 | \
        #stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | \
        #dialog --gauge "Downloading mazon-lasted.tar.xz..." 7 70
fi

if [ $1 = 'https://sourceforge.net/projects/mazonos/files/old-versions/mazonos-alpha-0.2.tar.bzip2/download' ]; then
	mv download /mnt/mazonos-alpha-0.2.tar.bzip2
else
	mv download /mnt/mazonos-lasted.tar.xz
fi

mazon=$(ls | grep mazon)
if [ $? = '1' ]; then
        dialog --title ' *** CHECK *** ' --msgbox 'Not found tarball mazon_version.tar.xz in ./\nPlease select file next screen...' 7 70
        fmazon=$( dialog --stdout --fselect './' 6 40 )
        quit
else
        dialog --msgbox "$mazon found." 6 40
fi
}

# primeira tela // helo
##########################
createdisk='no'
dialog --title ' *** CREATE PARTITION *** ' --yesno '\n    Welcome to install mazonOS.\n\n  You like create partitions now? ' 8 40 && createdisk='yes'
if [ $createdisk = yes ]; then
	cfdisk
fi

# escolha a hd a ser instalada // install hd
#########################
partitions=( $(blkid | cut -d: -f1 | sed "s/$/ '*' /") )
part=$(dialog --clear --menu 'Choose partition for installation mazonOS:' \
        0 50 0 \
        "${partitions[@]}" \
        2>&1 >/dev/tty )
quit

# deseja formatar?
format=
dialog --title ' *** FORMAT *** ' \
        --yesno "\n   *** All data will be lost *** \n\n    Format partition $part ?" 8 40 && format='yes'
if [ $format = 'yes' ] ; then
        # WARNING! FORMAT PARTITION
        #######################
        mkfs.ext4 $part
fi

# Partition mount
########################
mount $part /mnt
cd /mnt


# segunda tela // menu
#########################
while : ; do
        resposta=$(
        dialog --stdout                                 \
           --title ' *** INSTALL CONFIGURATION *** '              \
           --menu 'Choose your option:'                 \
           0 70 0                                                       \
	   full       '*8.2G Free disk (Xfce4 or i3wm)'                \
           minimal    'Minimall install, not X.'     \
           quit       'Exit install')
           #custom     'Choose softwares. (GIMP, QT5, LIBREOFFICE...)'  \

        # sair com cancelar ou esc
        quit

        case "$resposta" in
		full) resfull=$(dialog --stdout    \
                        --title 'FULL INSTALATION' \
                        --menu 'Choose your Desktop Enviroment:' \
                        0 0 0                       \
                        XFCE4 'Classic and powerfull!' \
                        i3WM 'Desktop for advanceds guys B).') 
                        case "$resfull" in
                                # TROCAR POR /MNT *********************
                                XFCE4) downloadwget "https://sourceforge.net/projects/mazonos/files/latest/download"
             				tarfull
                                        echo "ck-launch-session dbus-launch --exit-with-session startxfce4" > /mnt/etc/skel/.xinitrc 
					break ;;
                			

				i3WM) downloadwget "https://sourceforge.net/projects/mazonos/files/latest/download"
                                        tarfull
                                        echo "ck-launch-session dbus-launch --exit-with-session i3" > /mnt/etc/skel/.xinitrc 
					break ;;
                        esac ;;

                minimal) dialog --yesno 'The minimal version does not come from Xorg and DE.\nDo you confirm?' 0 0 && minimal='yes'
                        if [ $minimal = 'yes' ]; then
                        	cd /mnt
				downloadwget https://sourceforge.net/projects/mazonos/files/old-versions/mazonos-alpha-0.2.tar.bzip2/download
                                tar -xjpvf /mnt/mazonos-alpha-0.2.tar.bzip2 -C /mnt
				break
                        fi ;;

                custom) rescustom=$(dialog --stdout \
                        --separate-output \
                        --checklist 'Choose install softwares:' \
                        0 0 0                       \
                        LIBREOFFICE 'Office suite free' OFF \
                        GIMP 'GNU Image Manipulation Program' OFF  \
                        INKSCAPE 'Draw freely' OFF \
                        QT5 'Framework' OFF \
                        SUBLIME_TEXT 'Text editor for code' OFF \
                        VLC 'Player video' OFF \
                        OPENJDK 'Open Java' OFF \
                        TELEGRAM 'Communicator' OFF \
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
                quit) exit ;;
        esac
done
        # grub install
        #######################
        grubyes=
        dialog --title ' *** GRUB *** ' --yesno 'Would you like to install grub?\n\n*Remembering that we do not yet have dual bot support in our grub.\nIf use dualboot, use the grub from its other distribution with:\n# update-grub' 10 75 && grubyes='yes'
        if [ $grubyes = 'yes' ]; then
                grubinstall
                break
        else
                break
        fi

finish

clear
