#!/bin/bash
IMAGES=(
  centos-6-erlang-19.3.6 centos6 \
  centos-7-erlang-19.3.6 centos7 \
  debian-jessie-erlang-19.3.6 jessie \
  debian-stretch-erlang-19.3.6 stretch \
  ubuntu-trusty-erlang-19.3.6 trusty \
  ubuntu-xenial-erlang-19.3.6 xenial \
  ubuntu-bionic-erlang-19.3.6 bionic
)

usage() {
  echo $0 takes exactly one argument, either:
  echo '  - path/to/couchdb-VERSION.tar.gz or'
  echo '  - http://url/to/couchdb-VERSION.tar.gz'
  echo
  exit
}

if [ $# -ne "1" ]
then
  usage
fi

ARG=$1

if [ -f ${ARG} ]
then
  # file
  cp ${ARG} . 2>/dev/null || true
  FILE=$(basename ${ARG})
else
  if [[ ${ARG} =~ ^http.*$ ]]
  then
    # url
    # thank you, advanced bash scripting guide
    curl -O ${ARG}
    FILE=${ARG##*/}
  else
    usage
  fi
fi

echo Using ${FILE} to build packages...
chmod 777 ${FILE}

mkdir -p pkgs && chmod 777 pkgs

image_count=${#IMAGES[@]}
index=0

while [ "$index" -lt "$image_count" ]
do
  img=${IMAGES[$index]}
  ((index++))
  plat=${IMAGES[$index]}
  ((index++))
  docker run -it -w /tmp/couchdb-pkg -v $(readlink -f .):/tmp/couchdb-pkg couchdbdev/$img make copy-couch $plat copy-pkgs PLATFORM=$plat COUCHTARBALL=${FILE}
done
