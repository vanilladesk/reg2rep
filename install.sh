#!/bin/bash
#############################################
#
# Installation script Reg2Rep.
#
# Script will install reg2rep to defined folder and create additional
# configuration folders.
#
# Copyright (c) 2010 Vanilladesk Ltd., http://www.vanilladesk.com
#
#############################################

##### CONFIGURATION - TO BE MODIFIED IF NECESSARY
# installation folder
inst_folder=/usr/local/lib/reg2rep

#--------------------------------------------
# color codes

C_BLACK='\033[0;30m'
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[1;34m'
C_MAGENTA='\033[1;35m'
C_CYAN='\033[1;36m'
C_WHITE='\033[1;37m'
C_GRAY='\033[;37m'
C_DEFAULT='\E[0m'

#-------------------------------------------

function cecho ()  {
  # Description
  #   Colorized echo
  #
  # Parameters:
  #   $1 = message
  #   $2 = color
  
  message=${1:-""}   # Defaults to default message.
  color=${2:-$C_BLACK}           # Defaults to black, if not specified.
  
  echo -e "$color$message$C_DEFAULT"  
  
  return
} 

#-------------------------------------------

if [ ! `which sed` ]; then
  cecho "Error: Application 'sed' is necessary to run this script." $C_RED
  exit 1
fi

if [ ! `which sudo` ]; then
  cecho "Error: Application 'sudo' is necessary to run this script." $C_RED
  exit 1
fi

# "install" reg2rep by copying all files to specified folder
cecho "Creating install folder $inst_folder" $C_GREEN
[ -d $inst_folder ] || sudo mkdir -p $inst_folder
if [ $? -ne 0 ]; then
  cecho "Error: It is not possible to create install folder." $C_RED
  exit 1
fi

cecho "Copying all files to $inst_folder" $C_GREEN
sudo cp * $inst_folder

# and remove installation script :-)
sudo rm $inst_folder/install.sh

#---------------------------------------------
# configure helper script
sudo sed -i -e "/^r2r_install_path=/cr2r_install_path=$inst_folder" $inst_folder/reg2rep.sh

# create symlink in /usr/local/bin so reg2rep can be executed directly
sudo cp -s $inst_folder/reg2rep.sh /usr/local/bin/reg2rep

#---------------------------------------------
cecho "Copying all files to $inst_folder" $C_GREEN
[ ! -d /etc/reg2rep ] || mkdir /etc/reg2rep
sudo cp $inst_folder/example.conf /etc/reg2rep/example.conf

echo "----------------------------------------"
echo "Reg2Rep successfully installed."
echo "----------------------------------------"
