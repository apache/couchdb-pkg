## CouchDB Packaging support repo

The main purpose of this repository is to provide packaging support files for Apache CouchDB and its SpiderMonkey 1.8.5 dependency, for a number of well-known and used packaging formats, namely:

* `.deb` files, as used by Debian, Ubuntu, and derivatives
* `.rpm` files, as used by CentOS, RedHat, and derivatives
* `snapcraft` files, as used by the Ubuntu Snappy package manager

## Usage

### On a system with all necessary build-time dependencies:

#### SpiderMonkey 1.8.5

##### rpms

```shell
make couch-js-rpms
```

##### debs

```shell
make couch-js-debs PLATFORM=$(lsb_release -cs)
```

#### CouchDB

##### rpms or debs from `master` branch:

```shell
cd .. && git clone https://github.com/apache/couchdb
cd couchdb-pkg && make build-couch $(lsb_release -cs) PLATFORM=$(lsb_release -cs)
```

##### rpms or debs from a release tarball:

```shell
make copy-couch $(lsb_release -cs) COUCHTARBALL=path/to/couchdb-#.#.#.tar.gz PLATFORM=$(lsb_release -cs)
```

-----

### Building inside the `couchdbdev` docker containers

You must first pull down the image or images you need from Docker Hub, or build the images
using the [apache/couchdb-ci](https://github.com/apache/couchdb-ci) repository. A full
list of supported environments is at https://hub.docker.com/u/couchdbdev/ .

#### SpiderMonkey 1.8.5

```shell
docker pull couchdbdev/<os>-<codename>-base
./build.sh js <os>-<codename>    # for example, debian-stretch, ubuntu-bionic or centos-7.
```

#### CouchDB

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

## Building packages for a release

### Prerequisites

1. Linux running Docker
1. The current user must be capable of running `docker run`.
1. Enough free disk space to download all of the Docker images + build
   CouchDB.

### Running the package build

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

### Uploading the packages

If you have Apache credentials (set your `BINARY_CREDS` environment variable appropriately), after building all CouchDB packages above, **and signing the rpms with the appropriate GPG key using the `rpmsign --addsign <file.rpm>` command**, simply run:

    ./build.sh couch-upload-all

Or, for the SpiderMonkey packages:

    ./build.sh js-upload-all

-----

## Upload Dev Packages

`couch-dev-deb` and `couch-dev-rpm` are dev repos which can be used
for pre-release or testing of packages.

To upload packages to the dev repository:

    ./build.sh couch-dev-upload-all path/to/apache-couchdb-VERSION.tar.gz

To upload only a subset of packages, edit build.sh temporary to remove some of these variables:
```
DEBIANS="..."
UBUNTUS="..."
CENTOSES="..."
XPLAT_BASES="..."
XPLAT_ARCHES="..."
```

## Install Dev Packages

### Deb Packages

```
sudo apt update && sudo apt install -y curl apt-transport-https gnupg
curl https://couchdb.apache.org/repo/keys.asc | gpg --dearmor | sudo tee /usr/share/keyrings/couchdb-archive-keyring.gpg >/dev/null 2>&1
source /etc/os-release
echo "deb [signed-by=/usr/share/keyrings/couchdb-archive-keyring.gpg] https://apache.jfrog.io/artifactory/couch-dev-deb/ ${VERSION_CODENAME} main" \
    | sudo tee /etc/apt/sources.list.d/couchdb.list >/dev/null
```

### RPM Packages

#### RHEL/AlmaLinux/RockyLinux 8

```
sudo dnf install -y yum-utils
sudo yum-config-manager --add-repo https://apache.jfrog.io/artifactory/couchdb/couchdev.repo
sudo dnf install -y couchdb
```

#### RHEL/AlmaLinux/RockyLinux 9

```
sudo dnf install -y yum-utils
sudo yum-config-manager --add-repo https://apache.jfrog.io/artifactory/couchdb/couchdev.repo
sudo dnf config-manager --set-enabled crb
sudo dnf install epel-release epel-next-release
sudo dnf install -y mozjs78
sudo dnf install -y couchdb
```

#### Enable Nouveau

To try out Nouveau:

1. Use `COUCHDB_NOUVEAU_ENABLE=1` when installing the couchdb package.
   That enables the `nouveau` config setting

2. Install Java 11+:
```
    sudo dnf install java-21-openjdk-headless
```

3. Start the service:
```
    sudo service start couchdb
```


## Snap packages

See [README-SNAP.md](README-SNAP.md).

-----

## Feedback, Issues, Contributing

General feedback is welcome at our [user][1] or [developer][2] mailing lists.

Apache CouchDB has a [CONTRIBUTING][3] file with details on how to get started
with issue reporting or contributing to the upkeep of this project.

[1]: http://mail-archives.apache.org/mod_mbox/couchdb-user/
[2]: http://mail-archives.apache.org/mod_mbox/couchdb-dev/
[3]: https://github.com/apache/couchdb/blob/main/CONTRIBUTING.md

