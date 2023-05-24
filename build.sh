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

# TODO derive these by interrogating the couchdb-ci repo rather than hard coding the list
DEBIANS="debian-buster debian-bullseye"
UBUNTUS="ubuntu-bionic ubuntu-focal ubuntu-jammy"
CENTOSES="centos-7 centos-8 centos-9"
XPLAT_BASES="debian-bullseye ubuntu-focal ubuntu-jammy centos-8 centos-9"
XPLAT_ARCHES="arm64 ppc64le s390x"
BINARY_API="https://apache.jfrog.io/artifactory"
ERLANGVERSION=${ERLANGVERSION:-24.3.4.10}

split-os-ver() {
  OLDIFS=$IFS
  IFS='-' tokens=( $1 )
  IFS=$OLDIFS
  os=${tokens[0]}
  version=${tokens[1]}
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
      exit 1
    fi
  fi
  echo Using ${COUCHTARBALL} to build packages...
  chmod 777 ${COUCHTARBALL}
}

build-couch() {
  split-os-ver $1
  # We will be changing user to 'jenkins' - ensure it has write permissions
  chmod a+rwx pkgs pkgs/couch pkgs/js
  # $1 is plat, $2 is the optional path to a dist tarball
  if [ -z ${CONTAINERARCH+x} ]; then
    docker run \
        --mount type=bind,src=${SCRIPTPATH},dst=/home/jenkins/couchdb-pkg \
        -u 0 -w /home/jenkins/couchdb-pkg \
        --platform linux/amd64 \
        apache/couchdbci-${os}:${version}-erlang-${ERLANGVERSION} \
        make copy-couch $1 COUCHTARBALL=${COUCHTARBALL}
  else
    docker run \
        --mount type=bind,src=${SCRIPTPATH},dst=/home/jenkins/couchdb-pkg \
        -u 0 -w /home/jenkins/couchdb-pkg \
        --platform linux/${CONTAINERARCH} \
        apache/couchdbci-${os}:${version}-erlang-${ERLANGVERSION} \
        make copy-couch ${CONTAINERARCH}-$1 COUCHTARBALL=${COUCHTARBALL}
  fi
  make clean
}

build-all-couch() {
  rm -rf ${SCRIPTPATH}/pkgs/couch/*
  for plat in $DEBIANS $UBUNTUS $CENTOSES; do
    build-couch $plat $*
  done
  for base in $XPLAT_BASES; do
    for arch in $XPLAT_ARCHES; do
      if [[ ${base} != "centos-8" ]] || [[ ${arch} != "arm64" ]]; then
        CONTAINERARCH="${arch}" build-couch ${base}
      fi
    done
  done
}


binary-upload() {
  echo "Uploading ${PKG}..."
  local ret="$(curl \
      --request PUT \
      --upload-file $PKG \
      --user ${BINARY_CREDS} \
      "${BINARY_API}/${REPO}/${RELPATH}${SUFFIX}")"
  if [[ ${ret} =~ '"created" :' ]]; then
    echo "Uploaded successfully."
  else
    echo "Failed to upload $PKG, ${ret}"
    exit 1
  fi
}

upload-couch() {
  # invoke with $1 as plat, expect to find the binaries under pkgs/couch/$plat/*
  if [ -z ${BINARY_CREDS+x} ]; then
    echo "Please set your upload credentials before using this command:"
    echo "  export BINARY_CREDS=<user@domain:KEYGOESHERE>"
    exit 1
  fi
  for PKG in $(ls pkgs/couch/$1/*.deb 2>/dev/null); do
    # Example filename: couchdb_2.3.0~jessie_amd64.deb
    fname=${PKG##*/}
    REPO="couchdb-deb"
    RELPATH="pool/C/CouchDB/${fname}"
    DIST=$(echo $fname | cut -d~ -f 2 | cut -d_ -f 1)
    PKGARCH=$(echo $fname | cut -d_ -f 3 | cut -d. -f 1)
    PKGVERSION=$(echo $fname | cut -d_ -f 2 | cut -d~ -f 1)
    SUFFIX=";deb.distribution=${DIST}"
    SUFFIX+=";deb.component=main"
    SUFFIX+=";deb.architecture=${PKGARCH}"
    binary-upload
  done
  for PKG in $(ls pkgs/couch/$1/*.rpm 2>/dev/null); do
    # Example filename: couchdb-2.3.0-1.el7.x86_64.rpm.asc
    #                   couchdb-3.3.1.1.1-1.el7.x86_64.rpm
    fname=${PKG##*/}
    REPO="couchdb-rpm"
    DIST=$(echo $fname | cut -d- -f 3 | cut -d. -f 2)
    PKGARCH=$(echo $fname | cut -d- -f 3 | cut -d. -f 3)
    PKGVERSION=$(echo $fname | cut -d- -f 2)
    RELPATH="${DIST}/${PKGARCH}/${fname}"
    SUFFIX=""
    binary-upload
    if [ ${DIST} == "el7" ]; then
        # see https://github.com/apache/couchdb-pkg/issues/103
        DIST="el7Server"
        RELPATH="${DIST}/${PKGARCH}/${fname}"
        SUFFIX=""
        binary-upload
    elif [ ${DIST} == "el8" ]; then
        # see https://github.com/apache/couchdb-pkg/issues/103
        DIST="el8Server"
        RELPATH="${DIST}/${PKGARCH}/${fname}"
        SUFFIX=""
        binary-upload
    fi
  done
  echo "Recalculating Debian repo metadata..."
  local ret="$(curl \
    --request POST \
    --user ${BINARY_CREDS} \
    "${BINARY_API}/api/deb/reindex/couchdb-deb")"
  echo "${ret}"
}

usage() {
  cat << EOF
$0 <command> [OPTIONS]

Recognized commands:
  clean                 Remove all built package artefacts.
  couch <plat> <src>    Builds CouchDB packages for <plat>.
  couch-all <src>       Builds CouchDB packages for all platforms.
  *couch-upload <plat>  Uploads the JS packages for <plat> to binary.
  *couch-upload-all     Uploads the JS packages for all platforms to binary.

  <src> is either
    - a path/to/a/couchdb.tar.gz, or
    - a URL to http(s)://domain.com/to/couchdb.tar.gz

  Commands marked with * require BINARY_CREDS env var.
EOF
}


case "$1" in
  clean)
    # removes built pkgs for all platforms
    shift
    rm -rf ${SCRIPTPATH}/pkgs/js/* ${SCRIPTPATH}/pkgs/couch/*
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
    usage
    if [[ $1 ]]; then
      exit 1
    fi
    ;;
esac

exit 0
