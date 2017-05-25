SAVEDFILE=/var/lib/urandom/random-seed

[ -c /dev/urandom ] || exit 0

PATH=/sbin:/bin
if ! POOLBYTES=$((
  ($(cat /proc/sys/kernel/random/poolsize 2>/dev/null) + 7) / 8
)) ; then
  POOLBYTES=512
fi
. /lib/init/vars.sh

. /lib/lsb/init-functions

do_status () {
	if [ -f $SAVEDFILE ] ; then
		return 0
	else
		return 4
	fi
}

case "$1" in
  start|"")
	[ "$VERBOSE" = no ] || log_action_begin_msg "Initializing random number generator"
	# Seed the RNG with date and time.
	# This is helpful in the less-than-ideal case where $SAVEDFILE
	# is read-only.
	# The value of this is greatly reduced if $SAVEDFILE is missing,
	# or its contents are shared machine-to-machine or known to
	# attackers (since they might well know at what time this
	# machine booted up).
	(
	  date +%s.%N

	  # Load and then save $POOLBYTES bytes,
	  # which is the size of the entropy pool
	  if [ -f "$SAVEDFILE" ]
	  then
		  cat "$SAVEDFILE"
	  fi
	# Redirect output of subshell (not individual commands)
	# to cope with a misfeature in the FreeBSD (not Linux)
	# /dev/random, where every superuser write/close causes
	# an explicit reseed of the yarrow.
	) >/dev/urandom

	# Write a new seed into $SAVEDFILE because re-using a seed
	# compromises security.  Each time we re-seed, we want the
	# seed to be as different as possible.
	# Write it now, in case the machine crashes without doing
	# an orderly shutdown.
	# The write will fail if $SAVEDFILE is read-only, but it
	# doesn't hurt to try.
	umask 077
	dd if=/dev/urandom of=$SAVEDFILE bs=$POOLBYTES count=1 >/dev/null 2>&1
	ES=$?
	umask 022
	[ "$VERBOSE" = no ] || log_action_end_msg $ES
	;;
  stop)
	# Carry a random seed from shut-down to start-up;
	# Write it on shutdown, in case the one written at startup
	# has been lost, snooped, or otherwise compromised.
	# see documentation in linux/drivers/char/random.c
	[ "$VERBOSE" = no ] || log_action_begin_msg "Saving random seed"
	umask 077
	dd if=/dev/urandom of=$SAVEDFILE bs=$POOLBYTES count=1 >/dev/null 2>&1
	ES=$?
	[ "$VERBOSE" = no ] || log_action_end_msg $ES
	;;
  status)
	do_status
	exit $?
	;;
  restart|reload|force-reload)
	echo "Error: argument '$1' not supported" >&2
	exit 3
	;;
  *)
	echo "Usage: urandom start|stop" >&2
	exit 3
	;;
esac
