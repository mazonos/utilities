#!/bin/bash
###############################################
#  first login Mazon OS - version 1.0         #
#                                             #
#  @utor: Diego Sarzi <diegosarzi@gmail.com>  #
#  created: 2019/02/26 licence: MIT           #
###############################################

### LANGUAGE SYSTEM
##########################################################################
#echo -e "\nConfig Language and layout keyboard system... <PRESS ENTER>" ; read

# get locales list
locales=( $( cat /etc/locale.gen | grep _ | sed 's/#//g' | sed 's/  $//g' | sed 's/ /./g' | awk 'NR>4'  ) )

# create array locales
array=()
n=-1
for i in ${locales[@]}; do
	n=($n+1)
	array[$n]=$i
	n=($n+1)
	array[$n]=''
done

# dialog locale choose item
language=$(dialog --stdout \
	--backtitle 'Languages System:' \
	--menu 'Choose you language:' 0 30 15 \
	"${array[@]}" )

# clean language selected
lang=$(echo $language | cut -d. -f1,2)

# get localge.gen list
localechange=$(cat /etc/locale.gen | grep -v "#")


if [ ! -z "$lang" ]; then
	sed "s/LANG=.*/LANG=$lang/g" /etc/profile.d/i18n.sh > /etc/profile.d/i18n.sh.change
	mv /etc/profile.d/i18n.sh.change /etc/profile.d/i18n.sh	
	# return "#" locale.gen
	sed "s/$localechange/#$localechange/g" /etc/locale.gen > /etc/locale.gen.change
	# remote "#" locale.gen selected
	sed "s/#$lang/$lang/g" /etc/locale.gen.change > /etc/locale.gen
	locale-gen
fi

### LAYOUT KEYBOARD
##########################################################################
keymaps=( $( find /usr/share/keymaps/ -name "*.map.gz" | cut -d/ -f7 | sed -e "s/.map.gz//g" | sort ) )

array=()
n=-1
for i in ${keymaps[@]}; do
	n=($n+1)
	array[$n]=$i
	n=($n+1)
	array[$n]=''
done

keyboard=$(dialog --stdout \
        --backtitle 'Keyboard Layout:' \
	--menu 'Choose you keyboard:' 0 30 15 \
	"${array[@]}" )

if [ ! -z "$keyboard" ]; then
	sed "s/KEYMAP=\".*\"/KEYMAP=\"$keyboard\"/g" /etc/sysconfig/console > /etc/sysconfig/console.change
	mv /etc/sysconfig/console.change /etc/sysconfig/console
	loadkeys $keyboard
fi

clear

echo "OK! Keyboard and language configured."

# echo first login
#echo -e "\n*****************************"
#echo -e "First Login: \nuser: root password: root \n" 


# remove script
# rm -f /etc/rc.d/rc3.d/S1000first
