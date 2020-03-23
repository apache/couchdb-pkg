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

If this is your first time installing couchdb then you will need to set an admin password
and manually start CouchDB.

```bash
$ sudo snap set couchdb admin=[your-password-goes-here]
$ sudo snap start couchdb 
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
single machine for making backups. In this example we will be using parallel instance of 
snaps that is availble from version 2.36.

First we need to enable parallel instances of snap.
```bash
$ snap set system experimental.parallel-instances=true
```
We install couchdb via snap from the store and enable interfaces, open up the bind address
and set a admin password.
```bash
$> snap install couchdb_1
$> snap connect couchdb_1:mount-observe
$> snap connect couchdb_1:process-control
$> snap set couchdb_1 name=couchdb1@127.0.0.1 setcookie=cutter port=5981 admin=Be1stDB
```
You will need to edit the local configuration file to manually set the data directories. 
You can find the file here (/var/snap/couchdb_1/current/etc/local.ini) ensure
that the couchdb stanza should look like this
```
[couchdb]
;max_document_size = 4294967296 ; bytes
;os_process_timeout = 5000
database_dir = /var/snap/couchdb_1/common/data
view_index_dir = /var/snap/couchdb_1/common/data
```
Start your engine and confirm couchdb is running.

$> snap start couchdb_1

$> curl -X GET http://localhost:5981

Then repeat for couchdb_1, couchdb_2 and couchdb_bkup

## Enable CouchDB Cluster (using the http interface)

Have the first node generate two uuids 

$> curl http://localhost:5981/_uuids?count=2

The each instances within a cluster needs to share the same uuid ... 

```bash
curl -X PUT http://admin:Be1stDB@127.0.0.1:5981/_node/_local/_config/couchdb/uuid -d '"f6f22e2c664b49ba2c6dc88379002548"'
curl -X PUT http://admin:Be1stDB@127.0.0.1:5982/_node/_local/_config/couchdb/uuid -d '"f6f22e2c664b49ba2c6dc88379002548"'
curl -X PUT http://admin:Be1stDB@127.0.0.1:5983/_node/_local/_config/couchdb/uuid -d '"f6f22e2c664b49ba2c6dc88379002548"'
```
... and common secret ...

```bash
curl -X PUT http://admin:Be1stDB@127.0.0.1:5981/_node/_local/_config/couch_httpd_auth/secret -d '"f6f22e2c664b49ba2c6dc88379002a80"'
curl -X PUT http://admin:Be1stDB@127.0.0.1:5982/_node/_local/_config/couch_httpd_auth/secret -d '"f6f22e2c664b49ba2c6dc88379002a80"'
curl -X PUT http://admin:Be1stDB@127.0.0.1:5983/_node/_local/_config/couch_httpd_auth/secret -d '"f6f22e2c664b49ba2c6dc88379002a80"'
```
... before they can be enabled for clustering
```bash
curl -X POST -H "Content-Type: application/json" http://admin:Be1stDB@127.0.0.1:5981/_cluster_setup -d '{"action": "enable_cluster", "bind_address":"0.0.0.0", "username": "admin", "password":"Be1stDB", "node_count":"3"}'
curl -X POST -H "Content-Type: application/json" http://admin:Be1stDB@127.0.0.1:5982/_cluster_setup -d '{"action": "enable_cluster", "bind_address":"0.0.0.0", "username": "admin", "password":"Be1stDB", "node_count":"3"}'
curl -X POST -H "Content-Type: application/json" http://admin:Be1stDB@127.0.0.1:5983/_cluster_setup -d '{"action": "enable_cluster", "bind_address":"0.0.0.0", "username": "admin", "password":"Be1stDB", "node_count":"3"}'
```
You can check the status here.
```bash
curl http://admin:Be1stDB@127.0.0.1:5981/_cluster_setup
curl http://admin:Be1stDB@127.0.0.1:5982/_cluster_setup
curl http://admin:Be1stDB@127.0.0.1:5983/_cluster_setup
```

## Configure CouchDB Cluster (using the http interface)
Next we want to join the three nodes together. We do this through requests to the first node.
```bash
curl -X PUT "http://admin:Be1stDB@127.0.0.1:5981/_node/_local/_nodes/couchdb2@127.0.0.1" -d '{"port":5982}'
curl -X PUT "http://admin:Be1stDB@127.0.0.1:5981/_node/_local/_nodes/couchdb3@127.0.0.1" -d '{"port":5983}'

