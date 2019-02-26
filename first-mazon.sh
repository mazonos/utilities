#!/bin/bash
###############################################
#  first login Mazon OS - version 1.0         #
#                                             #
#  @utor: Diego Sarzi <diegosarzi@gmail.com>  #
#  created: 2019/02/26 licence: MIT           #
###############################################

echo -e "\nConfig Layout Keyboard... <PRESS ENTER>" ; read

#keymaps=( $( find /usr/share/keymaps/ -name "*.map.gz" | cut -d/ -f7 | sed -e "s/.map.gz/ [OK]/g" | sort ) )

keyboard=$(dialog --stdout \
        --backtitle 'Keyboard Layout:' \
	--menu 'Choose you keyboard:' 0 40 30 \
	ANSI-dvorak '' \
	applkey '' \
	azerty '' \
	backspace '' \
	bashkir '' \
	be-latin1 '' \
	bg_bds-cp1251 '' \
	bg_bds-utf8 '' \
	bg-cp1251 '' \
	bg-cp855 '' \
	bg_pho-cp1251 '' \
	bg_pho-utf8 '' \
	br-abnt '' \
	br-abnt2 '' \
	br-latin1-abnt2 '' \
	br-latin1-us '' \
	by '' \
	by-cp1251 '' \
	bywin-cp1251 '' \
	carpalx '' \
	carpalx-full '' \
	cf '' \
	croat '' \
	ctrl '' \
	cz '' \
	cz '' \
	cz-cp1250 '' \
	cz-lat2 '' \
	cz-lat2-prog '' \
	cz-us-qwertz '' \
	de '' \
	de_alt_UTF-8 '' \
	de_CH-latin1 '' \
	defkeymap '' \
	defkeymap_V1.0 '' \
	de-latin1 '' \
	de-latin1-nodeadkeys '' \
	de-mobii '' \
	dk '' \
	dk-latin1 '' \
	dvorak '' \
	dvorak-ca-fr '' \
	dvorak-es '' \
	dvorak-fr '' \
	dvorak-l '' \
	dvorak-la '' \
	dvorak-programmer '' \
	dvorak-r '' \
	dvorak-ru '' \
	dvorak-sv-a1 '' \
	dvorak-sv-a5 '' \
	dvorak-uk '' \
	emacs '' \
	emacs2 '' \
	en-latin9 '' \
	es '' \
	es '' \
	es-cp850 '' \
	et '' \
	et-nodeadkeys '' \
	euro '' \
	euro1 '' \
	euro2 '' \
	fi '' \
	fr '' \
	fr-bepo '' \
	fr-bepo-latin9 '' \
	fr_CH '' \
	fr_CH-latin1 '' \
	fr-latin1 '' \
	fr-latin9 '' \
	fr-pc '' \
	gr '' \
	gr-pc '' \
	hu '' \
	hu101 '' \
	il '' \
	il-heb '' \
	il-phonetic '' \
	is-latin1 '' \
	is-latin1-us '' \
	it '' \
	it2 '' \
	it-ibm '' \
	jp106 '' \
	kazakh '' \
	keypad '' \
	ky_alt_sh-UTF-8 '' \
	kyrgyz '' \
	la-latin1 '' \
	lt '' \
	lt.baltic '' \
	lt.l4 '' \
	lv '' \
	lv-tilde '' \
	mac-be '' \
	mac-de_CH '' \
	mac-de-latin1 '' \
	mac-de-latin1-nodeadkeys '' \
	mac-dk-latin1 '' \
	mac-dvorak '' \
	mac-es '' \
	mac-euro '' \
	mac-euro2 '' \
	mac-fi-latin1 '' \
	mac-fr '' \
	mac-fr_CH-latin1 '' \
	mac-it '' \
	mac-pl '' \
	mac-pt-latin1 '' \
	mac-se '' \
	mac-template '' \
	mac-uk '' \
	mac-us '' \
	mk '' \
	mk0 '' \
	mk-cp1251 '' \
	mk-utf '' \
	nl '' \
	nl2 '' \
	no '' \
	no '' \
	no-latin1 '' \
	pc110 '' \
	pl '' \
	pl1 '' \
	pl2 '' \
	pl3 '' \
	pl4 '' \
	pt '' \
	pt-latin1 '' \
	pt-latin9 '' \
	ro '' \
	ro_std '' \
	ro_win '' \
	ru '' \
	ru1 '' \
	ru2 '' \
	ru3 '' \
	ru4 '' \
	ru-cp1251 '' \
	ru-ms '' \
	ru_win '' \
	ruwin_alt-CP1251 '' \
	ruwin_alt-KOI8-R '' \
	ruwin_alt_sh-UTF-8 '' \
	ruwin_alt-UTF-8 '' \
	ruwin_cplk-CP1251 '' \
	ruwin_cplk-KOI8-R '' \
	ruwin_cplk-UTF-8 '' \
	ruwin_ctrl-CP1251 '' \
	ruwin_ctrl-KOI8-R '' \
	ruwin_ctrl-UTF-8 '' \
	ruwin_ct_sh-CP1251 '' \
	ruwin_ct_sh-KOI8-R '' \
	ruwin_ct_sh-UTF-8 '' \
	ru-yawerty '' \
	se-fi-ir209 '' \
	se-fi-lat6 '' \
	se-ir209 '' \
	se-lat6 '' \
	sg '' \
	sg-latin1 '' \
	sg-latin1-lk450 '' \
	sk-prog-qwerty '' \
	sk-prog-qwertz '' \
	sk-qwerty '' \
	sk-qwertz '' \
	slovene '' \
	sr-cy '' \
	sv-latin1 '' \
	tj_alt-UTF8 '' \
	tralt '' \
	trf '' \
	trf '' \
	tr_f-latin5 '' \
	trq '' \
	tr_q-latin5 '' \
	ttwin_alt-UTF-8 '' \
	ttwin_cplk-UTF-8 '' \
	ttwin_ctrl-UTF-8 '' \
	ttwin_ct_sh-UTF-8 '' \
	ua '' \
	ua-cp1251 '' \
	ua-utf '' \
	ua-utf-ws '' \
	ua-ws '' \
	uk '' \
	unicode '' \
	us '' \
	us-acentos '' \
	wangbe '' \
	wangbe2 '' \
	windowkeys ''
		)

if [ ! -z "$keyboard" ]; then
	#echo "KEYMAP='$keyboard'" >> /etc/sysconfig/console
	loadkeys $keyboard
fi

clear

# echo first login
#echo -e "\n*****************************"
#echo -e "First Login: \nuser: root password: root \n" 


# remove script
# rm -f /etc/rc.d/rc3.d/S1000first





