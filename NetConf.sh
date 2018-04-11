#!/bin/bash


####Function####

For_The_Looks () {		## for decoration output only
	  line=#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!
}

Root_Check () {		## checks that the script runs as root
	if [[ $EUID -eq 0 ]] ;then
		:
	else
		zenity --error --text "please run the script as root" --width 200
		exit
	fi
}

Zenity_Check () {		## checks that zenity is installed
	if [[ -e /usr/bin/zenity ]] ;then
		:
	else
		printf "$line\n"
		printf "\#\!Please install zenity to run this script\#\!\n"
		printf "$line\n"
	fi
}

Distro_Check () {		## checking the environment the user is currenttly running on to determine which settings should be applied

	cat /etc/*-release |grep ID |cut  -d "=" -f "2" |egrep "^arch$|^manjaro$"

	if [[ $? -eq 0 ]] ;then
	  	Distro_Val="arch"
	else
	  	:
	fi

	  cat /etc/*-release |grep ID |cut  -d "=" -f "2" |egrep "^debian$|^\"Ubuntu\"$"

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

Static_IP () {		## configure static IP
	Distro_Check
	local IFS="."		## sets the internal field separator to "." so we could inspect the data from the user as elements in an array
  IP_Val=($(zenity --entry --text "Please enter an IP address" --title "IP setup" --width "400" ))		## prompte the gui for the user to enter an IP and puts it into a variabl

	if [[ $? -eq 1 ]] ;then		## check with exit status if the user wants to exit the script
      	exit
    else
      	:
    fi

	## validation check for correct IP value
	until [[ ${IP_Val[0]} -le 254 ]] && [[ ${IP_Val[0]} -ge 1 ]] && \
	[[ ${IP_Val[1]} -le 254 ]] && [[ ${IP_Val[1]} -ge 0 ]] && \
	[[ ${IP_Val[2]} -le 254 ]] && [[ ${IP_Val[2]} -ge 0 ]] && \
	[[ ${IP_Val[3]} -le 254 ]] && [[ ${IP_Val[3]} -ge 0 ]] && \
	[[ ${#IP_Val[@]} -eq 4 ]] ;do
    zenity --error --text "Is it that hard to enter a valid address? try agin..." --width "200"
    IP_Val=($(zenity --entry --text "Please enter an IP address" --title "IP setup" --width "400" ))
	  if [[ $? -eq 1 ]] ;then		## check with exit status if the user wants to exit the script
		  exit
	  else
		  :
	  fi
  done

  NetMask_Val=($(zenity --entry --text "Please enter Net Mask" --title "IP setup" --width "400"))		## prompte the gui for the user to enter NetMask and puts it into a variable

	if [[ $? -eq 1 ]] ;then		## check with exit status if the user wants to exit the script
		exit
	else
		:
	fi

	## validation check for correct NetMask value
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

	Gateway_Val=($(zenity --entry --text "Please enter Gateway" --title "IP setup" --width "400"))		## prompte the gui for the user to enter a gateway and puts it into a variable

	if [[ $? -eq 1 ]] ;then		## check with exit status if the user wants to exit the script
		exit
	else
		:
	fi

	## validation check for correct gateway value
	until [[ ${Gateway_Val[0]} -le 254 ]] && [[ ${Gateway_Val[0]} -ge 0 ]] && \
	[[ ${Gateway_Val[1]} -le 254 ]] && [[ ${Gateway_Val[1]} -ge 0 ]] && \
	[[ ${Gateway_Val[2]} -le 254 ]]  && [[ ${Gateway_Val[2]} -ge 0 ]] && \
	[[ ${Gateway_Val[3]} -le 254 ]] && [[ ${Gateway_Val[3]} -ge 0 ]] && \
	[[ ${#Gateway_Val[@]} -eq 4 ]] ;do
	  zenity --error --text "Is it that hard to enter a valid netmask? try agin..." --width "200"
	  NetMask_Val=($(zenity --entry --text "Please enter Net Mask" --title "IP setup" --width "400"))
	  if [[ $? -eq 1 ]] ;then				## validation check for correct gateway value
		  exit
	  else
		  :
	  fi
	done

	if [[ $Distro_Val =~ "centos" ]] ;then		## checks the user's environment
		int_name=$(ip a |grep -Eo 'enp[0-9{1,4}]s[0-9{1,4}]' |head -1)		## gets the interface name into a variable
		int_path=/etc/sysconfig/network-scripts/ifcfg-$int_name		## gets the interface's configuration file path into a variable (this is just for convenience purposes)
		cat $int_path > $int_path.bck		## makes a backup file of the interface configuration incase something goes wrong

		sed -ie 's/BOOTPROTO=.*/BOOTPROTO="static"/' $int_path		## sets static configuration in the configuration file of the interface (*confusing sentence isn't it? ;D)
		cat $int_path |egrep "^IPADDR|^NETMASK" &> /dev/null		## checks if static configuration has already exist and throws the stdout and stderr to /dev/null

		## checks exit status of last command to determine the next course of action,
		## if static configuration exists, fix it, if not, append static configuration
		if [[ $? -eq 0 ]] ;then
			sed -ie "s/IPADDR=.*/IPADDR=${IP_Val[*]}/" $int_path
			sed -ie "s/NETMASK=.*/NETMASK=${NetMask_Val[*]}/" $int_path
		else
		    printf "IPADDR=${IP_Val[*]}\n" >> $int_path
		    printf "NETMASK=${NetMask_Val[*]}\n" >> $int_path
		fi

		cat $int_path |egrep "^GATEWAY" &> /dev/null		## checks if static configuration has already exist

		## checks exit status of last command to determine the next course of action,
		## if static configuration exists, fix it, if not, append static configuration
		if [[ $? -eq 0 ]] ;then
			sed -ie "s/GATEWAY=.*/GATEWAY=${Gateway_Val[*]}/" $int_path
		else
			printf "GATEWAY=${Gateway_Val[*]}\n" >> $int_path
		fi
		## restart the network service
		(
		sleep 1
		systemctl restart network
		) |
		zenity --progress --title "Net Config" --text "Restarting the network service" --pulsate --auto-close --width 250
		if [[ $? -eq 0 ]] ;then		## validating if the network service has restarted successfully with exit status, if not fall back to previews configuration
			zenity --info --text "IP configuration completed successfully" --width 250
			menu
		else
			cat $int_path.bck > $int_path		## restores the configuration file to previews state
			(
			## trys again to restart the service with previews configuration, if it secceed it lets the user know that something went wrong
			## while configuring the network file, if it doesn't, it lets the user know that the current configuring could not be applied
			## and the previews configuration could not be apllied, it also suggests the user to check the conf file by himself.
			sleep 1
			systemctl restart network
			) |
			zenity --progress --title "Net Config" --text "Restarting the network service with old config" --pulsate --auto-close --width 250
			if [[ $? -eq 0 ]] ;then
				zenity --error --text "Something went wrong while restarting the \"network\" service, falling back to previews state." --width 250
			else
				zenity --error --text "Something went wrong while restarting the \"network\" service, \
				could not resolve the issue even when falling back to previews state, please check your configuration file at $int_path" --width 250
			fi
		fi

	elif [[ $Distro_Val =~ "debian" ]] ;then		## checks the user's environment
		int_name=$(ip a |grep -Eo 'enp[0-9{1,4}]s[0-9{1,4}]' |head -1)		## gets the interface name into a variable
		int_path=/etc/network/interfaces				## gets the interface's configuration file path into a variable (this is just for convenience purposes)
		cat $int_path > $int_path.bck		## makes a backup file of the interfaces configuration  incase something goes wrong

		cat $int_path |egrep -Eo "^iface $int_name inet static$" &> /dev/null		## checks if static configuration has already exist and throws the stdout and stderr to /dev/nul

		## checks exit status of last command to determine the next course of action,
		## if static configuration exists, fix it, if not, append static configuration
		if [[ $? -eq 0 ]] ;then
			sed -ie "s/address.*/address ${IP_Val[*]}/" $int_path
			sed -ie "s/netmask.*/netmask ${NetMask_Val[*]}/" $int_path

			cat $int_path |egrep -Eo "gateway" &> /dev/null		## checks if static configuration has already exist

			## checks exit status of last command to determine the next course of action,
			## ןf static configuration exists, fix it, if not, append static configuration
			if [[ $? -eq 0 ]] ;then
				sed -ie "s/gateway.*/gateway ${Gateway_Val[*]}/" $int_path
			else
				printf "gateway ${Gateway_Val[*]}\n" >> $int_path
			fi

		else
			cat $int_path |egrep -Eo "^iface $int_name inet dhcp$" &> /dev/null

			## checks exit status of last command to determine the next course of action,
			## if static configuration exists, fix it, if not, append static configuration
			if [[ $? -eq 0 ]] ;then
				sed -ie "s/iface $int_name inet dhcp/iface $int_name inet static/" $int_path
				printf "\taddress ${IP_Val[*]}\n \tnetmask ${NetMask_Val[*]}\n \tgateway ${Gateway_Val[*]}\n" >> $int_path
			else
				printf "iface $int_name inet static\n" >> $int_path
				printf "\taddress ${IP_Val[*]}\n \tnetmask ${NetMask_Val[*]}\n \tgateway ${Gateway_Val[*]}\n" >> $int_path
			fi
		fi

		(
		systemctl stop NetworkManager		## kills the NetworkManager service so it will not interfere with the networking service
		if [[ $? -eq 0 ]] ;then		## validating if the NetworkManager service has stoped successfully with exit status, if not fall back to previews configuration
			:
		else
			zenity --error --text "Something went wrong while stoping the \"NetworkManager\" service" --width 250
			cat $int_path.bck > $int_path
		fi

		systemctl disable NetworkManager		## Disables the NetworkManager service from starting upon startup so it will not interfere with the networking service
		if [[ $? -eq 0 ]] ;then		## validating if the NetworkManager service has been disabled successfully with exit status, if not fall back to previews configuration
			:
		else
			zenity --error --text "Something went wrong while trying to disable the \"NetworkManager\" service" --width 250
			cat $int_path.bck > $int_path
		fi

		ip addr flush dev $int_name		## flushes the interface's current IP address so it will not duplicate or interfere the new settings
		if [[ $? -eq 0 ]] ;then		## validating if the interface has flushed its IP address successfully with exit status, if not fall back to previews configuration
			:
		else
			zenity --error --text "Something went wrong while trying to flush the ip on $int_name" --width 250
			cat $int_path.bck > $int_path
		fi

		systemctl restart networking			## restart the networking service
		if [[ $? -eq 0 ]] ;then		## validating if the networking service has restarted successfully with exit status, if not fall back to previews configuration
			zenity --info --text "IP configuration completed successfully" --width 250
			menu
		else
			cat $int_path.bck > $int_path		## restores the configuration file to previews state
			(
			## trys again to restart the service with previews configuration, if it secceed it lets the user know that something went wrong
			## while configuring the network file, if it doesn't, it lets the user know that the current configuring could not be applied
			## and the previews configuration could not be apllied, it also suggests the user to check the conf file by himself.
			sleep 1
			systemctl restart networking
			) |
			zenity --progress --title "Net Config" --text "Restarting the network service with old config" --pulsate --auto-close --width 250
			if [[ $? -eq 0 ]] ;then
				zenity --error --text "Something went wrong while restarting the \"network\" service, falling back to previews state." --width 250
			else
				zenity --error --text "Something went wrong while restarting the \"network\" service, \
				could not resolve the issue even when falling back to previews state, please check your configuration file at $int_path" --width 250
			fi
		fi
		) |
		zenity --progress --title "Net Config" --text "Re-configuring network services" --pulsate --auto-close --width 250

	else
		printf "Sorry but this script does not support your system\n"
	fi


}


