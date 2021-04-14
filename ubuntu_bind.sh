#!/bin/bash

#UBUNTU/DEBIAN BIND stage setup
#latest patch: 04/13/21 - WR
#Purpose: to prep linux machines for use within the active directory environment
#Active Directory bind rules

#This script will require user input to define variables.

#1.  install packages
#2.  Define Domain with samba, sssd, nsswitch files
#3.  Set Hostname
#4.  Set and map timeserver using ntp
#5.  Bind to domain via net ads
#6.  Grant users Sudo (and define access for ACAD Support team with sudo group)
#7.  Set sign-in rules, define window settings
#8.  check for and perform updates
#9.  Remove Assets. 
#10. Inform user that restart will be required, and prompt for restart/delay.

# Invoke shell script with -x to output everything:
# sh -x dukebind.sh
# Log to the file you want with:
# sh -x dukebind.sh >> ~/Desktop


#RESOURCES HERE: 
#https://www.smbadmin.com/2018/06/connecting-ubuntu-server-1804-to-active.html

#https://computingforgeeks.com/join-ubuntu-debian-to-active-directory-ad-domain/



##################################################################################
#ENVIRONMENT BLOCK:
    NORMAL=$(printf "\033[m")
    MENU=$(printf "\033[36m")
    NUMBER=$(printf "\033[33m")
    RED_TEXT=$(printf "\033[31m")
    INTRO_TEXT=$(printf "\033[32m")
    END=$(printf "\033[0m")
##################################################################################

LOGFILE=/tmp/ubuntu_bind.log


#FUNCTIONS CALL BLOCKS CONTAINED BELOW:

##################################################################################

#Change Hostname of local machine
hostname_Change () {
	#statements
	cat /etc/hostname
	sleep 2
	echo "Would you like to change your hostname?"
	read -p "modify hostname (y/n)?" choice
case "$choice" in 
  y|Y ) echo "Please specify a new hostname"
	read newhostname
	echo "updating hostname"
	hostnamectl set-hostname "$newhostname"
	echo "hostname has been updated to:"
	hostname
	#write change to log:
	echo "hostname updated to" >> /tmp/ubuntu_bind.log; echo hostname >> /tmp/ubuntu_bind.log
	sleep 1
	BelayThat
		;;
  n|N ) echo "You have chosen to leave your hostname as it is"
		echo "hostname not changed" >> /tmp/ubuntu_bind.log
		sleep 2
		BelayThat
		;;
esac

}
##################################################################################
#Are you sure check? 
#can we move this into the set hostname step?
BelayThat () {
read -p "Are you sure? y/n " -n 1 -r
echo  ""
if [[ $REPLY =~ ^[Yy]$ ]]
then
	echo "confirmed..."
	sleep 2
else
	echo "No worries, let's ask again"
	hostname_Change
fi
}
##################################################################################
#ntpdate time map:
Set_Time () {
	echo "Please specify an internal timeserver and press return to continue:"
	sleep 2
	read time_server
	echo "stopping NTP if running"
	systemctl stop ntp
	ntpdate "$time_server"
	sleep 2
	systemctl start ntp
	echo "time set to DHE ntp server"
	echo "time set to DHE ntp server" >> /tmp/ubuntu_bind.log; date >> /tmp/ubuntu_bind.log
	sleep 2
}
##################################################################################
#Bind to domain functional call:
OneRing () {
	echo "Now binding to domain:"
	sleep 2
	echo "Please insert the domain address in all caps and press return to continue:"
	sleep 1
	read domain_name
	echo "Now enter your pre-authorized Username/Service Account"
	read username
	sleep 1
	echo "attempting to bind with supplied credentials..."
	sleep 1
	realm join --verbose --user="$netID" "$domain_name" --install=/
	sleep 3
	clear
}
##################################################################################
#Verify bind status - if checks true, continue, if fails, re-run OneRing function
BindStatus () {
	echo "checking connection to active directory..."
	sleep 1
	if realm list | grep "configured: kerberos-member"
	then 
		echo "Join verified successfully... moving to next step..."
		sleep 2
		echo "adding realm permit for domain users"
		clear
	else
	echo "Join failed... trying again, please verify credentials"
	sleep 3
	clear
	OneRing
fi
}
##################################################################################
#Cancel script - Unit already bound 
#TEST THIS BLOCK

