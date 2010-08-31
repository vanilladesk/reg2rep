#!/bin/bash
# Simple helper script to start reg2rep.rb
if [ ! `which ruby` ]; then
  echo "Error: Ruby not installed or accessible in PATH."
  exit 1
fi

r2r_install_path=/usr/local/lib/reg2rep

ruby $r2r_install_path/reg2rep.rb $@