curl -X POST -H "Content-Type: application/json" http://admin:Be1stDB@127.0.0.1:5981/_cluster_setup -d '{"action": "finish_cluster"}'

curl http://admin:Be1stDB@127.0.0.1:5981/_cluster_setup

```
If everthing as been successful, then the three notes can be seen here.
```bash
$> curl -X GET "http://admin:Be1stDB@127.0.0.1:5981/_membership"
```
Now we have a functioning three node cluster. 

## An Example Database
Let's create an example database ...
```bash
$ curl -X PUT http://admin:Be1stDB@localhost:5981/example
$ curl -X PUT http://admin:Be1stDB@localhost:5981/example/aaa -d '{"test":1}' -H "Content-Type: application/json"
$ curl -X PUT http://admin:Be1stDB@localhost:5981/example/aab -d '{"test":2}' -H "Content-Type: application/json"
$ curl -X PUT http://admin:Be1stDB@localhost:5981/example/aac -d '{"test":3}' -H "Content-Type: application/json"
```
... and verify that it is created on all three nodes ...
```bash
$ curl -X GET http://localhost:5981/example/_all_docs
$ curl -X GET http://localhost:5982/example/_all_docs
$ curl -X GET http://localhost:5983/example/_all_docs
```
... and is separated into shards on the disk.
```bash
  $ ls /var/snap/couchdb_?/common/data/shards/
```

## Backing Up CouchDB
The backup machine we will configure as a single instance (`n=1, q=1`). 
```bash
$> snap install couchdb_bkup
$> snap set couchdb_bkup name=couchdb0@localhost setcookie=cutter port=5980 admin=Be1stDB
$> curl -X PUT http://admin:Be1stDB@localhost:5980/_node/_local/_config/cluster/n -d '"1"'
$> curl -X PUT http://admin:Be1stDB@localhost:5980/_node/_local/_config/cluster/q -d '"1"'
```
We will manually replicate to this from one (can be any one) of the nodes.
```bash
$ curl -X POST http://admin:Be1stDB@localhost:5980/_replicate \
    -d '{"source":"http://localhost:5981/example","target":"example","continuous":false,"create_target":true}' \
    -H "Content-Type: application/json"
$ curl -X GET http://admin:Be1stDB@localhost:5980/example/_all_docs
```
The backup database has a single shard and single directory:
```bash
  $ ls /var/snap/couchdb_bkup/common/data/shards/
```

-----

# Remote Shell into CouchDB

In the very rare case you need to connect to the couchdb server, a remsh script is
provided. You need to specify both the name of the server and the cookie, even if
you are using the default. 

/snap/bin/couchdb.remsh -n couchdb@localhost -c monster

# Building this snap <a name="building"></a>

This build requires Ubuntu 18.04, the `core18` core, and the `snapcraft` tool.  The
CouchDB team builds this using the
[`yakshaveinc/snapcraft`](https://hub.docker.com/r/yakshaveinc/snapcraft) image, which is
the [official `snapcore/snapcraft` Docker
image](https://snapcraft.io/docs/build-on-docker) patched for Ubuntu 18.04. (When the
upstream image is fully patched for `core18`, we'll move to it instead.)

From an Ubuntu 18.04 machine with Docker installed:

```bash
$ git clone https://github.com/couchdb/couchdb-pkg && cd couchdb-pkg
$ docker pull yakshaveinc/snapcraft:core18
$ docker run -it -v "$PWD":/build:Z -w /build yakshaveinc/snapcraft:core18 snapcraft
```

The self-built snap will need to be installed using `--dangerous`:

```bash
sudo snap install ./couchdb_3.0.0_amd64.snap --dangerous
```

Clean up with:

```bash
$docker run -it -v "$PWD":/build:Z -w /build yakshaveinc/snapcraft:core18-edge snapcraft clean
```
