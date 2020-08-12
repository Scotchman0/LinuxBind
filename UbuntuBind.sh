#!/bin/bash

#UBUNTU/DEBIAN BIND stage setup
#created by William Russell,
#Updated 08/12/2020
#now compatible with 16.04/18.04/20.04LTS
#Purpose: to prep Ubuntu machines for use within the active directory environment
#Active Directory bind rules

#This script will require user input to define variables.

# A Short and basic Bind script for Debian/Ubuntu Active Directory Bind to domain calls, with SSSD/krb5 authentication

# This script is designed to aide in the bind and connection to your target AD domain for user workstations.

# In order to launch this script, you need to make the following changes:

#     copy the script to your local directory
#     Define the script as executable with chmod a+x ./UbuntuBind.sh
#     launch the script from within the directory folder that contains the sssd asset file.

# This script will require user input to define some variables.

# Action path:

#     install packages
#     create a temp directory for recovery
#     Prompt for hostname changes
#     Set and map timeserver using ntp
#     Bind to domain via Realmd
#     Set sign-in rules, define home folder settings
#     check for and perform updates
#     Remove unused assets.
#     Inform user that restart will be required, and prompt for restart/delay.

# Invoke shell script with -x to output everything: sh -x dukebind.sh Log to the file you want with: sh -x dukebind.sh >> ~/Desktop/output.log

# Logging and updates to syntax coming in future builds.

#RESOURCES HERE: #https://www.smbadmin.com/2018/06/connecting-ubuntu-server-1804-to-active.html}



##################################################################################
#ENVIRONMENT BLOCK:
    NORMAL=$(printf "\033[m")
    MENU=$(printf "\033[36m")
    NUMBER=$(printf "\033[33m")
    INTRO_TEXT=$(printf "\033[32m")
    END=$(printf "\033[0m")

##################################################################################

LOGFILE=/tmp/UbuntuBind.log


#FUNCTIONS CALL BLOCKS CONTAINED BELOW:

##################################################################################

#Change Hostname of local machine
hostname_Change () {
	#statements
	cat /etc/hostname
	sleep 2
	echo "{$Menu} Would you like to change your hostname? {$END}"
	read -p "Change HOSTNAME (y/n)?" choice
case "$choice" in 
  y|Y ) echo "Please specify a new hostname"
	read newhostname
	echo "updating hostname"
	hostnamectl set-hostname "$newhostname"
	echo "hostname has been updated to:"
	hostname
		#write change to log:
	echo "hostname updated to" >> /tmp/UbuntuBind.log; echo hostname >> /tmp/UbuntuBind.log
	sleep 1
	BelayThat
		;;
  n|N ) echo "You have chosen to leave your hostname as it is"
		echo "hostname not changed" >> /tmp/UbuntuBind.log
		sleep 2
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
	echo "No worries, let's ask again"
	hostname_Change
fi
}
##################################################################################
#ntpdate time map:
Set_Time () {
	echo "{$Menu} Define NTP Server for Synchronization {$END}"
	echo "Example: Time.apple.com, or ntp.domain.org"
	sleep 2
	read NTPNEW
	echo "stopping NTP if running"
	sleep 1
	systemctl stop ntp
	ntpdate "$NTPNEW"
	sleep 2
	systemctl start ntp
	echo "time set to $NTPNEW ntp server"
	echo "time set to $NTPNEW ntp server" >> /tmp/UbuntuBind.log; date >> /tmp/UbuntuBind.log
	sleep 2
}
##################################################################################

