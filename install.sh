#!/bin/bash
#############################################
#
# Installation script Reg2Rep.
#
# Script will install reg2rep to defined folder and create additional
# configuration folders.
#
# Copyright (c) 2010 Vanilladesk Ltd., jozef.sovcik@vanilladesk.com
#
#############################################

##### CONFIGURATION - TO BE MODIFIED IF NECESSARY
# installation folder
inst_folder=/usr/local/lib/reg2rep

#--------------------------------------------
# this script should be run under ROOT account
if [ "$UID" -ne "0" ]; then
  echo "Error: Script should be run under root user privileges."
  exit 1
fi 

if [ ! `which sed` ]; then
  echo "Error: Application 'sed' is necessary to run this script."
  exit 1
fi

# "install" reg2rep by copying all files to specified folder
[ ! -d $inst_folder ] || mkdir -p $inst_folder
cp * $inst_folder

# and remove installation script :-)
rm $inst_folder/install.sh

#---------------------------------------------
# configure helper script
sed -i -e "/^r2r_install_path=/cr2r_install_path=$inst_folder" $inst_folder/reg2rep.sh

# create symlink in /usr/local/bin so reg2rep can be executed directly
cp -s $inst_folder/reg2rep.sh /usr/local/bin/reg2rep

#---------------------------------------------
[ ! -d /etc/reg2rep ] || mkdir /etc/reg2rep
cp $inst_folder/example.conf /etc/reg2rep/example.conf

echo "----------------------------------------"
echo "Reg2Rep successfully installed."
echo "----------------------------------------"
