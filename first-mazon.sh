#!/bin/bash
###############################################
#  first login Mazon OS - version 1.0         #
#                                             #
#  @utor: Diego Sarzi <diegosarzi@gmail.com>  #
#  created: 2019/02/26 licence: MIT           #
###############################################

keymaps=$(find /usr/share/keymaps/ -name "*.map.gz" | cut -d/ -f7 | sed 's/.map.gz//g'| sort)

keyboard=$(dialog --stdout \
	--backtitle 'Ajust keyboard layout:' \
	--menu 'Choose you keyboard:' 0 0 0 \
	"${keymaps[@]}" "")

if [ ! -z "$keyboard" ]; then
	loadkeys $keyboard
fi

# echo first login
echo -e "\n*****************************"
echo -e "First Login: \nuser: root password: root \n" 


# remove script
# rm -f /etc/rc.d/rc3.d/S1000first





