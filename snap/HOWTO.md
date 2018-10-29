# HOW TO install a cluster using snap

# Create three machines

In the instruction below, we are going to set up a three -- the miniumn number needed to gain performace improvement -- Couch cluster database. In this potted example we will be using LXD.

We launch a new container and install couchdb on one machine

1. localhost> `lxc launch ubuntu:18.04 couchdb-c1`
1. localhost> `lxc exec couchdb-c1 bash`
1. couchdb-c1> `apt update`
1. couchdb-c1> `snap install couchdb`
1. couchdb-c1> `logout`

Here we use LXD copy function to speed up the test
```
lxc copy couchdb-c1 couchdb-c2
lxc copy couchdb-c1 couchdb-c3
lxc copy couchdb-c1 cdb-backup
lxc start couchdb-c2
lxc start couchdb-c3
lxc start cdb-backup
```

# Configure CouchDB (using the snap tool)

We are going to need the IP addresses. You can find them here.
```
lxc list
```

Now lets use the snap configuration tool to set the configuration files.
```
lxc exec couchdb-c1 snap set couchdb name=couchdb@10.210.199.199 setcookie=monster admin=password bind-address=0.0.0.0
lxc exec couchdb-c2 snap set couchdb name=couchdb@10.210.199.254 setcookie=monster admin=password bind-address=0.0.0.0
lxc exec couchdb-c3 snap set couchdb name=couchdb@10.210.199.24 setcookie=monster admin=password bind-address=0.0.0.0
```
The backup machine we will leave as a single instance and no sharding. 
```
lxc exec cdb-backup snap set couchdb name=couchdb@127.0.0.1 setcookie=monster admin=password bind-address=0.0.0.0 n=1 q=1
```

The snap must be restarted for the new configurations to take affect. 
```
lxc exec couchdb-c1 snap restart couchdb
lxc exec couchdb-c2 snap restart couchdb
lxc exec couchdb-c3 snap restart couchdb
lxc exec cdb-backup snap restart couchdb
```
The configuration files are stored here.
```
lxc exec cdb-backup cat /var/snap/couchdb/current/etc/vm.args
lxc exec cdb-backup cat /var/snap/couchdb/current/etc/local.d/*
```
Any changes to couchdb from the http configutation tool are made here
```
lxc exec cdb-backup cat /var/snap/couchdb/current/etc/local.d/local.ini
```

# Configure CouchDB Cluster (using the http interface)

Now we set up the cluster via the http front-end. This only needs to be run once on the first machine. The last command syncs with the other nodes and creates the standard databases.
```
curl -X POST -H "Content-Type: application/json" http://admin:password@10.210.199.199:5984/_cluster_setup -d '{"action": "add_node", "host":"10.210.199.254", "port": "5984", "username": "admin", "password":"password"}'
curl -X POST -H "Content-Type: application/json" http://admin:password@10.210.199.199:5984/_cluster_setup -d '{"action": "add_node", "host":"10.210.199.24", "port": "5984", "username": "admin", "password":"password"}'
curl -X POST -H "Content-Type: application/json" http://admin:password@10.210.199.199:5984/_cluster_setup -d '{"action": "finish_cluster"}'
```
Now we have a functioning three node cluster. 

# An Example Database

Let's create an example database ...
```
curl -X PUT http://admin:password@10.210.199.199:5984/example
curl -X PUT http://admin:password@10.210.199.199:5984/example/aaa -d '{"test":1}' -H "Content-Type: application/json"
curl -X PUT http://admin:password@10.210.199.199:5984/example/aab -d '{"test":2}' -H "Content-Type: application/json"
curl -X PUT http://admin:password@10.210.199.199:5984/example/aac -d '{"test":3}' -H "Content-Type: application/json"
```
... And see that it is sync'd accross the three nodes.
```
curl -X GET http://admin:password@10.210.199.199:5984/example/_all_docs
curl -X GET http://admin:password@10.210.199.254:5984/example/_all_docs
curl -X GET http://admin:password@10.210.199.24:5984/example/_all_docs
```
# Backing Up CouchDB

Our back up server is on 10.210.199.242. We will manually replicate this from one (anyone) of the nodes.
```
curl -X POST http://admin:password@10.210.199.242:5984/_replicate -d '{"source":"http://10.210.199.199:5984/example", "target":"example", "continuous":false,"create_target":true}' -H "Content-Type: application/json"
curl -X GET http://admin:password@10.210.199.242:5984/example/_all_docs
```
The data store for the clusters nodes are sharded 
```
lxc exec couchdb-c1 ls /var/snap/couchdb/common/2.x/data/shards/
```

The backup database is a single file.
```
lxc exec cdb-backup ls /var/snap/couchdb/common/2.x/data/shards/00000000-ffffffff/
```

# Monitoring CouchDB 

The logs, by default, are captured by journald
```
lxc exec couchdb-c1 bash
journalctl -u snap.couchdb -f
```

