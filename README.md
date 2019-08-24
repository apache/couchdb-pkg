# CouchDB Packaging support repo

The main purpose of this repository is to provide packaging support files for Apache CouchDB and its SpiderMoneky 1.8.5 dependency, for a number of well-known and used packaging formats, namely:

* `.deb` files, as used by Debian, Ubuntu, and derivatives
* `.rpm` files, as used by CentOS, RedHat, and derivatives
* `snapcraft` files, as used by the Ubuntu Snappy package manager

# Usage

## On a system with all necessary build-time dependencies:

### SpiderMonkey 1.8.5

#### rpms

```shell
make couch-js-rpms
```

#### debs

```shell
make couch-js-debs PLATFORM=$(lsb_release -cs)
```

### CouchDB

#### rpms or debs from `master` branch:

```shell
cd .. && git clone https://github.com/apache/couchdb
cd couchdb-pkg && make build-couch $(lsb_release -cs) PLATFORM=$(lsb_release -cs)
```

#### rpms or debs from a release tarball:

```shell
make copy-couch $(lsb_release -cs) COUCHTARBALL=path/to/couchdb-#.#.#.tar.gz PLATFORM=$(lsb_release -cs)
```

-----

## Building inside the `couchdbdev` docker containers

You must first pull down the image or images you need from Docker Hub, or build the images
using the [apache/couchdb-ci](https://github.com/apache/couchdb-ci) repository. A full
list of supported environments is at https://hub.docker.com/u/couchdbdev/ .

### SpiderMonkey 1.8.5

```shell
docker pull couchdbdev/<os>-<codename>-base
./build.sh js <os>-<codename>    # for example, debian-stretch, ubuntu-bionic or centos-7.
```

### CouchDB

From a downloaded CouchDB tarball:

```shell
docker pull couchdbdev/<osname>-<codename>-erlang-<erlang-version>
ERLANGVERSION=<erlang-version> ./build.sh couch <os>-<codename> path/to/couchdb-#.#.#.tar.gz
```

Directly from the Apache source CDN:

```shell
docker pull couchdbdev/<osname>-<codename>-erlang-<erlang-version>
./build.sh couch <os>-<codename> https://dist.apache.org/repos/dist/release/couchdb/source/#.#.#/apache-couchdb-#.#.#.tar.gz
```

-----

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

    $ ./build.sh couch-all path/to/apache-couchdb-VERSION.tar.gz

or

    $ ./build.sh couch-all http://url/to/apache-couchdb-VERSION.tar.gz

Packages will be placed in the `pkgs/couch` subdirectory.

A similar `js-all` target exists, should the SpiderMonkey packages need to be regenerated.

## Uploading the packages

If you have Apache Bintray credentials (set your `BINTRAY_USER` and `BINTRAY_API_KEY` environment variables appropriately), after building all CouchDB packages above, simply run:

    ./build.sh couch-upload-all

Or, for the SpiderMonkey packages:

    ./build.sh js-upload-all

-----

# Snap packages

See [README-SNAP.md](README-SNAP.md).

-----

# Feedback, Issues, Contributing

General feedback is welcome at our [user][1] or [developer][2] mailing lists.

Apache CouchDB has a [CONTRIBUTING][3] file with details on how to get started
with issue reporting or contributing to the upkeep of this project.

[1]: http://mail-archives.apache.org/mod_mbox/couchdb-user/
[2]: http://mail-archives.apache.org/mod_mbox/couchdb-dev/
[3]: https://github.com/apache/couchdb/blob/master/CONTRIBUTING.md

