#!/bin/bash

VARLIB="/var/lib/search-mazon"
SITE="http:/mazonos.com/packages/"

if [ $1 = "-u" ] || [ $1 = "--update" ]; then
	if [ -e "$VARLIB" ]; then
		cd $VARLIB
	else
		mkdir $VARLIB
		cd $VARLIB
	fi
	echo "Clean /var/lib/search-mazon/"
	rm -f *
	echo "Updating Folders..."
	printf "folders"
	wget -c -q http://mazonos.com/packages
	echo " [OK]"
	echo "Updating Packages..."
	# capture folders
	###########################
	folders=$(cat $VARLIB/packages | grep href | sed 's/      <a href="//g' | cut -d/ -f1 | more +2)
	cleanFolders=$(echo $folders | sed 's/<pre>?C=N;O=D">Name< //g')

	# capture files
	##########################
	for i in $cleanFolders; do
		declare -g ii=$i
		printf "$i"
		wget -c -q "http://mazonos.com/packages/$i"
		echo " [OK]"
		package=$(cat "$VARLIB/$i" | grep href | sed 's/      <a href="//g' | cut -d/ -f1 | sed 's/">.*<//g' | grep -v sha256 | more +2)
		cleanPackages=$(echo $package | sed 's/<pre>?C=N;O=D//g')

		for p in $cleanPackages; do
			echo "$ii/$p" >> list
		done
	done

	echo "All packages updated! Use: # search-mazon <package> for searching."

	exit
fi

# search
#########################
pkg=$(grep $1 $VARLIB/list)
pkgInstall=$(echo $pkg | cut -d"/" -f2)

if [ $? = 0 ]; then
	echo "--------------- RESULT ----------------"
	echo -e "\e[5m\e[42m\e[30m-FOUND-\e[0m $pkg"
	echo "---------------------------------------"
	echo ""
	read -p "Download? [Y/n]" download
	if [ $download = 'y' ] || [ $download = 'Y' ] || [[ $download = "" ]]; then
		cd /tmp/
		wget "http://mazonos.com/packages/$pkg"
		
		read -p "Install $pkg ? [Y/n]" install
		if [ $install = 'y' ] || [ $install = 'Y' ] || [[ $install = "" ]]; then
			banana -i $pkgInstall
		fi
	fi
fi

# return folder
cd - >/dev/null 2>&1
