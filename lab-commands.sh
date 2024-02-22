
# Pull the latest image (preview) if not already done
docker pull yugabytedb/yugabyte:latest
docker pull prom/prometheus:latest
docker pull grafana/grafana-oss

# create a docker network if not already done
docker network create -d bridge yb

mkdir yb-lab && cd yb-lab

cat > Dockerfile <<'DOCKERFILE'
FROM  yugabytedb/yugabyte:latest
CMD  [ -f /root/var/conf/yugabyted.conf ] && flags="" ; rm -rf /tmp/.yb.* ; yugabyted start $flags --background=false --tserver_flags=yb_enable_read_committed_isolation=true 
DOCKERFILE
docker build -t yugabyted .

#############   lab:   ##########
[ ${1:=0} -lt    01    ] && exit
#################################

# Start yb0 (host yb0, zone A, PostgreSQL endpoint 5433)

docker run -d --name yb0 --hostname yb0 --network yb -p5433:5433 -p7000:7000 -p9000:9000 -p15433:15433         -e flags='--advertise_address=yb0.yb --cloud_location=lab.yb.zoneA --fault_tolerance=zone' yugabyted 

until docker exec yb0 postgres/bin/pg_isready -h yb0.yb ; do sleep 1 ; done | uniq

# Start yb1 (host yb1, zone B, PostgreSQL endpoint 5434)

docker run -d --name yb1 --hostname yb1 --network yb -p5434:5433 -p7001:7000 -p9001:9000 -e flags='--join yb0.yb --advertise_address=yb1.yb --cloud_location=lab.yb.zoneB --fault_tolerance=zone' yugabyted 

until docker exec yb0 postgres/bin/pg_isready -h yb1.yb ; do sleep 1 ; done | uniq

# Start yb2 (host yb2, zone C, PostgreSQL endpoint 5435)

docker run -d --name yb2 --hostname yb2 --network yb -p5435:5433 -p7002:7000 -p9002:9000 -e flags='--join yb0.yb --advertise_address=yb2.yb --cloud_location=lab.yb.zoneC --fault_tolerance=zone' yugabyted 

until docker exec yb0 postgres/bin/pg_isready -h yb2.yb ; do sleep 1 ; done | uniq

#############   lab:   ##########
[ ${1:=0} -lt    02    ] && exit
#################################


