# LinuxBind
A Short and basic Bind script for Linux (ubuntu and rhel based distros) Active Directory Bind to domain calls, with SSSD/krb5 authentication


This script is designed to aide in the bind and connection to your target AD domain for user workstations.





In order to launch this script, you need to make the following changes:
(before you start, update your OS with *sudo apt update && upgrade -y*
or sudo yum update -y)

1. Clone this directory with:
> git clone https://github.com/Scotchman0/LinuxBind.git

2.  Define the relevant script to your system as executable with chmod a+x ./rhel_bind.sh 
(or ./ubuntu_bind.sh)

3. EDIT the SSSD.conf file to reflect your LOCAL DOMAIN *** this file MUST be edited to reflect the domain name you're specifying during the bind arguments while the script runs. It will be placed automatically in /etc/sssd/ and will be used to launch logins next boot. Without updating to your domain, you will not be able to log in with net credentials. If you've forgotten to do it before the script runs, you may log in with local creds, edit this file and restart again - should resolve. 

4. launch the script from within the directory folder that contains the sssd asset file.
> sudo ./rhel_bind.sh


This script will require user input to define some variables.

Action path:
1.  install packages
2.  create a temp directory for recovery
3.  Prompt for hostname changes
4.  Set and map timeserver using ntp
5.  Bind to domain via Realmd
7.  Set sign-in rules, define home folder settings
8.  check for and perform updates
9.  Remove unused assets.
10. Inform user that restart will be required, and prompt for restart/delay.

Invoke shell script with -x to output everything:
sh -x ubuntu_bind.sh
Log to the file you want with:
sh -x rhel_bind.sh >> ~/Desktop/output.log

Logging and updates to syntax coming in future builds.


#RESOURCES HERE: 
#https://www.smbadmin.com/2018/06/connecting-ubuntu-server-1804-to-active.html}


#PREPARATION AND RUNNING THE SCRIPT:
1. copy the master directory or clone this repository to your target machine
2. enter the new UbuntuBind folder and make the UbuntuBind.sh executable with sudo a+x UbuntuBind.sh
3. Make adjustments to the sssd.conf file: Nano or vim the sssd.conf file and change any mention of "AD.COMPANY.COM" to your active directory domain target address. Capitalize the full caps instance of the term.
4. save changes and execute the script from the directory, and follow the prompts. There are at least 4 places where you will need to acknowledge or interact with the script, and there are portions where it will wait for you to confirm that you have made changes to your domain structure. 
5. Verify that there is an Object in the domain matching the hostname of the target computer (Don't worry, it will ask you whether this has been completed). This script does not attempt to create an object to avoid undue permissions errors for certain circumstances or particular OU's that are enabled for object creation and binding specifically, and to simplify the process for the user.

#Troubleshooting:
After bind, you can't login with your AD account username:
Go back in with your local account and run: 'sudo realm permit <username>'
Then log out and try to log in again with that credential (occasionally the realm permit --all action fails, and defining the users list will let them in directly instead of having the login table just be open to all users) this is a bug, and I don't know why it impacts maybe 1/10 machines. Looking into it.

Is the time server updating correctly, and is it accurate against your internal domain clock? (sometimes there's an intentional clock skew). Try mapping your NTP against the domain address itself.

Is there an object in the domain that you are authorized to bind with the same hostnamename as the device you're attempting to bind? If you're RE-Running the bind script, delete the original object, and create a new one for a fresh bind link.

Are you authorized to bind to your domain? Check your permissions and see if your systems administrator will allow you to interact with your domain in this way.

does the SSSD.conf file have the accurate target information re: your domain address when it comes to LDAP targeting and AD authentications?

Can your Machine speak to the domain? Try and ping against your host domain address and see if there's a networking path issue. If you can't ping your domain, you can't bind to it. 

Is your machine using the correct DNS entries to be able to do dynamic hostname resolution in your network? verify the internal DNS servers are linked to your device correctly, and that you are able to ping against other internal hostnames (not just IP addresses). 

Beyond that, the script really should run itself once launched. I'll be continuing to update and patch this build moving forward. Always clone the latest version, and ensure that your system is up to date with sudo apt update && apt upgrade -y before you begin. 
