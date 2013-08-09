#!/bin/bash
#
# earlynetfs         Mount network filesystems.
#
# Authors:  Bill Nottingham <notting@redhat.com>
#   AJ Lewis <alewis@redhat.com>
#     Miquel van Smoorenburg, <miquels@drinkel.nl.mugnet.org>
#
# chkconfig: 345 25 06
# description: Mounts and unmounts all Network File System (NFS), \
#        SMB/CIFS (Lan Manager/Windows), and NCP (NetWare) mount points.
### BEGIN INIT INFO
# Provides: $local_fs $remote_fs
### END INIT INFO

[ -f /etc/sysconfig/network ] || exit 0
. /etc/init.d/functions
. /etc/sysconfig/network

# Check that networking is up.
[ "${NETWORKING}" = "no" ] && exit 0

NFSFSTAB=`LC_ALL=C awk '!/^#/ && $3 ~ /^nfs/ && $3 != "nfsd" && $4 !~ /noauto/ { print $2 }' /etc/fstab`

NFSMTAB=`LC_ALL=C awk '$3 ~ /^nfs/ && $3 != "nfsd" && $2 != "/" { print $2 }' /proc/mounts`


# See how we were called.
case "$1" in
  start)
  # Let udev handle any backlog before trying to mount file systems

  touch /var/lock/subsys/earlynetfs
  # The 'no' applies to all listed filesystem types. See mount(8).
  action $"EarlyNetFS doing nothing on start(thats good): "
  ;;
  stop)
        # Unmount loopback stuff first
  __umount_loopback_loop
  __umount_blktap_loop
    if [ -n "$NFSMTAB" ]; then
    __umount_loop '$3 ~ /^nfs/ && $3 != "nfsd" && $2 != "/" {print $2}' \
      /proc/mounts \
      $"Unmounting NFS(early) filesystems: " \
      $"Unmounting NFS(early) filesystems (retry): " \
      "-f -l"
  fi

  rm -f /var/lock/subsys/earlynetfs
  ;;
  status)
  if [ -f /proc/mounts ] ; then
        [ -n "$NFSFSTAB" ] && {
         echo $"Configured NFS mountpoints: "
         for fs in $NFSFSTAB; do echo $fs ; done
    }
    [ -n "$NFSMTAB" ] && {
                      echo $"Active NFS mountpoints: "
          for fs in $NFSMTAB; do echo $fs ; done
    }
  else
    echo $"/proc filesystem unavailable"
  fi
  [ -r /var/lock/subsys/earlynetfs ] || exit 2
  ;;
  restart)
  $0 stop
  $0 start
  ;;
  reload)
        $0 start
  ;;
  *)
  echo $"Usage: $0 {start|stop|restart|reload|status}"
  exit 1
esac

exit 0
