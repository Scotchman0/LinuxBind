#!/bin/bash

#UBUNTU/DEBIAN BIND stage setup
#created by William Russell, DHTS-Academic Support at Duke University Heath System
#6/14/19
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


##################################################################################
#ENVIRONMENT BLOCK:
    NORMAL=$(printf "\033[m")
    MENU=$(printf "\033[36m")
    NUMBER=$(printf "\033[33m")
    RED_TEXT=$(printf "\033[31m")
    INTRO_TEXT=$(printf "\033[32m")
    END=$(printf "\033[0m")
    BESCLIENTCHECK="$(service --status-all | grep besclient)"
	FSENSORCHECK="$(service --status-all | grep falcon-sensor)"
	BNDAEMONCHECK="$(service --status-all | grep bndaemon)"

##################################################################################

LOGFILE=dukebind.sh.log


#FUNCTIONS CALL BLOCKS CONTAINED BELOW:

##################################################################################

#Change Hostname of local machine
hostname_Change () {
	#statements
	cat /etc/hostname
	sleep 2
	echo "Would you like to change your hostname?"
	read -p "Continue (y/n)?" choice
case "$choice" in 
  y|Y ) echo "Please specify a new hostname"
	read newhostname
	echo "updating hostname"
	hostnamectl set-hostname "$newhostname"
	echo "hostname has been updated to:"
	hostname
	sleep 1
	BelayThat
		;;
  n|N ) echo "You have chosen to leave your hostname as it is"
		sleep 2
		BelayThat
		;;
  * ) echo "invalid Reply, you'll be prompted again. (Y) at next choice to make no changes" #any other input provided
		BelayThat
		;;
esac

}
##################################################################################
#Are you sure check?
BelayThat () {
read -p "Are you sure? y/n " -n 1 -r
echo  ""
if [[ $REPLY =~ ^[Yy]$ ]]
then
	echo "confirmed..."
	sleep 2
else
	echo "which step do you need to repeat - type EXACT SELECTION SHOWN:"
	echo "hostname_Change | Set_Time | none"
	read choices
	$choices
fi
}
##################################################################################
#ntpdate time map:
Set_Time () {
	echo "setting internal clock to domain controller..."
	sleep 2
	service ntp stop
	ntpdate ntp.dhe.duke.edu
	sleep 2
	service ntp start
	echo "time set to DHE ntp server"
	sleep 2
}
##################################################################################

#Pause for user to complete steps outside of prompt
Wait_for_it () {
	echo "your hostname is currently:"
	hostname
	sleep 1
	echo "please verify that a matching object exists in the LZ OU"
	echo "to abort process type exit_script or press return to proceed"
	read answer1
}
##################################################################################
#Bind to domain functional call:
OneRing () {
	echo "enter your netID:  note - must be AD admin, object in LZ to proceed"
	read netID
	sleep 1
	echo "attempting to bind with supplied credentials..."
	sudo realm join --verbose --user="$netID" DHE.DUKE.EDU --install=/
	sleep 2
	echo "The last statement should read: successfully enrolled machine in realm"
	sleep 2
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
		sleep 5
		clear
	else
	echo "Join failed... trying again, please verify credentials"
	sleep 3
	clear
	OneRing
fi
}
##################################################################################
#Cancel script - Unit already bound event
Event0 () {
	echo "Event Triggered: Machine Already Bound to domain..."
	sleep 3
	print -p "Options: rebind, leave_domain, exit_script"
	read Options
	$Options
}
##################################################################################
#Event "none" --> Relating to the "Are you sure" options check --> exit path
none () {
	sleep 2
}
##################################################################################
#Event "Exit_Script"
exit_script () {
	echo "aborting processes and abandoning threads. Cleanup required"
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
	sudo realm leave
	echo "removed link to domain... note that object may not be deleted from AD"
	sleep 3
	#### removing sudo access for defined users after this step...
	exit_script
}
##################################################################################
#Flight Check block - ensures bigFix/Fortinac/CrowdStrike are present:
flight_check () {
	if service --status-all | grep besclient
		then
		echo "MDM passing..."
else 
	echo "failed precheck. Please re-run prestage.sh : bigFix not found"
	exit_script
fi

	if service --status-all | grep falcon-sensor
	then
	echo "Antivirus passing..."
else 
	echo "Failed precheck. Please re-run prestage.sh : falcon sensor not found"
	exit_script
fi

	if service --status-all | grep bndaemon
		then
		echo "NetAgent passing..."
else 
	echo "Failed precheck. Please re-run prestage.sh : fortinac not found"
	exit_script
fi

sleep 3
echo "Preflight check passed."
sleep 2
echo "Press return to continue, or type exit_script to abort"
read response2
$response2
}
##################################################################################


