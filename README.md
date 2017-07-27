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

    $ ./make-pacakges http://url/to/apache-couchdb-VERSION.tar.gz

Packages will be placed in the `pkgs/` subdirectory.

# Feedback, Issues, Contributing

General feedback is welcome at our [user][1] or [developer][2] mailing lists.

Apache CouchDB has a [CONTRIBUTING][3] file with details on how to get started
with issue reporting or contributing to the upkeep of this project.

[1]: http://mail-archives.apache.org/mod_mbox/couchdb-user/
[2]: http://mail-archives.apache.org/mod_mbox/couchdb-dev/
[3]: https://github.com/apache/couchdb/blob/master/CONTRIBUTING.md