Event0 () {
	echo "Event Triggered: Machine Already Bound to domain..."
	sleep 3
	print -p "Options: 1. attempt rebind, 1. leave domain, 3. exit script"
	read options

	while [ "$options" != '' ]
    do
    if [ "$options" = "" ]; then
            exit;
    else
        case $options in
    1) clear
          	break 
          	#Require a break here to bounce out of the while loop specified above and continue the task
          	#because the UBUNTU installer is a default part of the path progression, instead of a function.
            ;;

	2) clear
	    echo "Copying files to log location and unlinking services"
	    leave_domain
             ;;

    3) clear
		echo "done"
		exit_script
	esac
fi
done

}

###############################
adcli_install () {
if lsb_release -d | grep 18
	then
		echo "Ubuntu 18.x detected, adcli from apt" >> /tmp/dukebind.log
		apt install -y adcli
		sleep 3
elif lsb_release -d | grep 20
	then
		echo "Ubuntu 20.x detected, installing adcli from dpkg (UPDATED)" >> /tmp/dukebind.log
		apt install adcli*.deb
		sleep 3
fi
sleep 2
echo "installed updated adcli platform"

sleep 2
clear 
}
##################################################################################
realm-manager () {
	echo "Would you like to define users who can log in to this workstation or allow all domain-users?"
	read -p "allow all domain-users (y/n)?" choice2
case "$choice2" in 
  y|Y ) echo "confirmed - all users in domain will be able to login locally - press return to continue"
	read confirmation
	realm permit --all
	realm list
	sleep 5
	echo "changes can be made later with the command 'realm list' and 'realm permit -u <username>'"
	sleep 3
		;;
  n|N ) echo "please enter the usernames of the users you wish to add in the following format:"
		echo "<username1> <username2> <username3> ...."
		read access-users
		realm permit $access-users
		realm list
		echo "confirm users listed above - modifications can be made later with 'realm permit --revoke netID' or 'realm permit -U netID' "
		sleep 2
		;;
esac

}
##################################################################################

#Event "none" --> Relating to the "Are you sure" options check --> exit path
none () {
	sleep 2
}
##################################################################################
#Event "Exit_Script"
exit_script () {
	echo "aborting processes and abandoning threads. Cleanup may be required"
	sleep 2
	exit 0
}
##################################################################################
#event: "Leave Domain" --> remove domain settings and revert to pre-stage setting
leave_domain () {
	echo "reverting to pre-bind state..."
	echo "moving files/logs to /tmp/local/bind_data"
	sleep 3
	mkdir /tmp/local
	sleep 1
	mkdir /tmp/local/bind_data
	sleep 1
	mv /etc/samba/smb.conf /tmp/local/bind_data
	mv /etc/samba/smb_original.conf /etc/samba/smb.conf
	echo "samba reverted..."
	sleep 2
	mv /etc/krb5.conf /tmp/local/bind_data
	echo "kerberos conf removed..."
	sleep 2
	realm leave
	echo "removed link to domain... note that object may not be deleted from AD"
	sleep 3
	#### removing sudo access for defined users after this step...
	exit_script
}
##################################################################################


MENU_LAUNCH () {
	clear
	echo "${INTRO_TEXT} 	Duke Active Directory link 						${END}"
	echo "${NORMAL}  														${END}"
	echo "${MENU}*${NUMBER} 1)${MENU} Join Domain     		${END}"
	echo "${MENU}*${NUMBER} 2)${MENU} leave Domain   	    		${END}"
	echo "${MENU}*${NUMBER} 3)${MENU} cancel and exit script   	    ${END}"
	echo 
	echo "${NORMAL}  														${END}"

	read -r option

	while [ "$option" != '' ]
    do
    if [ "$option" = "" ]; then
            exit;
    else
        case $option in
    1) clear
            echo "Installing packages and beginning AD bind process"
            sleep 2
          	break 

          	#Require a break here to bounce out of the while loop specified above and continue the task
          	#because the UBUNTU installer is a default part of the path progression, instead of a function.
            ;;

	2) clear
	    echo "Copying files to log location and unlinking services"
	    leave_domain
             ;;
    3) clear
			echo "OK Bye Bye"
 			sleep 1
 			exit_script
			;;
        x)exit
        ;;
       '\n')exit
        ;;

	*) clear
        echo "Please select an option from the menu"
        sleep 1
        MENU_LAUNCH
        ;;

    esac
