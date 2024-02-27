
# Pull the latest image (preview) if not already done
docker pull yugabytedb/yugabyte:latest
docker pull prom/prometheus:latest
docker pull grafana/grafana-oss

# create a docker network if not already done
docker network create -d bridge yb

cat > Dockerfile <<'DOCKERFILE'
FROM  yugabytedb/yugabyte:latest
CMD  [ -f /root/var/conf/yugabyted.conf ] && flags="" ; rm -rf /tmp/.yb.* ; yugabyted start $flags --background=false --tserver_flags=yb_enable_read_committed_isolation=true 
DOCKERFILE
docker build -t yugabyted .

###########################################   lab:   ##########
sh .ports.sh  ; step="$1" ; [ ${step:=0} -lt    01    ] && exit
###############################################################

# Start yb0 (host yb0, zone A, PostgreSQL endpoint 5433)

docker run -d --name yb0 --hostname yb0 --network yb -p5433:5433 -p7000:7000 -p9000:9000 -p15433:15433         -e flags='--advertise_address=yb0.yb --cloud_location=lab.yb.zoneA --fault_tolerance=zone' yugabyted 

until docker exec yb0 postgres/bin/pg_isready -h yb0.yb ; do sleep 1 ; done | uniq

# Start yb1 (host yb1, zone B, PostgreSQL endpoint 5434)

docker run -d --name yb1 --hostname yb1 --network yb -p5434:5433 -p7001:7000 -p9001:9000 -e flags='--join yb0.yb --advertise_address=yb1.yb --cloud_location=lab.yb.zoneB --fault_tolerance=zone' yugabyted 

until docker exec yb0 postgres/bin/pg_isready -h yb1.yb ; do sleep 1 ; done | uniq

# Start yb2 (host yb2, zone C, PostgreSQL endpoint 5435)

docker run -d --name yb2 --hostname yb2 --network yb -p5435:5433 -p7002:7000 -p9002:9000 -e flags='--join yb0.yb --advertise_address=yb2.yb --cloud_location=lab.yb.zoneC --fault_tolerance=zone' yugabyted 

until docker exec yb0 postgres/bin/pg_isready -h yb2.yb ; do sleep 1 ; done | uniq

###########################################   lab:   ##########
sh .ports.sh  ; step="$1" ; [ ${step:=0} -lt    02    ] && exit
###############################################################

cat <<'TTY'

docker exec -it yb0 ysqlsh -h yb0  
docker exec -it yb0 ysqlsh -h yb1  
docker exec -it yb0 ysqlsh -h yb2  

