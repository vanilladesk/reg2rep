#!/bin/bash
#############################################
#
# Uninstallation script for Reg2Rep.
#
# Script will remove reg2rep and restore previous state.
# Any existing configuration files will be kept.
#
# Copyright (c) 2010 Vanilladesk Ltd., http://www.vanilladesk.com
#
#############################################

##### CONFIGURATION - TO BE MODIFIED IF NECESSARY
# version
version="1.0"

# installation folder
inst_folder="/usr/local/lib/reg2rep$version"

# bin folder to store symlinks
bin_folder="/usr/local/bin"

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

cecho "Restoring symlinks..." $C_GREEN
# remove current symlink
[ -e $bin_folder/reg2rep ] || [ -h $bin_folder/reg2rep ] && sudo rm $bin_folder/reg2rep

# restore previous symmlink, if any to bin folder
[ -e $inst_folder/.uninstall/reg2rep ] || [ -h $inst_folder/.uninstall/reg2rep ] && sudo mv $inst_folder/.uninstall/reg2rep $bin_folder/reg2rep

# remove installation folder
cecho "Removing installation folder $inst_folder..." $C_GREEN
[ -d $inst_folder ] && sudo rm -R $inst_folder

echo "----------------------------------------"
echo "Reg2Rep $version successfully un-installed."
echo "----------------------------------------"
