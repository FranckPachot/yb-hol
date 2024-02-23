# This image starts YugabyteDB with yugabyted. The initializaion flags are passed as an environment variable ($flags) so that they can be removed when it is a re-start (they are stored to configuration file)
# Example: docker run -e flags='--join yb0.yb --advertise_address=yb1.yb --cloud_location=lab.yb.zoneB --fault_tolerance=zone' yugabyted
#
FROM  yugabytedb/yugabyte:latest
CMD  [ -f /root/var/conf/yugabyted.conf ] && flags="" ; rm -rf /tmp/.yb.* ; yugabyted start $flags --background=false --tserver_flags=yb_enable_read_committed_isolation=true 
