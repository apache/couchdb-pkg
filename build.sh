#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing,
#   software distributed under the License is distributed on an
#   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#   KIND, either express or implied.  See the License for the
#   specific language governing permissions and limitations
#   under the License.

# This is the master shell script to build Docker containers
# for CouchDB 2.x.

# stop on error
set -e

# This works if we're not called through a symlink
# otherwise, see https://stackoverflow.com/questions/59895/
SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# TODO derive these by interrogating the Docker repo rather tha
# hard coding the list
DEBIANS="debian-stretch aarch64-debian-stretch debian-buster aarch64-debian-buster"
UBUNTUS="ubuntu-trusty ubuntu-xenial ubuntu-bionic"
debs="(debian-stretch|aarch64-debian-stretch|debian-buster|aarch64-debian-buster|ubuntu-trusty|ubuntu-xenial|ubuntu-bionic)"

CENTOSES="centos-6 centos-7"
rpms="(centos-6|centos-7)"

BINTRAY_API="https://api.bintray.com"
ERLANGVERSION=${ERLANGVERSION:-19.3.6}


build-js() {
  # TODO: check if image is built first, if not, complain
  # invoke as build-js <plat>
  if [[ ${TRAVIS} == "true" ]]; then
    docker run \
        --mount type=bind,src=${SCRIPTPATH},dst=/home/jenkins/couchdb-pkg \
        -u 0 couchdbdev/$1-base \
        /home/jenkins/couchdb-pkg/bin/build-js.sh
  else
    docker run \
        --mount type=bind,src=${SCRIPTPATH},dst=/home/jenkins/couchdb-pkg \
        couchdbdev/$1-base \
        sudo /home/jenkins/couchdb-pkg/bin/build-js.sh
  fi
}

build-all-js() {
  rm -rf ${SCRIPTPATH}/pkgs/js/*
  for plat in $DEBIANS $UBUNTUS $CENTOSES; do
    build-js $plat
  done
}

bintray-check-credentials() {
  if [[ ! ${BINTRAY_USER} || ! ${BINTRAY_API_KEY} ]]; then
    echo "Please set your Bintray credentials before using this command:"
    echo "  export BINTRAY_USER=<username>"
    echo "  export BINTRAY_API_KEY=<key>"
    exit 1
  fi
}

bintray-upload() {
  echo "Uploading ${PKG}..."
  local ret="$(curl \
      --request PUT \
      --upload-file $PKG \
      --user ${BINTRAY_USER}:${BINTRAY_API_KEY} \
      --header "X-Bintray-Package: ${PKGNAME}" \
      --header "X-Bintray-Version: ${PKGVERSION}" \
      --header "X-Bintray-Publish: 1" \
      --header "X-Bintray-Override: 1" \
      --header "X-Bintray-Explode: 0" \
      "${HEADERS[@]}" \
      "${BINTRAY_API}/content/apache/${REPO}/${RELPATH}")"
  if [[ ${ret} == '{"message":"success"}' ]]; then
    echo "Uploaded successfully."
  else
    echo "Failed to upload $PKG, ${ret}"
    exit 1
  fi
}

upload-js() {
  # invoke with $1 as plat, expect to find the binaries under pkgs/js/$plat/*
  bintray-check-credentials
  # Debian packages first
  PKGNAME="spidermonkey"
  PKGVERSION="1.8.5"
  for PKG in $(ls pkgs/js/$1/*.deb 2>/dev/null); do
    # Example filename: couch-libmozjs185-1.0_1.8.5-1.0.0+couch-2~bionic_amd64.deb
    # TODO: pull this stuff from buildinfo / changes files, perhaps? Not sure it matters.
    REPO="couchdb-deb"
    fname=${PKG##*/}
    DIST=$(echo $fname | cut -d~ -f 2 | cut -d_ -f 1)
    PKGARCH=$(echo $fname | cut -d_ -f 3 | cut -d. -f 1)
    RELPATH="pool/s/spidermonkey/${fname}"
    HEADERS=("--header" "X-Bintray-Debian-Distribution: ${DIST}")
    HEADERS+=("--header" "X-Bintray-Debian-Component: main")
    HEADERS+=("--header" "X-Bintray-Debian-Architecture: ${PKGARCH}")
    bintray-upload
  done
  for PKG in $(ls pkgs/js/$1/*.rpm 2>/dev/null); do
    # Example filename: couch-js-1.8.5-21.el7.x86_64.rpm
    REPO="couchdb-rpm"
    fname=${PKG##*/}
    # better not put any extra . in the filename...
    DIST=$(echo $fname | cut -d. -f 4)
    PKGARCH=$(echo $fname | cut -d. -f 5)
    RELPATH="${DIST}/${PKGARCH}/${fname}"
    HEADERS=()
    bintray-upload
  done
}

cannot-find-tarball() {
    echo Must supply path to tarball, either:
    echo '  - path/to/couchdb-VERSION.tar.gz or'
    echo '  - http(s)://url/to/couchdb-VERSION.tar.gz'
    echo
    exit 1
}

