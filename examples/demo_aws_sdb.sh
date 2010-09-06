#!/bin/bash

#******************************************
#
# This script demonstrates usage of reg2rep in combination with 
# Amazon SimpleDB service.
#
# In order to run this script you have to have Amazon AWS
# * access key
# * secret key
#
# (c) 2010 Vanilladesk Ltd.
#
#******************************************

AWS_ACCESS_KEY="$1"
AWS_SECRET_KEY="$2"
AWS_ADDRESS="$3"

DBDOMAIN="sdb_test"

if [ ! "$AWS_ACCESS_KEY" ] || [ ! "$AWS_SECRET_KEY" ]; then
  echo "Error: Parameters missing."
  echo 'Usage: demo_aws_sdb.sh <aws-access-key> <aws-secret-key>'
  exit 1
fi

[ "$AWS_ADDRESS" ] || AWS_ADDRESS="sdb.eu-west-1.amazonaws.com"

if [ ! "`which ruby`" ]; then
  echo "Error: Ruby seems to be unavailable. Please, install ruby first."
  exit 2
fi

# create some items in test domain
echo "-------------------------------"
echo "Adding 4 items to $DBDOMAIN"
ruby ../reg2rep.rb -o ~/reg2rep.log --add $DBDOMAIN item1 "key1:value1;key2:value2;key3:value3" --id $AWS_ACCESS_KEY --secret $AWS_SECRET_KEY --address $AWS_ADDRESS

ruby ../reg2rep.rb -o ~/reg2rep.log --add $DBDOMAIN item2 "key1:value1;key3:value3" --id $AWS_ACCESS_KEY --secret $AWS_SECRET_KEY --address $AWS_ADDRESS

ruby ../reg2rep.rb -o ~/reg2rep.log --add $DBDOMAIN item3 "key1:value1;key2:value2" --id $AWS_ACCESS_KEY --secret $AWS_SECRET_KEY --address $AWS_ADDRESS

ruby ../reg2rep.rb -o ~/reg2rep.log --add $DBDOMAIN item4 "key2:value2;key3:value3" --id $AWS_ACCESS_KEY --secret $AWS_SECRET_KEY --address $AWS_ADDRESS


# list inserted items as table
echo "-------------------------------"
echo "Showing inserted items in table"
ruby ../reg2rep.rb -o ~/reg2rep.log --list $DBDOMAIN table --id $AWS_ACCESS_KEY --secret $AWS_SECRET_KEY --address $AWS_ADDRESS


# modify one item
echo "-------------------------------"
echo "Update 'item2' 'key3' to value 'value1111'"
ruby ../reg2rep.rb -o ~/reg2rep.log --update $DBDOMAIN item2 "key3:value1111" --id $AWS_ACCESS_KEY --secret $AWS_SECRET_KEY --address $AWS_ADDRESS


# show items as hash
echo "-------------------------------"
echo "Showing inserted items as hash"
ruby ../reg2rep.rb -o ~/reg2rep.log --list $DBDOMAIN hash --id $AWS_ACCESS_KEY --secret $AWS_SECRET_KEY --address $AWS_ADDRESS

# show items using custom query
echo "-------------------------------"
echo "Showing subset of inserted items using custom query"
# see http://developer.amazonwebservices.com/connect/entry.jspa?externalID=1231 for more info about SimpleDB queries
ruby ../reg2rep.rb -o ~/reg2rep.log --list $DBDOMAIN hash --query "select key1 from %domain% where key3 = 'value3'" --id $AWS_ACCESS_KEY --secret $AWS_SECRET_KEY --address $AWS_ADDRESS 

exit 0

# delete two items
echo "-------------------------------"
echo "Deleting 'item1' and 'item3'"
ruby ../reg2rep.rb -o ~/reg2rep.log --delete $DBDOMAIN item1 --id $AWS_ACCESS_KEY --secret $AWS_SECRET_KEY --address $AWS_ADDRESS

ruby ../reg2rep.rb -o ~/reg2rep.log --delete $DBDOMAIN item3 --id $AWS_ACCESS_KEY --secret $AWS_SECRET_KEY --address $AWS_ADDRESS


# show only item names
echo "-------------------------------"
echo "Showing only item identifiers"
ruby ../reg2rep.rb -o /root/reg2rep.log --list $DBDOMAIN items --id $AWS_ACCESS_KEY --secret $AWS_SECRET_KEY --address $AWS_ADDRESS



