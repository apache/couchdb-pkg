# CouchDB Packaging support files

Quickstart:

```shell
$ cd .. && git clone https://github.com/apache/couchdb
$ cd couchdb-pkg && make build-couch $(lsb_release -cs) PLATFORM=$(lsb_release -cs)
```

# Building packages for a release

## Prerequisites

1. Linux running Docker
1. The current user must be capable of running `docker run`.
1. Enough free disk space to download all of the Docker images + build
   CouchDB.

## Running the package build

You can either build packages from a local CouchDB dist tarball (the output
of `make dist`), or from a URL of a published CouchDB dist tarball (such
as the ones on https://couchdb.apache.org/). The package's version number
will be derived from the filename of the CouchDB dist tarball.

Run:

    $ ./make-packages path/to/apache-couchdb-VERSION.tar.gz

or

    $ ./make-packages http://url/to/apache-couchdb-VERSION.tar.gz

Packages will be placed in the `pkgs/` subdirectory.

# Building snaps

## Prerequisites

1. Ubuntu 16.04
1. `sudo apt install snapd snapcraft`

## How to do it

1. Edit `snap/snapcraft.yaml` to point to the correct tag (e.g. `2.1.0`)
1. `snapcraft`

# Installing snaps

The self crafted snap will need to be installed in devmode

    $ sudo snap install /somepath/couchdb_x.x.x_amd64.snap --devmode 

The name of the erlang process and the security cookie used can be set through 
the snap configuration. For example, when setting up a cluster over several 
machines the convention is to set the erlang name to couchdb@your_ip_address.

    $ sudo snap set couchdb name=couchdb@216.3.128.12 setcookie=cutter

# Feedback, Issues, Contributing

General feedback is welcome at our [user][1] or [developer][2] mailing lists.

Apache CouchDB has a [CONTRIBUTING][3] file with details on how to get started
with issue reporting or contributing to the upkeep of this project.

[1]: http://mail-archives.apache.org/mod_mbox/couchdb-user/
[2]: http://mail-archives.apache.org/mod_mbox/couchdb-dev/
[3]: https://github.com/apache/couchdb/blob/master/CONTRIBUTING.md
