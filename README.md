## Next workshops:
- PGConf India 2024 February 28 - 14:00 [Distributed SQL on containers: YugabyteDB hands-on lab](https://pgconf.in/conferences/pgconfin2024/program/proposals/685)

---

## Current workshop:

**Slides for the workshop**: [http://hol.pachot.net](http://hol.pachot.net)


**You can run it on Docker Desktop, or a free Gitpod VM (with github account)**:

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/FranckPachot/yb-hol/)

**If you are currently following the workshop, my ports are exposed to:** 
[current-workshop-public-ports.md](current-workshop-public-ports.md)

The commands to run are in the slide and in  [lab-commands.sh](lab-commands.sh)

The Docker images we will use (can be pulled before to avoid Wi-Fi issues)
```
docker pull yugabytedb/yugabyte:latest
docker pull postgres
docker pull prom/prometheus:latest
docker pull grafana/grafana-oss
```

---

# Distributed SQL on containers: YugabyteDB hands-on lab

Join us for a hands-on lab where we'll dive into Distributed SQL databases, focusing on YugabyteDB—an open-source and PostgreSQL-compatible solution. In this workshop, you'll have the opportunity to install YugabyteDB and test its key features, such as elasticity and resilience. We'll simulate scenarios like adding new containers and failures while running the SQL application.

Throughout the session, we'll discuss the reasons behind using Distributed SQL and Cloud Native databases for modern applications. We'll cover important concepts like horizontal scalability, including sharding, replication, and distribution. We might also explore more details on YugabyteDB's architecture, including the Raft algorithm, LSM-Tree, and clock skew.

To participate, you can simply attend and follow along with the demo on-screen. If you want to run the lab on your own, it's recommended to bring a laptop with Docker installed. However, if you're comfortable with alternative installation methods like VMs with Vagrant or Kubernetes, feel free to use them. For connectivity, we'll use any PostgreSQL client, with psql being the easiest option. If you're up for it, you can even try running your PostgreSQL application on YugabyteDB to see how it performs.
