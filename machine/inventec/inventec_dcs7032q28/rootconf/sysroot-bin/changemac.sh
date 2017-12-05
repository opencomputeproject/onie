#!/bin/sh

# Change MAC address from VPD
value=`onie-syseeprom -g 0x24`
error_msg="TLV code not present in EEPROM"
#echo "$value"

case $value in
  *$error_msg*) echo "$error_msg";return 1 ;;
esac
  
OIFS=$IFS
IFS=":"

echo -n "Setting MAC from VPD "
i=0
for str in $value
do
  #echo "Setting offset:0x$i = $str"
  echo -n ":$str"
  cmd="ethtool -E eth0 magic 0x15338086 offset 0x$i value 0x$str"
  eval $cmd
  #echo $cmd
  i=`expr $i + 1`
done

IFS=$OLDIFS
echo " ...Done"