get-couch-tarball() {
  if [ $# -ne "1" ]
  then
    cannot-find-tarball
  fi
  ARG=$1
  if [ -f $ARG ]
  then
    # file
    cp $ARG . 2>/dev/null || true
    COUCHTARBALL=$(basename ${ARG})
  else
    if [[ $ARG =~ ^http.*$ ]]
    then
      #url
      # thank you, advanced bash scripting guide
      curl -O $ARG
      COUCHTARBALL=${ARG##*/}
    else
      usage
    fi
  fi
  echo Using ${COUCHTARBALL} to build packages...
  chmod 777 ${COUCHTARBALL}
}

build-couch() {
  # We will be changing user to 'jenkins' - ensure it has write permissions
  chmod a+rwx pkgs pkgs/couch pkgs/js
  # $1 is plat, $2 is the optional path to a dist tarball
  docker run \
      --mount type=bind,src=${SCRIPTPATH},dst=/home/jenkins/couchdb-pkg \
      -w /home/jenkins/couchdb-pkg \
      couchdbdev/$1-erlang-${ERLANGVERSION} \
      make copy-couch $1 COUCHTARBALL=${COUCHTARBALL}
}

build-all-couch() {
  rm -rf ${SCRIPTPATH}/pkgs/couch/*
  for plat in $DEBIANS $UBUNTUS $CENTOSES; do
    build-couch $plat $*
  done
}

upload-couch() {
  # invoke with $1 as plat, expect to find the binaries under pkgs/couch/$plat/*
  bintray-check-credentials
  # Debian packages first
  PKGNAME="CouchDB"
  for PKG in $(ls pkgs/couch/$1/*.deb 2>/dev/null); do
    # Example filename: couchdb_2.3.0~jessie_amd64.deb
    # TODO: pull this stuff from buildinfo / changes files, perhaps? Not sure it matters.
    fname=${PKG##*/}
    REPO="couchdb-deb"
    DIST=$(echo $fname | cut -d~ -f 2 | cut -d_ -f 1)
    PKGARCH=$(echo $fname | cut -d_ -f 3 | cut -d. -f 1)
    PKGVERSION=$(echo $fname | cut -d_ -f 2 | cut -d~ -f 1)
    RELPATH="pool/C/CouchDB/${fname}"
    HEADERS=("--header" "X-Bintray-Debian-Distribution: ${DIST}")
    HEADERS+=("--header" "X-Bintray-Debian-Component: main")
    HEADERS+=("--header" "X-Bintray-Debian-Architecture: ${PKGARCH}")
    bintray-upload
  done
  for PKG in $(ls pkgs/couch/$1/*.rpm 2>/dev/null); do
    # Example filename: couchdb-2.3.0-1.el7.x86_64.rpm.asc
    fname=${PKG##*/}
    REPO="couchdb-rpm"
    # better not put any extra . in the filename...
    DIST=$(echo $fname | cut -d. -f 4)
    PKGARCH=$(echo $fname | cut -d. -f 5)
    PKGVERSION=$(echo $fname | cut -d- -f 2)
    RELPATH="${DIST}/${PKGARCH}/${fname}"
    HEADERS=()
    bintray-upload
  done
}


case "$1" in
  clean)
    # removes built pkgs for all platforms
    shift
    rm -rf ${SCRIPTPATH}/pkgs/js/* ${SCRIPTPATH}/pkgs/couch/*
    ;;
  js)
    # Build js packages for a given platform
    shift
    build-js $1
    ;;
  js-all)
    # build all supported JS packages
    shift
    build-all-js
    ;;
  js-upload)
    shift
    upload-js $1
    ;;
  js-upload-all)
    shift
    for dir in $(ls pkgs/js); do
      upload-js $dir
    done
    ;;
  couch)
    # build CouchDB pkgs for <plat>
    shift
    get-couch-tarball $2
    build-couch $*
    ;;
  couch-all)
    # build CouchDB pkgs for all platforms
    shift
    get-couch-tarball $1
    build-all-couch
    ;;
  couch-upload)
    shift
    upload-couch $1
    ;;
  couch-upload-all)
    shift
    for dir in $(ls pkgs/couch); do
      upload-couch $dir
    done
    ;;
  *)
    if [[ $1 ]]; then
      echo "Unknown target $1."
      echo
    fi
    cat << EOF
$0 <command> [OPTIONS]

Recognized commands:
  clean                 Remove all built package artefacts.

  js <plat>             Builds the JS packages for <plat>.
  js-all                Builds the JS packages for all platforms.
  *js-upload <plat>     Uploads the JS packages for <plat> to bintray.
  *js-upload-all        Uploads the JS packages for all platforms to bintray.

  couch <plat> <src>    Builds CouchDB packages for <plat>.
  couch-all <src>       Builds CouchDB packages for all platforms.
  *couch-upload <plat>  Uploads the JS packages for <plat> to bintray.
  *couch-upload-all     Uploads the JS packages for all platforms to bintray.

  <src> is either
    - a path/to/a/couchdb.tar.gz, or
    - a URL to http(s)://domain.com/to/couchdb.tar.gz

  Commands marked with * require BINTRAY_USER and BINTRAY_API_KEY env vars.
EOF
    if [[ $1 ]]; then
      exit 1
    fi
    ;;
esac

exit 0
