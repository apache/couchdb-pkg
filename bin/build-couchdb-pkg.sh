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

# This shell script builds and tests CouchDB on the current host.
# It assumes the build environment is already set up correctly.
# It needs no special privileges.

# stop on error
set -e

SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. ${SCRIPTPATH}/detect-os.sh

redhats='(rhel|centos|fedora)'
debians='(debian|ubuntu)'

cd /home/jenkins

if [[ $1 ]]; then
  # use copied package
  mkdir couchdb
  tar -xf ${SCRIPTPATH}/../$1 -C couchdb
  cp ${SCRIPTPATH}/../$1 couchdb
else
  # use master branch
  git clone https://github.com/apache/couchdb
  cd couchdb
  ./configure -c
  make dist
  cd ..
fi

# now, build the package
cd couchdb-pkg
platform=${ID}-${VERSION_CODENAME}
make $platform PLATFORM=${VERSION_CODENAME}

# and save the output
if [[ ${ID} =~ ${redhats} ]]; then
  mv ../rpmbuild/RPMS/* ${SCRIPTPATH}/../couch/$platform
elif [[ ${ID} =~ ${debians} ]]; then
  mv ../couchdb/*.deb ${SCRIPTPATH}/../couch/$platform
else
  echo "Sorry, we don't support this Linux (${ID}) yet."
  exit 1
fi
# and make sure we can delete it if necessary
chmod -R a+rwx  ${SCRIPTPATH}/../couch/$platform/*
