# Snap Instalation

## Downloading from the snap store

The snap can be installed from a file or directly from the snap store. It is, for the moment, listed in the edge channel.

```
    $ sudo snap install couchdb --edge
```  
## Enable snap permissions

The snap installation uses AppArmor to protect your system. CouchDB requests access to two interfaces: mount-observe, which
is used by the disk compactor to know when to initiate a cleanup; and process-control, which is used by the indexer to set
the priority of couchjs to 'nice'. These two interfaces, while not required, are useful. If they are not enabled, CouchDB will
still run, but you will need to run the compactor manually and couchjs may put a heavy load on the system when indexing. 

To connect the interfaces type:
   ```
   $ sudo snap connect couchdb:mount-observe
   $ sudo snap connect couchdb:process-control
   ```
## Snap configuration

There are two levels of hierarchy within couchdb configuration. 

The default layer is stored in /snap/couchdb/current/rel/couchdb/etc/ the default.ini is
first consulted and then any file default.d directory. In the snap installation 
this is mounted read-only.

The local layer is stored in /var/snap/couchdb/current/etc/ on the writable /var mount. 
Within this second layer, configurations are set with-in local.ini or superseded by any 
file within local.d. Configuration management tools (like puppet, chef, ansible, salt) operate here.

The name of the erlang process and the security cookie used is set within vm.args file.
This can be set suing the snap native configuration. For example, when setting up 
a cluster over several machines the convention is to set the erlang name to couchdb@your.ip.address. 

```
    $ sudo snap set couchdb name=couchdb@216.3.128.12 setcookie=cutter
```

Snap Native Configuration changes only come into effect after a restart

```
    $ sudo snap restart couchdb
```

CouchDB options can be set via configuration over HTTP, as below.

```
    $ curl -X PUT http://localhost:5984/_node/_local/_config/httpd/bind_address -d '"0.0.0.0"'
    $ curl -X PUT http://localhost:5984/_node/_local/_config/couchdb/delayed-commits -d '"true"'
```

Changes here do not require a restart.

For anything else in vm.args or configuration not white listed over http, you can edit 
the /var/snap/couchdb/current/etc files by hand and restart CouchDB. 

## Example Cluster

See the [HOWTO][1] file to see an example of a three node cluster and further notes. 

## Building a Private Snap

If you want to build your own snap file from source see the [BUILD][2] for instructions.

[1]: HOWTO.md
[2]: BUILD.md