MENU_LAUNCH () {
	clear
	echo "${INTRO_TEXT} 	Duke Active Directory link 						${END}"
	echo "${INTRO_TEXT} 	Written by William Russell, DHTS-Academic 		${END}"
	echo "${INTRO_TEXT} 	Please consult the wiki before starting 		${END}"
	echo "${NORMAL}  														${END}"
	echo "${MENU}*${NUMBER} 1)${MENU} Join DHE.DUKE.EDU (Ubuntu)     		${END}"
	echo "${MENU}*${NUMBER} 2)${MENU} leave Domain (Ubuntu)  	    		${END}"
	echo "${MENU}*${NUMBER} 3)${MENU} cancel and exit script (Ubuntu)  	    ${END}"
	echo "${MENU}*${NUMBER} 4)${MENU} visit Wiki (Ubuntu)                   ${END}"
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
            sleep 1
            clear
            echo "starting in 3"
            sleep 1
            clear
            echo "starting in 2"
            sleep 1
            clear
            echo "starting in 1"
            sleep 1
            clear
            echo "GO!"
            sleep 1
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
        *)clear
        echo "Pick an option from the menu"
        sleep 1
        MENU_LAUNCH
        ;;
     4) clear
			echo "Launching new window with wiki page"

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
MENU_LAUNCH

#Flightcheck (see if prestage has been run, fail if not.)
flight_check

#error found here V 
if realm list | grep "configured: kerberos-member"
	then 
		Event0
	else
		echo "preflight cleared - beginning configuration"
		sleep 2

fi

#Stage 1: Packages and file placement
#create a folder to catch logs/output/original copies of files for replacement during undo request
mkdir /tmp/dukebind_cache
echo "folder /tmp/dukebind_cache created - holding backups and logs"
sleep 3
clear

# Pre-installation of packages needed for later
echo "Installing necessary packages and enabling remote support"
apt install -y ssh
sleep 2
service ssh start
sudo apt-get install -y realmd
clear
sudo apt-get install -y ntpdate

#install the samba domain defining applets and the kerberos token generator app
echo "${MENU}At next prompt, insert (All CAPS) DHE.DUKE.EDU - press return to continue${END}"
read response4
sudo apt install -y samba-common-bin
sudo apt install -y krb5-user
sudo apt install -y adcli
sleep 2
clear 

sudo apt-get install -y cockpit
sudo apt install -y libpam-sss libnss-sss sssd sssd-tools
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

#Check if object exists in the LZ (User prompt)
Wait_for_it
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
	sudo mv /etc/sssd/sssd.conf /tmp/local/bind_data
	sleep 1
	sudo cp sssd.conf /etc/sssd/
	sleep 1
else
	echo "moving new sssd.conf into place"
	sudo cp sssd.conf /etc/sssd/
	sleep 1
fi

#take ownership of the sssd protected files moved:
sudo chown root:root /etc/sssd/sssd.conf
sudo chmod 600 /etc/sssd/sssd.conf

echo "login credentials settings enabled (removed @dhe.duke.edu appendation to each login requirement)"
sleep 2
clear

sudo systemctl restart sssd.service
#set login window to ask for user logins:

echo "${MENU}At next prompt select create home directory{END}"
echo "press return to continue"
read response3

sudo pam-auth-update
sleep 1
clear

echo "Bind complete, updating packages"
apt update
apt upgrade -y

sleep 2
clear

#occasionally restarting at this point will jam on virtual machines and require a full shutdown instead
echo "SCRIPT COMPLETED"
sleep 3
echo "Please restart your workstation and login as your netID user account"
sleep 3
echo "note that after granting user sudo access on next restart, you'll need to reboot again."
sleep 5
exit 0






