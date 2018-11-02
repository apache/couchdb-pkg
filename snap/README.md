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

# Snap Instalation

You may need to pull the LXD file to the host system.

    $ lxc file pull couchdb-pkg/root/couchdb-pkg/couchdb_2.2.0_amd64.snap /tmp/couchdb_2.2.0_amd64.snap

The self crafted snap will need to be installed in devmode

    $ sudo snap install /tmp/couchdb_2.2.0_amd64.snap --devmode 

# Snap Configuration

There are two levels of erlang and couchdb configuration hierarchy. 

The default layer is stored in /snap/couchdb/current/rel/couchdb/etc/ and is read only. 
The user override layer, is stored in /var/snap/couchdb/current/etc/ and is writable. 
Within this second layer, configurations are set with the local.d directory (one file 
per section) or the local.ini (co-mingled). The "snap set" command works with the 
former (local.d) and couchdb http configuration overwrites the latter (local.ini). 
Entries in local.ini supersede those in the local.d directory.

The name of the erlang process and the security cookie used is set in vm.args file.
This can be set through the snap native configuration. For example, when setting up 
a cluster over several machines the convention is to set the erlang 
name to couchdb@your.ip.address. Both erlang and couchdb configuration changes can be 
made at the same time.

    $ sudo snap set couchdb name=couchdb@216.3.128.12 setcookie=cutter admin=Be1stDB bind-address=0.0.0.0

Snap set variable can not contain underscore character, but any dashes are converted to underscore when
writing to file. Wrap double quotes around any bracets and avoid spaces.

    $ sudo snap set couchdb delayed-commits=true erlang="{couch_native_process,start_link,[]}"

Snap Native Configuration changes only come into effect after a restart
    
    $ sudo snap restart couchdb

# Example Cluster

See the HOWTO.md file to see an example of a three node cluster.

