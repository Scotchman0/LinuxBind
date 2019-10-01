# UbuntuBind
A Short and basic Bind script for Debian/Ubuntu Active Directory Bind to domain calls, with SSSD/krb5 authentication


This script is designed to aide in the bind and connection to your target AD domain for user workstations.


In order to launch this script, you need to make the following changes:
1. copy the script to your local directory
2.  Define the script as executable with chmod a+x ./UbuntuBind.sh
3. launch the script from within the directory folder that contains the sssd asset file.

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
sh -x dukebind.sh
Log to the file you want with:
sh -x dukebind.sh >> ~/Desktop/output.log

Logging and updates to syntax coming in future builds.


#RESOURCES HERE: 
#https://www.smbadmin.com/2018/06/connecting-ubuntu-server-1804-to-active.html}
