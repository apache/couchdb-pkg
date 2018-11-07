# Snap Instalation

## Downloading from the snap store

The snap can be installed from a file or directly from the snap store. It is, for the moment, listed in the edge channel.

    ```$ sudo snap install couchdb --edge```
    
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

The default layer is stored in /snap/couchdb/current/rel/couchdb/etc/ and the default.ini is
referred to before the default.d directory. In the snap installation this is mounted read-only.

The local layer is stored in /var/snap/couchdb/current/etc/ on the writable /var mount. 
Within this second layer, configurations are set local.ini (single file co-mingled sections) or 
the local.d directory (one file per section). Configuration management tools (like puppet, chef, 
ansible, salt) often use the former (local.ini).  The "snap set" command works within the 
latter (local.d). Entries in local.d supersede those in the local.ini directory. 

Changes made via the http configuration will write into local.d/90-override.ini.

The name of the erlang process and the security cookie used is set in vm.args file.
This should be set through the snap native configuration. For example, when setting up 
a cluster over several machines the convention is to set the erlang 
name to couchdb@your.ip.address. 

Both erlang and couchdb configuration changes can be made at the same time.

    ```$ sudo snap set couchdb name=couchdb@216.3.128.12 setcookie=cutter admin=Be1stDB bind-address=0.0.0.0```

Snap set variable can not contain underscore character, but any dashes are converted to underscore when
writing to file. Wrap double quotes around any brackets or spaces. 

   ```$ sudo snap set couchdb erlang="{couch_native_process,start_link,[]}"```

Snap Native Configuration changes only come into effect after a restart
    
    ```$ sudo snap restart couchdb```

Snap Native Configuration has only been enabled for a few options essential to inital installation or items 
that are not white-listed for configuration over HTTP.  Other options that can be set via snap are: CHTTPD's "port";
Cluster options: "n", "q"; the log options "writer","file","level". And the Native Query Servers 
Options "query" and "erlang". 

Other options can be set via configuration over HTTP, as below.

    ```$ curl -X PUT http://admin:Be1stDB@216.3.128.12:5984/_node/_local/_config/couchdb/delayed-commits -d '"true"'```
    
Which has the advantage of not requiring restarting the application. 

For anything not covered by snap set or the configuration over http, you can edit 
the /var/snap/couchdb/current/etc files by hand. 


## Example Cluster

See the [HOWTO][1] file to see an example of a three node cluster and further notes. 

## Building a Private Snap

If you want to build your own snap file from source see the [BUILD][2] for instructions.

[1]: HOWTO.md
[2]: BUILD.md

