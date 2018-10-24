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

# This shell script detects which architecture we're currently
# operating on, and sets an environment variable the calling
# script can use.

# stop on error
set -e

case "${OSTYPE}" in
  linux*)
      if [ -x /usr/bin/arch -o -x /bin/arch ]; then
	  export ARCH=`arch`
      fi

      if [ -x /usr/bin/uname -o -x /bin/uname ]; then
	  export ARCH=`uname -m`
      fi

      if [ "$ARCH" == "" ]; then
	  echo "$0 uses 'arch' or 'uname' which appear to be missing"
	  exit 1
      fi
      ;;
  *bsd*)
    # TODO
    echo "Currently unable to detect Arch on BSD"
    exit 1
    ;;
  darwin*)
    # TODO
    echo "Currently unable to detect Arch on macOS (OSX)"
    exit 1
    ;;
  solaris*)
    # TODO
    echo "Currently unable to detect Arch on Solaris-like OS"
    exit 1
    ;;
  msys*)
    # TODO
    echo "Currently unable to detect Arch on Windows (msys)"
    exit 1
    ;;
  cygwin*)
    # TODO
    echo "Currently unable to detect Arch on Windows (cygwin)"
    exit 1
    ;;
  *)
    echo "Unknown OS detected: ${OSTYPE}"
    exit 1
    ;;
esac

echo "Detected architecture: $ARCH"