#Pause for user to complete steps outside of prompt
Wait_for_it () {
	echo "your hostname is currently:"
	hostname
	sleep 1
	echo "{$INTRO_TEXT} please verify that a matching object exists in an accessible OU in your domain {$END}"
	echo "{$INTRO_TEXT} This script will not CREATE an object, only TIE to a newly created existing object{$END}"
	echo "{INTRO_TEXT} to abort process type exit_script or press return to proceed {$END}"
	read answer1
}
##################################################################################
#Bind to domain functional call:
OneRing () {
	echo "{$MENU} Specify your Domain: AD.Company.org {$END}"
	read Domain_target
	sleep 2
	echo "{$MENU} enter your AD Admin Username:  note - must be AD admin to proceed {$END}"
	read netID
	sleep 2
	echo ""
	sudo realm join --verbose --user="$netID" $Domain_target --install=/
	sleep 2
	echo "The last statement should read: successfully enrolled machine in realm"
	echo "If you got an error, verify you have authority to bind an object to your domain"
	echo "or that the object you are trying to link to in AD exists with the EXACT hostname of this machine"
	sleep 5
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
	print -p "Options: 1. attempt rebind, 1. leave domain, 3. exit script"
	read options

	while [ "$options" != '' ]
    do
    if [ "$options" = "" ]; then
            exit;
    else
        case $option in
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

##################################################################################
adcli_install () {
		apt install -y adcli
		sleep 3
}
##################################################################################
realm-manager () {
	echo "Would you like to define users who can log in to this workstation or allow all domain-users?"
	read -p "allow all domain-users (y/n)?" choice2
case "$choice2" in 
  y|Y ) echo "confirmed - all users in DHE domain will be able to login locally - press return to continue"
	read confirmation
	realm permit --all
	realm list
	sleep 5
	echo "changes can be made later with the command 'realm list' and 'realm permit -u netID'"
	sleep 3
		;;
  n|N ) echo "please enter the netIDs of the users you wish to add in the following format:"
		echo "netID1 netID2 netID3 ...."
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
	realm leave
	echo "removed link to domain... note that object may not be deleted from AD"
	sleep 3
	#### removing sudo access for defined users after this step...
	exit_script
}
##################################################################################
#SSSD_Edit () {

	#This block will be called to edit the the SSSD configuration file and point at the new Domain


#}

##################################################################################


MENU_LAUNCH () {
	clear
	echo "${INTRO_TEXT} 	Ubuntu Active Directory link 				${END}"
	echo "${INTRO_TEXT} 	Written by Scotchman 0,	            			${END}"
	echo "${INTRO_TEXT} 	Please consult the github documentation before starting ${END}"
	echo "${NORMAL}  								${END}"
	echo "${MENU}*${NUMBER} 1)${MENU} Join Domain                   		${END}"
	echo "${MENU}*${NUMBER} 2)${MENU} leave Domain           	    		${END}"
	echo "${MENU}*${NUMBER} 3)${MENU} cancel and exit script        	    ${END}"
	echo "${MENU}*${NUMBER} 4)${MENU} visit github for readme/help          ${END}"
	echo "${NORMAL}  							${END}"

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
       
    4) clear
			echo "please click the link below, press 'enter/return' to return to script menu"
			echo "https://github.com/scotchman0/UbuntuBind/"
			read answer
			MENU_LAUNCH
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
touch /tmp/UbuntuBind.log

MENU_LAUNCH

#error found here V 
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
echo "Installing necessary packages and enabling remote access with SSH"
sleep 3
apt install -y ssh
sleep 2
service ssh start
sudo apt-get install -y realmd
clear
sudo apt-get install -y ntpdate

#install the samba domain defining applets and the kerberos token generator app
echo "${MENU} At next prompt, insert MYDOMAIN.MYCOMPANY.ORG - press return to continue ${END}"
read response4
sudo apt install -y samba-common-bin
sudo apt install -y krb5-user
sudo apt install -y adcli
sleep 2
clear 

#added the below line because SOMETIMES the adcli installation will get borked, this
#just let's things continue smoothly after the fact.
apt --fix-broken install


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
	echo "moving original sssd.conf to /tmp/bind_cache and replacing with clean copy"
	mv /etc/sssd/sssd.conf /tmp/local/bind_cache
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

echo "login credentials settings enabled (removed @domain.company.com appendation from each login)"
sleep 5
clear

systemctl restart sssd.service
#set login window to ask for user logins:

echo "${MENU}At next prompt select create home directory and other options desired{END}"
echo "press return to continue"
read response3

pam-auth-update
sleep 1
clear

echo "Bind complete, updating packages"
apt update
apt upgrade -y

sleep 2
clear

#ask about who should be able to login
realm-manager
sleep 1

#occasionally restarting at this point will jam on virtual machines and require a full shutdown instead
echo "SCRIPT COMPLETED"
sleep 3
echo "Please restart your workstation and login as your active directory user account"
sleep 3
echo "note that after granting any sudo access, you'll need to reboot again."
echo "troubleshooting first login: first time netID login can take awhile, and may dump you back"
echo "at login screen. Simply sign in again to resolve, or drop to shell (ctrl+alt+F4) and login there"
echo "check the github wiki for more troubleshooting steps if needed"
sleep 5
exit 0






