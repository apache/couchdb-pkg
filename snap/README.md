# Snap Instalation

## Downloading from the snap store

The snap can be installed from a file or directly from the snap store. It is, for the moment, list in the edge channel.

    $ sudo snap install couchdb --edge
    
## Enable snap permissions

The snap installation uses AppArmor to protect security. CouchDB request access to two interfaces: mount-observe, which
is used by the disk compactor to know when to initiate a cleanup; and, process-control, is used by the indexer to set
the priority of couchjs to 'nice'. These two interfaces are not required, but if they are not enabled, you will need to run the compactor manually and the couchjs can weigh a heavy load on the system. 

To connect the interfaces type:

    $ sudo snap connect couchdb:mount-observe
    $ sudo snap connect couchdb:process-control

## Snap configuration

There are two levels of hierarchy within couchdb configuration. 

The default layer is stored in /snap/couchdb/current/rel/couchdb/etc/ with in the 
directory default.d or the file default.ini and is read only. 

The local override layer is stored in /var/snap/couchdb/current/etc/ and is writable. 
Within this second layer, configurations are set local.ini (single file co-mingled sections) or 
the local.d directory (one file per section). The "snap set" command works with the 
latter (local.d) and couchdb http configuration overwrites the former (local.ini). 
Entries in local.d supersede those in the local.ini directory.

The name of the erlang process and the security cookie used is set in vm.args file.
This should be set through the snap native configuration. For example, when setting up 
a cluster over several machines the convention is to set the erlang 
name to couchdb@your.ip.address. 

Both erlang and couchdb configuration changes can be made at the same time.

    $ sudo snap set couchdb name=couchdb@216.3.128.12 setcookie=cutter admin=Be1stDB bind-address=0.0.0.0

Snap set variable can not contain underscore character, but any dashes are converted to underscore when
writing to file. Wrap double quotes around any brackets or spaces. 

    $ sudo snap set couchdb delayed-commits=true erlang="{couch_native_process,start_link,[]}"

Snap Native Configuration changes only come into effect after a restart
    
    $ sudo snap restart couchdb

Snap Native Configuration have only been enable for a select few variables. Generally those essential to inital 
installation or items that are not white-listed for configuration over HTTP. An example of configuration over HTTP is below.

    `$ curl -X PUT http://admin:Be1stDB@216.3.128.12:5984/_node/_local/_config/ssl/port -d '"6984"'`
    
This has the advantage of not requiring restarting the application. You can aslo edit the /var/couchdb/current/etc files 
by hand. Or using a configuration management tool (puppet, chef, ansible, salt) is also common.

## Example Cluster

See the [HOWTO][1] file to see an example of a three node cluster and further notes. 

## Building a Private Snap

If you want to build your own snap file from source see the [BUILD][2] for instructions.

[1]: HOWTO.md
[2]: BUILD.md

