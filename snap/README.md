# Building snaps

## Prerequisites

CouchDB requires Ubuntu 16.04. If building on 18.04, then LXD might be useful. 

1. `lxc launch ubuntu:16.04 couchdb-pkg`
1. `lxc exec couchdb-pkg bash`
1. `sudo apt update`
1. `sudo apt install snapd snapcraft`

1. `git clone https://github.com/couchdb/couchdb-pkg.git`
1. `cd couchdb-pkg`

## How to do it

1. Edit `snap/snapcraft.yaml` to point to the correct tag (e.g. `2.2.0`)
1. `snapcraft`

# Installing snaps

YOu may need to pull the LXD file to the host system.

    $ lxc file pull couchdb-pkg/root/couchdb-pkg/couchdb_2.2.0_amd64.snap /tmp/couchdb_2.2.0_amd64.snap

The self crafted snap will need to be installed in devmode

    $ sudo snap install /tmp/couchdb_2.2.0_amd64.snap --devmode 

The name of the erlang process and the security cookie used can be set through 
the snap configuration. For example, when setting up a cluster over several 
machines the convention is to set the erlang name to couchdb@your.ip.address.

Snap set variable can not contain underscore character, but any dashes are converted on writing to file.

    $ sudo snap set couchdb name=couchdb@216.3.128.12 setcookie=cutter admin=Be1stDB bind-address=0.0.0.0
    $ sudo snap restart couchdb


