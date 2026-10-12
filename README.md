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

### Building inside the `couchdbci` docker containers

`build.sh` runs the package build as a `docker buildx build` with an
`apache/couchdbci-<os>:<codename>-erlang-<version>` image from
DockerHub. Those are built in the
[apache/couchdb-ci](https://github.com/apache/couchdb-ci) repo. The
image is pulled automatically and the resulting packages are written
to `pkgs/couch/<os>-<codename>/`.

From a downloaded CouchDB tarball:

```shell
ERLANGVERSION=<erlang-version> ./build.sh couch <os>-<codename> path/to/couchdb-#.#.#.tar.gz
```

Directly from the Apache source CDN:

```shell
./build.sh couch <os>-<codename> https://dist.apache.org/repos/dist/release/couchdb/source/#.#.#/apache-couchdb-#.#.#.tar.gz
```

For another architecture:

```shell
CONTAINERARCH=arm64 ./build.sh couch <os>-<codename> path/to/couchdb-#.#.#.tar.gz
```

The build is run on with buildx. With the `default` builder a foreign
arch is run under qemu (needs `binfmt_misc` handlers on the host (for
example `docker run --privileged --rm tonistiigi/binfmt --install
arm64`). To build natively use an arch specific set of builders. One
node per arch. For example:

```shell
docker buildx create --name multiarch --use ssh://my-amd64-host
docker buildx create --name multiarch --append ssh://my-arm64-host
```

Then, `buildx` will pick the node based on `--platform`. Use
`BUILDKIT_PROGRESS=auto` for a less noisy buildx progress view.

-----

## Building packages for a release

### Prerequisites

1. Linux running Docker with buildx.
1. User must be able of running `docker buildx build`.
1. For non-x86_64 packages, need either qemu `binfmt_misc` handlers,
   or buildx builders with native nodes (see above).
1. Enough free disk space on the builder to download all of the Docker
   images + build CouchDB. Build layers stay in the builder's
   cache. But can use `docker buildx prune` to clean up if needed.

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

### Uploading the packages

If you have Apache credentials (set your `BINARY_CREDS` environment variable appropriately), after building all CouchDB packages above, **and signing the rpms with the appropriate GPG key using the `rpmsign --addsign <file.rpm>` command**, simply run:

    ./build.sh couch-upload-all

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

As root or under `sudo`
```
dnf install -y yum-utils
yum-config-manager --add-repo https://apache.jfrog.io/artifactory/couchdb/couchdev.repo
dnf install -y couchdb
```

#### RHEL/AlmaLinux/RockyLinux 9

As root or under `sudo`
```
dnf install -y yum-utils
yum-config-manager --add-repo https://apache.jfrog.io/artifactory/couchdb/couchdev.repo
dnf config-manager --set-enabled crb
dnf install epel-release epel-next-release
dnf install -y mozjs78
dnf install -y couchdb
```

#### RHEL/AlmaLinux/RockyLinux 10

As root or under `sudo`
```
dnf install -y yum-utils
yum-config-manager --add-repo https://apache.jfrog.io/artifactory/couchdb/couchdev.repo
dnf install -y couchdb
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

