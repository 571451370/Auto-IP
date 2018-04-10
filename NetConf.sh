#!/bin/bash


####Function####

For_The_Looks () {		##  just some cosmetic
	  line=#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!
}

Root_Check () {
	if [[ $EUID -eq 0 ]] ;then
		:
	else
		zenity --error --text "please run the script as root" --width 200
		exit
	fi
}

Zenity_Check () {
	if [[ -e /usr/bin/zenity ]] ;then
		:
	else
		printf "$line\n"
		printf "\#\!Please install zenity to run this script\#\!\n"
		printf "$line\n"
	fi
}

Distro_Check () {

	cat /etc/*-release |grep ID |cut  -d "=" -f "2" |egrep "^arch$|^manjaro$"

	if [[ $? -eq 0 ]] ;then
	  	Distro_Val="arch"
	else
	  	:
	fi

	  cat /etc/*-release |grep ID |cut  -d "=" -f "2" |egrep "^debian$"

	  if [[ $? -eq 0 ]] ;then
	    	Distro_Val="debian"
	  else
	    	:
	  fi

	cat /etc/*-release |grep ID |cut  -d "=" -f "2" |egrep "^\"centos\"$|^\"fedora\"$"

	if [[ $? -eq 0 ]] ;then
	   	Distro_Val="centos"
	else
		:
	fi
}

Static_IP () {
	Distro_Check
	local IFS="."
    IP_Val=($(zenity --entry --text "Please enter an IP address" --title "IP setup" --width "400" ))

	if [[ $? -eq 1 ]] ;then
      	exit
    else
      	:
    fi

    until [[ ${IP_Val[0]} -le 254 ]] && [[ ${IP_Val[0]} -ge 1 ]] && \
	[[ ${IP_Val[1]} -le 254 ]] && [[ ${IP_Val[1]} -ge 0 ]] && \
	[[ ${IP_Val[2]} -le 254 ]] && [[ ${IP_Val[2]} -ge 0 ]] && \
	[[ ${IP_Val[3]} -le 254 ]] && [[ ${IP_Val[3]} -ge 0 ]] && \
	[[ ${#IP_Val[@]} -eq 4 ]] ;do
	      zenity --error --text "Is it that hard to enter a valid address? try agin..." --width "200"
	      IP_Val=($(zenity --entry --text "Please enter an IP address" --title "IP setup" --width "400" ))
		  if [[ $? -eq 1 ]] ;then
			  exit
		  else
			  :
		  fi
    done

    NetMask_Val=($(zenity --entry --text "Please enter Net Mask" --title "IP setup" --width "400"))

	if [[ $? -eq 1 ]] ;then
		exit
	else
		:
	fi
    until [[ ${NetMask_Val[0]} -le 255 ]] && [[ ${NetMask_Val[0]} -ge 0 ]] && \
	[[ ${NetMask_Val[1]} -le 255 ]] && [[ ${NetMask_Val[1]} -ge 0 ]] && \
	[[ ${NetMask_Val[2]} -le 255 ]]  && [[ ${NetMask_Val[2]} -ge 0 ]] && \
	[[ ${NetMask_Val[3]} -le 255 ]] && [[ ${NetMask_Val[3]} -ge 0 ]] && \
	[[ ${#NetMask_Val[@]} -eq 4 ]] ;do
	      zenity --error --text "Is it that hard to enter a valid netmask? try agin..." --width "200"
	      NetMask_Val=($(zenity --entry --text "Please enter Net Mask" --title "IP setup" --width "400"))
		  if [[ $? -eq 1 ]] ;then
			  exit
		  else
			  :
		  fi
    done

	Gateway_Val=($(zenity --entry --text "Please enter Gateway" --title "IP setup" --width "400"))

	if [[ $? -eq 1 ]] ;then
		exit
	else
		:
	fi
	until [[ ${Gateway_Val[0]} -le 254 ]] && [[ ${Gateway_Val[0]} -ge 0 ]] && \
	[[ ${Gateway_Val[1]} -le 254 ]] && [[ ${Gateway_Val[1]} -ge 0 ]] && \
	[[ ${Gateway_Val[2]} -le 254 ]]  && [[ ${Gateway_Val[2]} -ge 0 ]] && \
	[[ ${Gateway_Val[3]} -le 254 ]] && [[ ${Gateway_Val[3]} -ge 0 ]] && \
	[[ ${#Gateway_Val[@]} -eq 4 ]] ;do
		  zenity --error --text "Is it that hard to enter a valid netmask? try agin..." --width "200"
		  NetMask_Val=($(zenity --entry --text "Please enter Net Mask" --title "IP setup" --width "400"))
		  if [[ $? -eq 1 ]] ;then
			  exit
		  else
			  :
		  fi
	done

	if [[ $Distro_Val =~ "centos" ]] ;then
		int_name=$(ip a |grep -Eo 'enp[0-9{1,4}]s[0-9{1,4}]' |head -1)
		int_path=/etc/sysconfig/network-scripts/ifcfg-$int_name

		sed -ie 's/BOOTPROTO=.*/BOOTPROTO="static"/' $int_path

		cat $int_path |egrep "^IPADDR|^NETMASK" &> /dev/null

		if [[ $? -eq 0 ]] ;then
			sed -ie "s/IPADDR=.*/IPADDR=${IP_Val[*]}/" $int_path
			sed -ie "s/NETMASK=.*/NETMASK=${NetMask_Val[*]}/" $int_path
		else
		    printf "IPADDR=${IP_Val[*]}\n" >> $int_path
		    printf "NETMASK=${NetMask_Val[*]}\n" >> $int_path
		fi

		cat $int_path |egrep "^GATEWAY" &> /dev/null

		if [[ $? -eq 0 ]] ;then
			sed -ie "s/GATEWAY=.*/GATEWAY=${Gateway_Val[*]}/" $int_path
		else
			printf "GATEWAY=${Gateway_Val[*]}\n" >> $int_path
		fi
		systemctl restart network
		if [[ $? -eq 0 ]] ;then
			zenity --info --text "IP configuration completed successfully" --width 250
			menu
		else
			zenity --error --text "Something went wrong trying to restart the \"network\" service" --width 250
		fi

	elif [[ $Distro_Val =~ "debian" ]] ;then
		int_name=$(ip a |grep -Eo 'enp[0-9{1,4}]s[0-9{1,4}]' |head -1)
		int_path=/etc/network/interfaces

		cat /etc/network/interfaces |egrep -Eo "^iface $int_name inet static$" &> /dev/null

		if [[ $? -eq 0 ]] ;then
			sed -ie "s/address.*/address $IP_Val/" $int_path
			sed -ie "s/netmask.*/netmask $NetMask_Val/" $int_path

			cat $int_path |egrep -Eo "gateway" &> /dev/null
			if [[ $? -eq 0 ]] ;then
				sed -ie "s/gateway.*/gateway ${Gateway_Val[*]}" $int_path
			else
				printf "gateway ${Gateway_Val[*]}\n" >> $int_path
			fi

		else
			cat $int_path |egrep -Eo "^iface $int_name inet dhcp$" &> /dev/null
			if [[ $? -eq 0 ]] ;then
				sed -ie "s/iface $int_name inet dhcp/iface $int_name inet static" $int_path
				printf "\taddress ${IP_Val[*]}\n \tnetmask ${NetMask_Val[*]}\n \tgateway ${Gateway_Val[*]}\n" >> $int_path
			else
				printf "iface $int_name inet static\n" >> $int_path
				printf "\taddress ${IP_Val[*]}\n \tnetmask ${NetMask_Val[*]}\n \tgateway ${Gateway_Val[*]}\n" >> $int_path
			fi
		fi

		systemctl stop NetworkManager
		if [[ $? -eq 0 ]] ;then
			:
		else
			zenity --error --text "Something went wrong while stoping the \"NetworkManager\" service" --width 250
		fi

		systemctl disable NetworkManager
		if [[ $? -eq 0 ]] ;then
			:
		else
			zenity --error --text "Something went wrong while trying to disable the \"NetworkManager\" service" --width 250
		fi

		ip addr flush dev $int_name
		if [[ $? -eq 0 ]] ;then
			:
		else
			zenity --error --text "Something went wrong while trying to flush the ip on $int_name" --width 250
		fi

		systemctl restart networking
		if [[ $? -eq 0 ]] ;then
			zenity --info --text "IP configuration completed successfully" --width 250
		else
			zenity --error --text "Something went wrong while trying to restart the \"networking\" service" --width 250
		fi

	else
		printf "Sorry but this script does not support your system\n"
	fi


}