fi
done


}

##################################################################################
#End function blocks, begin pathing blocks:
##################################################################################


#~#~#~#~#~#~#~#~#~#~#~#~#~#~+++++++++++++++++++++#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
							#SCRIPT PATHING START#
								#UBUNTU/DEBIAN#
#~#~#~#~#~#~#~#~#~#~#~#~#~#~+++++++++++++++++++++#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#
touch /tmp/ubuntu_bind.log

MENU_LAUNCH

if realm list | grep "configured: kerberos-member"
	then
		echo "Machine already enrolled in domain, please re-run script with option 2 selected then try again"
		sleep 3 
		Event0
	else
		echo "Disregard error with missing variable - checks if you're already bound to domain"
		echo "preflight cleared - beginning configuration"
		sleep 3

fi

#Stage 1: Packages and file placement
#create a folder to catch logs/output/original copies of files for replacement during undo request
mkdir /tmp/bind_cache
echo "folder /tmp/bind_cache created - holding temp data, will be cleared after install"
sleep 3
clear

# Pre-installation of packages needed for later
echo "Installing necessary packages and enabling remote support"
apt install -y ssh
sleep 2
service ssh start
apt-get install -y realmd
clear
apt-get install -y ntpdate

#install the samba domain defining applets and the kerberos token generator app
echo "${MENU}At next prompt, insert (All CAPS) <YOUR.DOMAIN.ORG> - press return to continue${END}"
read response4
apt install -y samba-common-bin
apt install -y krb5-user

#call function above
adcli_install

#installs SSS utilities for kerberos authentication/management of domain logins
apt --fix-broken install
#added because apparently sssd doesn't want to install properly without it??

apt install -y libpam-sss libnss-sss sssd sssd-tools
sleep 2
clear

###################################################
#Call function for mapping to time server
echo "beginning time synch and bind process..."
Set_Time
sleep 1
clear

#Change target hostname, then give chance to undo changes or continue
hostname_Change
sleep 2
clear


#Call the bind rule based on steps so far:
OneRing
sleep 3
clear
BindStatus
clear

echo "admin dialogue: finished bind arguments - beginning permissions staging." 
sleep 2
clear

############################################################################
#Permissions staging and settings configuration block:
############################################################################

#move the edited sssd.conf file into place for next step:
if find /etc/sssd/sssd.conf
then
	echo "moving original sssd.conf to /tmp/dukebind_cache and replacing with clean copy"
	mv /etc/sssd/sssd.conf /tmp/local/bind_data
	sleep 1
	cp sssd.conf /etc/sssd/
	sleep 1
else
	echo "moving new sssd.conf into place"
	cp sssd.conf /etc/sssd/
	sleep 1
fi

#take ownership of the sssd protected files moved:
chown root:root /etc/sssd/sssd.conf
chmod 600 /etc/sssd/sssd.conf

echo "login credentials settings enabled (removed @dhe.duke.edu appendation to each login requirement)"
sleep 2
clear

#Starts the sssd service for netID access/management
systemctl restart sssd.service
#set login window to ask for user logins:

echo "${MENU}At next prompt select create home directory if you'd like net logins to have a local account.{END}"
echo "press return to continue"
read response3

#Triggers options selection for home directory creation
pam-auth-update
sleep 1
clear

#Check for and perform updates to ensure all packages running on latest builds after new dependencies
echo "Bind complete, updating packages"
apt update
apt upgrade -y

sleep 2
clear

#Ask about realm access - realmD configuration steps (who can login and what the sudoers group is)
realm-manager
sleep 1
sudoers
sleep 1

#inform user of status and request restart for updated login access.
echo "SCRIPT COMPLETED"
sleep 3
echo "Please restart your workstation and login as your netID user account"
sleep 3
echo "if AD logins fail, login as local user and define access using 'realm permit <username> instead"
sleep 5
exit 0






