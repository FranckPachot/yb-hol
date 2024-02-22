# This adds an entrypoint to the YugabyteDB official image
FROM  yugabytedb/yugabyte:latest
CMD  [ -f /root/var/conf/yugabyted.conf ] && flags="" ; rm -rf /tmp/.yb.* ; yugabyted start $flags --background=false --tserver_flags=yb_enable_read_committed_isolation=true 