Static_DNS () {
	Distro_Check
	local IFS="."

	DNS1_Val=($(zenity --entry --text "Please enter main DNS server" --title "DNS setup" --width "400" ))

	if [[ $? -eq 1 ]] ;then
		exit
	else
		:
	fi

	until [[ ${DNS1_Val[0]} -le 254 ]] && [[ ${DNS1_Val[0]} -ge 1 ]] && \
	[[ ${DNS1_Val[1]} -le 254 ]] && [[ ${DNS1_Val[1]} -ge 0 ]] &&\
	[[ ${DNS1_Val[2]} -le 254 ]] && [[ ${DNS1_Val[2]} -ge 0 ]] && \
	[[ ${DNS1_Val[3]} -le 254 ]] && [[ ${DNS1_Val[3]} -ge 0 ]] && \
	[[ ${#DNS1_Val[@]} -eq 4 ]] ;do
		  zenity --error --text "If it's so hard to enter a valid DNS server try  8.8.8.8 or something idk..." --width "200"
		  DNS1_Val=($(zenity --entry --text "Please enter main DNS server" --title "DNS setup" --width "400" ))
		  if [[ $? -eq 1 ]] ;then
			  exit
		  else
			  :
		  fi
	done

	DNS2_Val=($(zenity --entry --text "Please enter secondary DNS server" --title "DNS setup" --width "400" ))

	if [[ $? -eq 1 ]] ;then
		exit
	else
		:
	fi

	until [[ ${DNS2_Val[0]} -le 254 ]] && [[ ${DNS2_Val[0]} -ge 1 ]] && \
	[[ ${DNS2_Val[1]} -le 254 ]] && [[ ${DNS2_Val[1]} -ge 0 ]] &&\
	[[ ${DNS2_Val[2]} -le 254 ]] && [[ ${DNS2_Val[2]} -ge 0 ]] && \
	[[ ${DNS2_Val[3]} -le 254 ]] && [[ ${DNS2_Val[3]} -ge 0 ]] && \
	[[ ${#DNS2_Val[@]} -eq 4 ]] ;do
		  zenity --error --text "If it's so hard to enter a valid secondary DNS server try  8.8.4.4 or something idk..." --width "200"
		  DNS2_Val=($(zenity --entry --text "Please enter secondary DNS server" --title "DNS setup" --width "400" ))
		  if [[ $? -eq 1 ]] ;then
			  exit
		  else
			  :
		  fi
	done

	if [[ $Distro_Val =~ "centos" ]] ;then
		int_name=$(ip a |grep -Eo 'enp[0-9{1,4}]s[0-9{1,4}]' |head -1)
		int_path=/etc/sysconfig/network-scripts/ifcfg-$int_name

		cat $int_path |egrep -Eo "^DNS1" &> /dev/null
		if [[ $? -eq 0 ]] ;then
			sed -ie "s/DNS1=.*/DNS1=${DNS1_Val[*]}/ $int_path"
		else
			printf "DNS1=${DNS1_Val[*]}\n" >> $int_path
		fi

		cat $int_path |egrep -Eo "^DNS2" &> /dev/null
		if [[ $? -eq 0 ]] ;then
			sed -ie "s/DNS2=.*/DNS2=${DNS2_Val[*]}/ $int_path"
		else
			printf "DNS2=${DNS2_Val[*]}\n" >> $int_path
		fi

		systemctl restart network
		if [[ $? -eq 0 ]] ;then
			zenity --info --text "IP configuration completed successfully" --width 250
			menu
		else
			zenity --error --text "Something went wrong trying to restart the \"network\" service" --width 250
		fi

	elif [[ $Distro_Val =~ "debian" ]]; then
		int_name=$(ip a |grep -Eo 'enp[0-9{1,4}]s[0-9{1,4}]' |head -1)
		int_path=/etc/sysconfig/network-scripts/ifcfg-$int_name

		cat $int_path |egrep -Eo "dns-servers"
		if [[ $? -eq 0 ]] ;then
			sed -ie "s/dns-servers.*/dns-servers ${DNS1_Val[*]} ${DNS2_Val[*]}/" $int_path
		else
			printf "\tdns-servers ${DNS1_Val[*]} ${DNS2_Val[*]}\n" >> $int_path
		fi

		systemctl stop NetworkManager
		if [[ $? -eq 0 ]] ;then
			:
		else
			zenity --error --text "Something went wrong while stoping the \"NetworkManager\" service" --width 250
		fi

		systemctl disable NetworkManager
		if [[ $? -eq 0 ]] ;then
			:
		else
			zenity --error --text "Something went wrong while trying to disable the \"NetworkManager\" service" --width 250
		fi

		ip addr flush dev $int_name
		if [[ $? -eq 0 ]] ;then
			:
		else
			zenity --error --text "Something went wrong while trying to flush the ip on $int_name" --width 250
		fi

		systemctl restart networking
		if [[ $? -eq 0 ]] ;then
			zenity --info --text "IP configuration completed successfully" --width 250
		else
			zenity --error --text "Something went wrong while trying to restart the \"networking\" service" --width 250
		fi

		else
			printf "Sorry but this script does not support your system\n"
		fi
	fi

}


menu () {
	Root_Check
	Zenity_Check

	Menu_Val=$(zenity --list \
	--text "What would you like to configure?" --title "Network configuration"  \
	--column=Script --column="Description" \
	--width 400 --height 400 "IP" "configure static IP address" "DNS" "Configure static main and scondary DNS servers")

	if [[ $Menu_Val =~ "IP" ]] ;then
		Static_IP
	elif [[ $Menu_Val =~ "DNS" ]]; then
		Static_DNS
	else
		exit
	fi
}

menu