Static_DNS () {		## configure static DNS (follow the Static_IP function for documentation, it has the same principles)
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
		cat $int_path > $int_path.bck

		cat $int_path |egrep -Eo "^DNS1" &> /dev/null
		if [[ $? -eq 0 ]] ;then
			sed -ie "s/DNS1=.*/DNS1=${DNS1_Val[*]}/" $int_path
		else
			printf "DNS1=${DNS1_Val[*]}\n" >> $int_path
		fi

		cat $int_path |egrep -Eo "^DNS2" &> /dev/null
		if [[ $? -eq 0 ]] ;then
			sed -ie "s/DNS2=.*/DNS2=${DNS2_Val[*]}/" $int_path
		else
			printf "DNS2=${DNS2_Val[*]}\n" >> $int_path
		fi

		(
		sleep 1
		systemctl restart network
		) |
		zenity --progress --title "Net Config" --text "Restarting the network service" --pulsate --auto-close --width 250
		if [[ $? -eq 0 ]] ;then		## validating if the network service has restarted successfully with exit status, if not fall back to previews configuration
			zenity --info --text "IP configuration completed successfully" --width 250
			menu
		else
			cat $int_path.bck > $int_path
			(
			sleep 1
			systemctl restart network
			) |
			zenity --progress --title "Net Config" --text "Restarting the network service with old config" --pulsate --auto-close --width 250
			if [[ $? -eq 0 ]] ;then
				zenity --error --text "Something went wrong while restarting the \"network\" service, falling back to previews state." --width 250
			else
				zenity --error --text "Something went wrong while restarting the \"network\" service, \
				could not resolve the issue even when falling back to previews state, please check your configuration file at $int_path" --width 250
			fi
		fi

	elif [[ $Distro_Val =~ "debian" ]]; then
		int_name=$(ip a |grep -Eo 'enp[0-9{1,4}]s[0-9{1,4}]' |head -1)
		int_path=/etc/network/interfaces
		cat $int_path > $int_path.bck

		cat $int_path |egrep -Eo "dns-servers"
		if [[ $? -eq 0 ]] ;then
			sed -ie "s/dns-servers.*/dns-servers ${DNS1_Val[*]} ${DNS2_Val[*]}/" $int_path
		else
			printf "\tdns-servers ${DNS1_Val[*]} ${DNS2_Val[*]}\n" >> $int_path
		fi

		(
		systemctl stop NetworkManager		## kills the NetworkManager service so it will not interfere with the networking service
		if [[ $? -eq 0 ]] ;then		## validating if the NetworkManager service has stoped successfully with exit status, if not fall back to previews configuration
			:
		else
			zenity --error --text "Something went wrong while stoping the \"NetworkManager\" service" --width 250
			cat $int_path.bck > $int_path
		fi

		systemctl disable NetworkManager		## Disables the NetworkManager service from starting upon startup so it will not interfere with the networking service
		if [[ $? -eq 0 ]] ;then		## validating if the NetworkManager service has been disabled successfully with exit status, if not fall back to previews configuration
			:
		else
			zenity --error --text "Something went wrong while trying to disable the \"NetworkManager\" service" --width 250
			cat $int_path.bck > $int_path
		fi

		ip addr flush dev $int_name		## flushes the interface's current IP address so it will not duplicate or interfere the new settings
		if [[ $? -eq 0 ]] ;then		## validating if the interface has flushed its IP address successfully with exit status, if not fall back to previews configuration
			:
		else
			zenity --error --text "Something went wrong while trying to flush the ip on $int_name" --width 250
			cat $int_path.bck > $int_path
		fi

		systemctl restart networking			## restart the networking service
		if [[ $? -eq 0 ]] ;then		## validating if the networking service has restarted successfully with exit status, if not fall back to previews configuration
			zenity --info --text "IP configuration completed successfully" --width 250
			menu
		else
			cat $int_path.bck > $int_path
			(
			sleep 1
			systemctl restart network
			) |
			zenity --progress --title "Net Config" --text "Restarting the network service with old config" --pulsate --auto-close --width 250
			if [[ $? -eq 0 ]] ;then
				zenity --error --text "Something went wrong while restarting the \"network\" service, falling back to previews state." --width 250
			else
				zenity --error --text "Something went wrong while restarting the \"network\" service, \
				could not resolve the issue even when falling back to previews state, please check your configuration file at $int_path" --width 250
			fi
		fi
		) |
		zenity --progress --title "Net Config" --text "Re-configuring network services" --pulsate --auto-close --width 250

	else
		printf "Sorry but this script does not support your system\n"
	fi

}


menu () {		## gui menu for selecting which setting to config
	Root_Check		## call the Root_Check function
	Zenity_Check		## call the Zenity_Check function

	## gui menu for the user to select whether he wants to configure static DNS or IP
	Menu_Val=$(zenity --list \
	--text "What would you like to configure?" \
	--title "Network configuration"  \
	--column=Script --column="Description" \
	--width 400 --height 400 "IP" "configure static IP address" "DNS" "Configure static main and scondary DNS servers")

	if [[ $Menu_Val =~ "IP" ]] ;then		## if the user selects IP, call Static_IP function
		Static_IP
	elif [[ $Menu_Val =~ "DNS" ]]; then		## if the user selects DNS call Static_DNS function
		Static_DNS
	else
		exit
	fi
}

menu