# enter the PostgreSQL command line to connect to yb0
docker exec -it yb0 ysqlsh -h yb0 
-- in the PostgreSQL command line ( prompt: yugabyte=# )
-- show its IP address 
 show listen_addresses;
-- Show all servers: 
 select host,port,node_type,zone from yb_servers();
 -- Connect to other nodes (yb1 and yb2) and do the same 
 \connect yugabyte yugabyte yb1
 show listen_addresses;

TTY

docker exec -it yb0 ysqlsh -h yb0   <<'SQL'

-- in the PostgreSQL command line ( prompt: yugabyte=# )
-- load the extension that helps to generate UUIDs 
 create extension pgcrypto;
-- create a table: 
 create table demo (
  id uuid default gen_random_uuid() , message text )
  split into 12 tablets;

-- in the PostgreSQL command line ( prompt: yugabyte=# )
-- connect to a node
 \connect yugabyte yugabyte yb0
-- insert a message
 insert into demo(message) values (
'hello, connected from '||current_setting('listen_addresses')
 ) returning *;
-- do the same on all nodes
 \connect yugabyte yugabyte yb1
...
select * from demo;

-- in the PostgreSQL command line ( prompt: yugabyte=# )
-- run the inserts in a loop
 insert into demo(message) values ('hello from ' 
  || current_setting('listen_addresses'))
 returning id, (select count(*) as "total count" from demo)
\watch 0.1

SQL

###########################################   lab:   ##########
sh .ports.sh  ; step="$1" ; [ ${step:=0} -lt    03    ] && exit
###############################################################

# Start yb3 yb4 yb5 in zoneA zoneB zone c

docker run -d --name yb3 --hostname yb3 --network yb -e flags='--join yb0.yb --advertise_address=yb3.yb --cloud_location=lab.yb.zoneA --fault_tolerance=zone' yugabyted 

docker run -d --name yb4 --hostname yb4 --network yb -e flags='--join yb0.yb --advertise_address=yb4.yb --cloud_location=lab.yb.zoneB --fault_tolerance=zone' yugabyted 

docker run -d --name yb5 --hostname yb5 --network yb -e flags='--join yb0.yb --advertise_address=yb5.yb --cloud_location=lab.yb.zoneC --fault_tolerance=zone' yugabyted 

###########################################   lab:   ##########
sh .ports.sh  ; step="$1" ; [ ${step:=0} -lt    04    ] && exit
###############################################################

# pause one container
 
docker pause yb2 

# or docker stop yb2, or docker network yb disconnect yb yb2

sleep 3

# restart the container
 
docker restart yb2 

###########################################   lab:   ##########
sh .ports.sh  ; step="$1" ; [ ${step:=0} -lt    05    ] && exit
###############################################################

# blacklist nodes to remove
docker exec yb0 yb-admin --master_addresses yb0:7100 change_blacklist ADD yb3.yb:9100
docker exec yb0 yb-admin --master_addresses yb0:7100 change_blacklist ADD yb4.yb:9100
docker exec yb0 yb-admin --master_addresses yb0:7100 change_blacklist ADD yb5.yb:9100

# wait for rebalance completion
docker exec yb0 yb-admin --master_addresses yb0:7100 get_load_move_completion

until docker exec yb0 yb-admin --master_addresses yb0:7100 get_load_move_completion |
 grep "Percent complete = 100 :" ; do sleep 10 ; done

 docker exec yb0 yb-admin --master_addresses yb0:7100 get_load_move_completion


# remove when balanced
docker rm -f yb3 yb4 yb5

# remove all nodes from blacklisted
for i in {0..5}
do
 docker exec yb0 yb-admin --master_addresses yb0:7100 \
 change_blacklist REMOVE yb$i.yb:9100
done

###########################################   lab:   ##########
sh .ports.sh  ; step="$1" ; [ ${step:=0} -lt    06    ] && exit
###############################################################

# from a PostgreSQL image
docker run -it --network yb postgres bash <<'SH'

# set connection parameters
export PGHOST=yb0.yb,yb1.yb,yb2.yb,yb3.yb,yb4.yb,yb5.yb 
export PGUSER=yugabyte  PGDATABASE=yugabyte PGPORT=5433
export PGLOADBALANCEHOSTS=random

# test connection (multiple times)
psql -c "
select yb_server_zone(),current_setting('listen_addresses')
"

# initialization
pgbench -i --scale=10 --init-steps=dtpGf --no-vacuum

# run <builtin: simple update>
while true
do
pgbench --client=10 -P5 -T 60 --max-tries=10 --no-vacuum
done &

SH

###########################################   lab:   ##########
sh .ports.sh  ; step="$1" ; [ ${step:=0} -lt    07    ] && exit
###############################################################

cat > prometheus.yml <<'YML'

global:
  scrape_interval: 5s
scrape_configs:
  - job_name: 'yugabytedb'
    metrics_path: /prometheus-metrics
    static_configs:
      - targets: [ 'yb0.yb:7000', 'yb0.yb:9000', 'yb1.yb:7000', 'yb1.yb:9000', 'yb2.yb:7000', 'yb2.yb:9000', 'yb3.yb:9000', 'yb4.yb:9000', 'yb5.yb:9000' ]

YML

# start prometheus
docker run -d --name pr --network yb -p 9090:9090 prom/prometheus

# change config and restart
docker cp prometheus.yml pr:/etc/prometheus/prometheus.yml
docker restart pr

# start grafana
docker run -d --name gr --network yb -p 3000:3000 grafana/grafana-oss

###########################################   lab:   ##########
sh .ports.sh  ; step="$1" ; [ ${step:=0} -lt    08    ] && exit
###############################################################

###########################################   lab:   ##########
sh .ports.sh  ; step="$1" ; [ ${step:=0} -lt    09    ] && exit
###############################################################


