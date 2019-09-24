# CouchDB "in a snap"

# Table of Contents
1. [Installation](#installation)
1. [Configuration](#configuration)
1. [Clustering](#clustering)
1. [Building](#building)

-----

# Installation <a name="installation"></a>

## Downloading from the snap store

The snap can be installed from a file or directly from the snap store:

```bash
$ sudo snap install couchdb
```  

## Enable snap permissions

The snap installation uses AppArmor to protect your system. CouchDB requests access to two
interfaces: mount-observe, which is used by the disk compactor to know when to initiate a
cleanup; and process-control, which is used by the indexer to set the priority of couchjs
to 'nice'. These two interfaces are required for CouchDB to run correctly.

To connect the interfaces type:

```bash
$ sudo snap connect couchdb:mount-observe
$ sudo snap connect couchdb:process-control
```

# Configuration <a name="configuration"></a>

Be sure to read the [CouchDB documentation](http://docs.couchdb.org/en/stable/) first.

CouchDB defaults are stored **read-only** in `/snap/couchdb/current/opt/couchdb/etc/`.
This includes `default.ini` and any `default.d/*` files added in the snap build process.
These are all read-only and should never be changed.

User-configurable files are stored in `/var/snap/couchdb/current/etc/` and are writeable.
Changes may be made to `local.ini` or placed in any `local.d/*.ini` file. Configuration
management tools (like puppet, chef, ansible, and salt) can be used to manage these files.

Erlang settings are stored in the `/var/snap/couchdb/current/etc/vm.args` file.  The snap
configuration tool can be used to quickly change the node name and security cookie:

```bash
$ sudo snap set couchdb name=couchdb@1.2.3.4 setcookie=cutter
```

Be sure to read `vm.args` to understand what these settings do before changing them.

*Any configuration file changes require restarting CouchDB before they are effective:*

```bash
$ sudo snap restart couchdb
```

## Monitoring CouchDB 

The logs, by default, are captured by journald. View the logs with either command:

```bash
$ snap logs couchdb -f
$ journalctl -u snap.couchdb* -f
```

## Removing CouchDB

There are several difference between installation via 'apt' and 'snap'. One important 
difference is when removing couchdb. When calling 'apt remove couchdb', the binaries 
are removed but the configuration and the couch database files remain, leaving the 
user to clean up any databases latter. 

Calling 'snap remove couchdb' *will* remove binaries, configurations and the database.

On newer versions of snapd (snapd 2.39+) a snapshot is made of the SNAP_DATA 
and SNAP_COMMON directories and this is stored (subject to disc space) for about 30 days. 
On these newer version a 'snap remove' followed by a 'snap install' may restore the 
database; but you are best to make your own backup before removing couchdb.
If you do not want to keep the configuration or database files you can delete the 
snapshot by calling snap remove with the --purge parameter. 

To remove your installation either:

```bash
$ sudo snap remove couchdb
$ sudo snap remove couchdb --purge
```

-----

# Clustering <a name="clustering"></a>

You can set up a snap-based cluster on your desktop in no time using the couchdb snap.

## Create three nodes

In the example below, we are going to set up a three node CouchDB cluster. (Three is the
minimum number needed to support clustering features.) We'll also set up a separate,
single machine for making backups. In this example we will be using LXD.

We launch a (single) new container, install couchdb via snap from the store and enable
interfaces, open up the bind address and set a admin password.

```bash
localhost> lxc launch ubuntu:18.04 couchdb-c1
localhost> lxc exec couchdb-c1 bash
couchdb-c1> apt update
couchdb-c1> snap install couchdb --edge
couchdb-c1> snap connect couchdb:mount-observe
couchdb-c1> snap connect couchdb:process-control
couchdb-c1> curl -X PUT http://localhost:5984/_node/_local/_config/chttpd/bind_address -d '"0.0.0.0"'
couchdb-c1> curl -X PUT http://localhost:5984/_node/_local/_config/admins/admin -d '"Be1stDB"'
couchdb-c1> exit
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

We are going to need the IP addresses of each container:

```bash
$ lxc list
```

For this example, let's say the IP addresses are `10.210.199.10`, `.11` and `.12`.

Now, again from localhost, and using the `lxc exec` commond, we will use the snap
configuration tool to set the various configuration files.

```bash
$ lxc exec couchdb-c1 snap set couchdb name=couchdb@10.210.199.10 setcookie=monster
$ lxc exec couchdb-c2 snap set couchdb name=couchdb@10.210.199.11 setcookie=monster
$ lxc exec couchdb-c3 snap set couchdb name=couchdb@10.210.199.12 setcookie=monster
```

The backup machine we will configure as a single instance (`n=1, q=1`). 

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

The configuration files are stored here:

```bash
$ lxc exec couchdb-bkup cat /var/snap/couchdb/current/etc/vm.args
```

Any changes to couchdb via curl are stored here:

```bash
$ lxc exec couchdb-bkup cat /var/snap/couchdb/current/etc/local.ini
```

## Configure CouchDB Cluster (using the http interface)

Now we set up the cluster via the http front-end. This only needs to be run once on the
first machine. The last command syncs with the other nodes and creates the standard
databases.

```bash
$ curl -X POST -H "Content-Type: application/json" \
    http://admin:Be1stDB@10.210.199.10:5984/_cluster_setup \
    -d '{"action": "add_node", "host":"10.210.199.11", "port": "5984", "username": "admin", "password":"Be1stDB"}'
$ curl -X POST -H "Content-Type: application/json" \
    http://admin:Be1stDB@10.210.199.10:5984/_cluster_setup \
    -d '{"action": "add_node", "host":"10.210.199.12", "port": "5984", "username": "admin", "password":"Be1stDB"}'
$ curl -X POST -H "Content-Type: application/json" \
    http://admin:Be1stDB@10.210.199.10:5984/_cluster_setup \
    -d '{"action": "finish_cluster"}'
```

Now we have a functioning three node cluster. 

## An Example Database

Let's create an example database ...

```bash
$ curl -X PUT http://admin:Be1stDB@10.210.199.10:5984/example
$ curl -X PUT http://admin:Be1stDB@10.210.199.10:5984/example/aaa -d '{"test":1}' -H "Content-Type: application/json"
$ curl -X PUT http://admin:Be1stDB@10.210.199.10:5984/example/aab -d '{"test":2}' -H "Content-Type: application/json"
$ curl -X PUT http://admin:Be1stDB@10.210.199.10:5984/example/aac -d '{"test":3}' -H "Content-Type: application/json"
```

... and verify that it is created on all three nodes:

```bash
$ curl -X GET http://admin:Be1stDB@10.210.199.10:5984/example/_all_docs
$ curl -X GET http://admin:Be1stDB@10.210.199.11:5984/example/_all_docs
$ curl -X GET http://admin:Be1stDB@10.210.199.12:5984/example/_all_docs
```

## Backing Up CouchDB

Our backup server is on 10.210.199.242. We will manually replicate to this from one (can be any one) of the nodes.

```bash
$ curl -X POST http://admin:Be1stDB@10.210.199.242:5984/_replicate \
    -d '{"source":"http://10.210.199.10:5984/example","target":"example","continuous":false,"create_target":true}' \
    -H "Content-Type: application/json"
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

-----

# Building this snap <a name="building"></a>

This build requires Ubuntu 18.04, the `core18` core, and the `snapcraft` tool.  The
CouchDB team builds this using the
[`yakshaveinc/snapcraft`](https://hub.docker.com/r/yakshaveinc/snapcraft) image, which is
the [official `snapcore/snapcraft` Docker
image](https://snapcraft.io/docs/build-on-docker) patched for Ubuntu 18.04. (When the
upstream image is fully patched for `core18`, we'll move to it instead.)

From an Ubuntu 18.04 machine with Docker installed:

```bash
$ git clone https://github.com/couchdb/couchdb-pkg && cd couchdb-pkg`
$ docker pull yakshaveinc/snapcraft:core18-edge`
$ docker run -it -v "$PWD":/build:Z -w /build yakshaveinc/snapcraft:core18-edge snapcraft
```

The self-built snap will need to be installed using `--dangerous`:

```bash
sudo snap install ./couchdb_2.3.1_amd64.snap --dangerous
```

Clean up with:

```bash
$docker run -it -v "$PWD":/build:Z -w /build yakshaveinc/snapcraft:core18-edge snapcraft clean
```
