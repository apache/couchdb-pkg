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

# This shell script detects the OS we're on, and sets a number
# of environment variables the calling script can use.

# It uses the systemd standard of variables, and attempts to
# populate some of the variables manually if systemd is not
# present on the underlying OS.

# Example systemd /etc/os-release file:
# NAME="Ubuntu"
# VERSION="16.04.4 LTS (Xenial Xerus)"
# ID=ubuntu
# ID_LIKE=debian
# PRETTY_NAME="Ubuntu 16.04.4 LTS"
# VERSION_ID="16.04"
# HOME_URL="http://www.ubuntu.com/"
# SUPPORT_URL="http://help.ubuntu.com/"
# BUG_REPORT_URL="http://bugs.launchpad.net/ubuntu/"
# VERSION_CODENAME=xenial
# UBUNTU_CODENAME=xenial

# While these scripts are primarily written to support building CI
# Docker images, they can be used on any workstation to install a
# suitable build environment.

# stop on error
set -e

case "${OSTYPE}" in
  linux*)
    echo "Detected OS: Linux"
    # Try the new, systemd-based way first
    . /etc/os-release 2>/dev/null || true
    # then try lsb_release, which might be installed
    # os-release doesn't actually give us everything we want...
    lsb_plat=$(lsb_release -d 2>/dev/null | awk -F"\t" '{print $2}' 2>/dev/null)
    if [[ ${lsb_plat} ]]; then
      if [[ ${lsb_plat} =~ "^Debian" ]]; then
        ID=${ID:-debian}
        VERSION_ID=${VERSION_ID:-$(echo ${lsb_plat} | awk '{print $3}' | awk -F'.' '{print $1}')}
        VERSION_CODENAME=${VERSION_CODENAME:-$(echo ${lsb_plat} | awk '{print $4}' | sed 's/[\(\)]//g')}
        DISTRIB_CODENAME=${DISTRIB_CODENAME:-${VERSION_CODENAME}}
      elif  [[ ${lsb_plat} =~ "^Ubuntu" ]]; then
        ID=${ID:-ubuntu}
        VERSION_ID=${VERSION_ID:-$(echo ${lsb_plat} | awk '{print $2}' | awk -F'.' '{print $1}')}
        VERSION_CODENAME=${VERSION_CODENAME:-$(lsb_release -cs)}
        DISTRIB_CODENAME=${DISTRIB_CODENAME:-${VERSION_CODENAME}}
      fi
    fi
    # and finally some rough heuristics
    if [[ -f /etc/redhat-release ]]; then
      # /etc/redhat-release is so inconsistent, we use rpm instead
      rhelish=$(rpm -qa '(redhat|sl|slf|centos|centos-linux|oraclelinux)-release(|-server|-workstation|-client|-computenode)' 2>/dev/null | head -1)
      if [[ $rhelish ]]; then
        ID=${ID:-$(echo ${rhelish} | awk -F'-' '{print tolower($1)}')}
        VERSION_ID=${VERSION_ID:-$(echo ${rhelish} | sed -E 's/([^[:digit:]]+)([[:digit:]]+)(.*)/\2/' )}
        VERSION_CODENAME=${VERSION_CODENAME:-${VERSION_ID}}
        DISTRIB_CODENAME=${VERSION_CODENAME:-${VERSION_ID}}
      fi
    elif [[ -f /etc/debian_version ]]; then
      # Ubuntu keeps changing the format of /etc/os-release's VERSION, and
      # it's numeric, not the codename. Boo.
      # Also, Debian doesn't supply VERSION_CODENAME. Double Boo.
      if [[ ${PRETTY_NAME} =~ "Ubuntu" ]]; then
        # Ubuntu keeps changing the format of /etc/os-release's VERSION, and
        # the codename is buried. Boo. Let's use a fancy regex.
        VERSION_ID=${VERSION_ID:-$(dpkg --status tzdata|grep Provides|cut -f2 -d'-')}
        VERSION_CODENAME=${VERSION_CODENAME:-$(echo ${VERSION} | sed -E 's/([0-9.]+)\W+([A-Za-z\,]+)\W+\(?(\w+)(.*)/\L\3/')}
        DISTRIB_CODENAME=${DISTRIB_CODENAME:-${VERSION_CODENAME}}
      elif [[ ${PRETTY_NAME} =~ "Debian" ]]; then
        VERSION_ID=${VERSION_ID:-$(dpkg --status tzdata|grep Provides|cut -f2 -d'-')}
        VERSION=${VERSION:-${VERSION_ID}}
        VERSION_CODENAME=${VERSION_CODENAME:-$(echo ${VERSION} | sed -E 's/(.*)\(([^\]+)\)/\2/' | sed -E 's/(.*)\/.*/\1/')}
        DISTRIB_CODENAME=${DISTRIB_CODENAME:-${VERSION_CODENAME}}
      else
        echo "Unknown Debian-like OS ${PRETTY_NAME}, aborting..."
        exit 1
      fi
    fi
    if [[ ${ID} && ${VERSION_ID} && ${VERSION_CODENAME} ]]; then
      echo "Detected distribution: ${ID}, version ${VERSION_ID} (${VERSION_CODENAME})"
    else
      echo "Unable to determine Linux distribution! Aborting."
      echo "Detected: ID=${ID}, VERSION_ID=${VERSION_ID}, VERSION_CODENAME=(${VERSION_CODENAME})"
      exit 1
    fi
    ;;

  freebsd*)
    echo "Detected OS: FreeBSD"
    # use userland version
    VERSION=$(freebsd-version -u | cut -d '-' -f1)
    ;;
  *bsd*)
    # TODO: detect netbsd vs. freebsd vs. openbsd?
    echo "Detected OS: BSD - UNSUPPORTED"
    exit 1
    ;;
  darwin*)
    # TODO
    echo "Detected OS: macOS (OSX) - UNSUPPORTED"
    exit 1
    ;;
  solaris*)
    # TODO
    echo "Detected OS: Solaris-like"
    exit 1
    ;;
  msys*)
    # TODO
    echo "Detected OS: Windows (msys)"
    exit 1
    ;;
  cygwin*)
    # TODO
    echo "Detected OS: Windows (cygwin)"
    exit 1
    ;;
  *)
    echo "Unknown OS detected: ${OSTYPE}"
    exit 1
    ;;
esac
