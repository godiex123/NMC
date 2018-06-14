#!/bin/bash

function f_banner {
	
echo -e "\e[1;32m		########################################################################
					** Network_Configurator **
     				Make a Static o DHCP configuration easely 
					    By: DiegoSantiago
						version 1.0			   
     		########################################################################\e[0m"
echo
echo

}


function f_backup {
	
	if [ ! -f /etc/network/interfaces.original ]; then
		echo -e "\e[1;31m\tBackup generated and saved as interfaces.original\e[0m"
		cp /etc/network/interfaces /etc/network/interfaces.original
		sleep 2
	fi
}


function f_main {

	echo -e "\e[1;36m\tConfiguration Menu\e[0m"
	echo
	echo -e "\t1. Show Available interfaces"
	echo -e "\t2. Configure a Static IP"
	echo -e "\t3. Configure an IP by DHCP"
	echo -e "\t4. Exit"
	echo
	echo -e -n "\t-> "
	read OPCION
	echo

	case $OPCION in
		1)
			f_showInterfaces
		;;
		2)
			STATIC=1
			f_check
		;;
		3)
			DHCP=1
			f_check
		;;
		4)
			f_msjes 2
			exit 0
		;;
		*)
			f_error 3
		;;
	esac
}


function f_showInterfaces {

	clear
	echo -e "\e[1;36m\tInterfaces available on your system: \e[0m"
	echo
	for i in `lshw -short -C network|grep -e et -e wl -e en|tr -s " "|cut -f2 -d " "`
	do
		echo "\t     -> $i"
	done
	echo
	echo
	echo -n -e "\tBack to Main Menu? (Y/N) "
        read OPTION
	f_backMenu $OPTION
}


function f_backMenu {

	OPT=$1
	case $OPT in
		y|Y)
			clear
			f_banner
			f_main
		;;
		n|N)
			f_msjes 2
			exit 0
		;;
	esac

}


function f_check {
	
	read -p "-> Interface: " INTERF
	IFACE=`lshw -short -C network|grep -e et -e wl -e en|tr -s " "|cut -f2 -d " "`
	if test -z $INTERF; then
		echo
		f_error 1
		echo
		f_check
	fi
	
	VALIDACION=0
	
	for v in $IFACE
	do
		if [ "$v" = "$INTERF"  ]; then
			VALIDACION=1
			echo
			echo -e "\e[1;32m\t--> :D OK <--\e[0m"
			sleep 2
			f_structure
		fi
	done

	if [ "$VALIDACION" = "0" ]; then
		echo
		f_error 2
		echo
		f_check
	fi
}

function f_error {
	
	error_code=$1
	case $error_code in
		1)
			echo -e "\e[1;31m\t** :( Error: Blank space  **\e[0m"
		;;
		2)
			echo -e "\e[1;31m\t** :( Error: Invalid interface\e[0m"
			;;
		3)
			echo -e "\e[1;31m\t** :( Error: Invalid option\e[0m"
			;;
	esac

}


function f_structure {
	
	ARCHIVO="/etc/network/interfaces" 
	IDENT=`cat $ARCHIVO|grep -w -c -e Network_Configurator`

	if test "$IDENT" = "0"; then
		f_newBody
	else
		if [ $STATIC -eq 1  ]; then
			f_ipData
		elif [ $DHCP -eq 1 ]; then
			f_dhcpConfig
		fi
	fi
}	


function f_newBody {

	echo " " > $ARCHIVO
	echo "#Network_Configurator - By DiegoSantiago " >> $ARCHIVO
	echo >> $ARCHIVO
	echo "#Hola and Thanks for use this tool, in case of emergency use the original file renamed (interfaces.original)" >> $ARCHIVO
	echo >> $ARCHIVO
	echo "#--> begin_lo" >> $ARCHIVO
	echo >> $ARCHIVO
	echo "auto lo" >> $ARCHIVO
	echo "iface lo inet loopback" >> $ARCHIVO
	echo >> $ARCHIVO
	echo "#--> end_lo" >> $ARCHIVO

	if [ $STATIC -eq 1 ]; then
		f_ipData
	elif [ $DHCP -eq 1 ]; then
		f_dhcpConfig
	fi
}


function f_ipData {

	clear
	echo -e "\e[1;36m\tIntroduce IP data:  \e[0m"
	echo
	echo -n *-e "\tIP Address: " 
	read IP
	echo -n -e "\tNetmask: " 
	read MASK
        echo -n -e "\tNetwork: " 
	read NET
	echo -n -e "\tGateway: " 
	read GATEWAY

	f_statiConfig $IP $MASK $NET $GATEWAY	
}


function f_statiConfig {

	VRF=`cat $ARCHIVO|grep -c -w -e begin_$INTERF`
	if [ "$VRF" = "1" ]; then
		sed -i "/begin_$INTERF/,/end_$INTERF/d" $ARCHIVO
	fi

	echo "#--> begin_$INTERF" >> $ARCHIVO
	echo >> $ARCHIVO
	echo "auto $INTERF" >> $ARCHIVO
	echo "iface $INTERF inet static" >> $ARCHIVO
	echo "address "$1 >> $ARCHIVO
	echo "netmask "$2 >> $ARCHIVO
	echo "network "$3 >> $ARCHIVO
	echo "gateway "$4 >> $ARCHIVO
	echo >> $ARCHIVO
	echo "#--> end_$INTERF" >> $ARCHIVO

	STATIC=0
	echo
	sudo service networking restart
	f_msjes 1
	echo
	echo -n -e "\tBack to Main Menu? (Y/N):  "
	read OPTION 
	f_backMenu $OPTION
}


function f_dhcpConfig {

	VRF=`cat $ARCHIVO|grep -c -w -e begin_$INTERF`
	if [ "$VRF" = "1" ]; then
		sed -i "/begin_$INTERF/,/end_$INTERF/d" $ARCHIVO
	fi

	echo "#--> begin_$INTERF" >> $ARCHIVO
	echo >> $ARCHIVO
	echo "auto $INTERF" >> $ARCHIVO 
	echo "iface $INTERF inet dhcp" >> $ARCHIVO
	echo >> $ARCHIVO
	echo "#--> end_$INTERF" >> $ARCHIVO
	sudo service networking restart
	f_msjes 1
	echo
	DHCP=0
	echo -n -e "\tBack to Main Menu? (Y/N):  " 
	read OPTION
	f_backMenu $OPTION

}


function f_msjes {

	msje=$1
	case $msje in
		1)
			echo -e "\e[1;32m\t--> :D Configuration successfully <--\e[0m"
		;;
		2)
			echo
			echo -e "\e[1;32m\t** Thanks for use NC, See ya! :) **\e[0m"
		;;
	esac
}


STATIC=0
DHCP=0

if [ $LOGNAME = "root" ]; then
	while true; do
		f_banner
		f_backup
		f_main
	done
else
	echo -e "\e[1;31m ** Permission denied: You must be a user with privileges! **\e[0m"
fi
