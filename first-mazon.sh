#!/bin/bash
###############################################
#  first login Mazon OS - version 1.0         #
#                                             #
#  @utor: Diego Sarzi <diegosarzi@gmail.com>  #
#  created: 2019/02/26 licence: MIT           #
###############################################

echo -e "\nConfig Layout Keyboard... <PRESS ENTER>" ; read

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
	#echo "KEYMAP='$keyboard'" >> /etc/sysconfig/console
	loadkeys $keyboard
fi

# clear

# echo first login
#echo -e "\n*****************************"
#echo -e "First Login: \nuser: root password: root \n" 


# remove script
# rm -f /etc/rc.d/rc3.d/S1000first
