# HOW TO install a cluster using snap

## Create three nodes

In the example below, we are going to set up a three node CouchDB cluster. (Three is the minimum number needed to support clustering features.) We'll also set up a separate, single machine for making backups. In this example we will be using LXD.

We launch a (single) new container, install couchdb via snap from the store and enable interfaces, open up the bind address and set a admin password.
```bash
  1. localhost> lxc launch ubuntu:18.04 couchdb-c1
  1. localhost> lxc exec couchdb-c1 bash
  1. couchdb-c1> apt update
  1. couchdb-c1> snap install couchdb --edge
  1. couchdb-c1> snap connect couchdb:mount-observe
  1. couchdb-c1> snap connect couchdb:process-control
  1. couchdb-c1> curl -X PUT http://localhost:5984/_node/_local/_config/httpd/bind_address -d '"0.0.0.0"'
  1. couchdb-c1> curl -X PUT http://localhost:5984/_node/_local/_config/admins/admin -d '"Be1stDB"'
  1. couchdb-c1> exit
```
Back on localhost, we can then use the LXD copy function to speed up installation:
```bash
  $ lxc copy couchdb-c1 couchdb-c2
  $ lxc copy couchdb-c1 couchdb-c3
  $ lxc copy couchdb-c1 couchdb-bkup
  $ lxc start couchdb-c2
  $ lxc start couchdb-c3
  $ lxc start couchdb-bkup
```

## Configure CouchDB using the snap tool

We are going to need the IP addresses:
```bash
  $ lxc list
```
Now, again from localhost, and using the `lxc exec` commond, we will use the snap configuration tool to set the 
various configuration files.
```bash
  $ lxc exec couchdb-c1 snap set couchdb name=couchdb@10.210.199.73 setcookie=monster
  $ lxc exec couchdb-c2 snap set couchdb name=couchdb@10.210.199.221 setcookie=monster
  $ lxc exec couchdb-c3 snap set couchdb name=couchdb@10.210.199.121 setcookie=monster
```
The backup machine we will configure as a single instance (n=1). 
```bash
  $ lxc exec couchdb-bkup snap set couchdb name=couchdb@127.0.0.1 setcookie=monster
  $ lxc exec couchdb-bkup -- curl -X PUT http://admin:Be1stDB@localhost:5984/_node/_local/_config/cluster/n -d '"1"'
  $ lxc exec couchdb-bkup -- curl -X PUT http://admin:Be1stDB@localhost:5984/_node/_local/_config/cluster/q -d '"1"'

```
Each snap must be restarted for the new configurations to take affect. 
```bash
  $ lxc exec couchdb-c1 snap restart couchdb
  $ lxc exec couchdb-c2 snap restart couchdb
  $ lxc exec couchdb-c3 snap restart couchdb
  $ lxc exec couchdb-bkup snap restart couchdb
```
The configuration files are stored here.
```bash
  $ lxc exec couchdb-bkup cat /var/snap/couchdb/current/etc/vm.args
```
Any changes to couchdb from the http configutation tool are made here
```bash
  $ lxc exec couchdb-bkup cat /var/snap/couchdb/current/etc/local.ini
```

## Configure CouchDB Cluster (using the http interface)

Now we set up the cluster via the http front-end. This only needs to be run once on the first machine. The last command 
syncs with the other nodes and creates the standard databases.
```bash
  $ curl -X POST -H "Content-Type: application/json" http://admin:Be1stDB@10.210.199.73:5984/_cluster_setup -d '{"action": "add_node", "host":"10.210.199.221", "port": "5984", "username": "admin", "password":"Be1stDB"}'
  $ curl -X POST -H "Content-Type: application/json" http://admin:Be1stDB@10.210.199.73:5984/_cluster_setup -d '{"action": "add_node", "host":"10.210.199.121", "port": "5984", "username": "admin", "password":"Be1stDB"}'
  $ curl -X POST -H "Content-Type: application/json" http://admin:Be1stDB@10.210.199.73:5984/_cluster_setup -d '{"action": "finish_cluster"}'
```
Now we have a functioning three node cluster. 

## An Example Database

Let's create an example database ...
```bash
  $ curl -X PUT http://admin:Be1stDB@10.210.199.73:5984/example
  $ curl -X PUT http://admin:Be1stDB@10.210.199.73:5984/example/aaa -d '{"test":1}' -H "Content-Type: application/json"
  $ curl -X PUT http://admin:Be1stDB@10.210.199.73:5984/example/aab -d '{"test":2}' -H "Content-Type: application/json"
  $ curl -X PUT http://admin:Be1stDB@10.210.199.73:5984/example/aac -d '{"test":3}' -H "Content-Type: application/json"
```
... And see that it is created on all three nodes.
```bash
  $ curl -X GET http://admin:Be1stDB@10.210.199.73:5984/example/_all_docs
  $ curl -X GET http://admin:Be1stDB@10.210.199.221:5984/example/_all_docs
  $ curl -X GET http://admin:Be1stDB@10.210.199.121:5984/example/_all_docs
```
## Backing Up CouchDB

Our backup server is on 10.210.199.242. We will manually replicate to this from one (can be any one) of the nodes.
```bash
  $ curl -X POST http://admin:Be1stDB@10.210.199.242:5984/_replicate -d '{"source":"http://10.210.199.73:5984/example", "target":"example", "continuous":false,"create_target":true}' -H "Content-Type: application/json"
  $ curl -X GET http://admin:Be1stDB@10.210.199.242:5984/example/_all_docs
```
Whereas the data store for the clusters nodes is sharded:
```bash
  $ lxc exec couchdb-c1 ls /var/snap/couchdb/common/data/shards/
```
The backup database is a single directory:
```bash
  $ lxc exec couchdb-bkup ls /var/snap/couchdb/common/data/shards/
```

## Monitoring CouchDB 

The logs, by default, are captured by journald. First connect to the node in question:
  `$ lxc exec couchdb-c1 bash`
Then, show logs as usual. couchdb is likely prefixed with 'snap' and suffix may vary depending on the version of snap.
  `$ journalctl -u snap.couchdb* -f`
