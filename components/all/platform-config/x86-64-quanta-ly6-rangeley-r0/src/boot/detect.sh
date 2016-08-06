############################################################
# <bsn.cl fy=2013 v=none>
#
#        Copyright 2013, 2014 BigSwitch Networks, Inc.
#        Copyright 2015 Quanta Computer Inc.
#
#
#
# </bsn.cl>
############################################################
# Default platform detection.

buf="`dmidecode 2>&1 || :`"
case "$buf" in
  *"Product Name: Quanta LY6"*)
    echo "x86-64-quanta-ly6-rangeley-r0" >/etc/onl_platform
    exit 0
  ;;
esac

exit 1
