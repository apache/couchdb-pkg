# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

COUCHDIR=../couchdb
DEBCHANGELOG="Automatically generated package from upstream."

JS_DEBCHANGELOG="Automatically generated package from couchdb-ci repository."

export DEBFULLNAME=CouchDB Developers
export DEBEMAIL=dev@couchdb.apache.org

# Default package directory (over-written for RPM based builds)
PKGDIR=$(COUCHDIR)

# RPMs go into the RPMS/<arch> dir where where <arch> is `uname -m`
# (x86_64, aarch64, ppc64le, ...). DEB builds figure out their own arch
PKGARCH=$(shell arch)

# Overridden for targets with SM60 in per-target env vars below.
SPIDERMONKEY=couch-libmozjs185-1.0
SPIDERMONKEY_DEV=couch-libmozjs185-dev
SM_VER=1.8.5
JS_ENGINE=spidermonkey

# Java
JAVA_RUNTIME=java21-runtime-headless | java21-runtime

# Try and guess the correct target...
all:
	make `bin/detect-target.sh`

# arch specific prefixes arm64-ubuntu-noble are aliases for plain
# target
arm64-%: % ; @:
arm64v8-%: % ; @:
aarch64-%: % ; @:
ppc64le-%: % ; @:
s390x-%: % ; @:

# Debian default
debian: sm-ver-debian find-couch-dist copy-debian update-changelog dpkg lintian copy-pkgs

# Debian 12 - bookworm
debian-bookworm: PLATFORM=bookworm
debian-bookworm: DIST=debian-bookworm
debian-bookworm: SPIDERMONKEY=libmozjs-78-0
debian-bookworm: SPIDERMONKEY_DEV=libmozjs-78-dev
debian-bookworm: SM_VER=78
debian-bookworm: bookworm

bookworm: debian

# Debian 13 - trixie
debian-trixie: PLATFORM=trixie
debian-trixie: DIST=debian-trixie
debian-trixie: SPIDERMONKEY=libmozjs-128-0
debian-trixie: SPIDERMONKEY_DEV=libmozjs-128-dev
debian-trixie: SM_VER=128
debian-trixie: JAVA_RUNTIME=java21-runtime-headless | java21-runtime
debian-trixie: trixie

trixie: debian

# Ubuntu 22.04 (Jammy)
ubuntu-jammy: PLATFORM=jammy
ubuntu-jammy: DIST=ubuntu-jammy
ubuntu-jammy: SPIDERMONKEY=libmozjs-78-0
ubuntu-jammy: SPIDERMONKEY_DEV=libmozjs-78-dev
ubuntu-jammy: SM_VER=78
ubuntu-jammy: jammy
jammy: debian

# Ubuntu 24.04 (Noble)
ubuntu-noble: PLATFORM=noble
ubuntu-noble: DIST=ubuntu-noble
ubuntu-noble: SPIDERMONKEY=libmozjs-115-0
ubuntu-noble: SPIDERMONKEY_DEV=libmozjs-115-dev
ubuntu-noble: SM_VER=115
ubuntu-noble: noble
noble: debian

# Ubuntu 26.04 (Resolute)
ubuntu-resolute: PLATFORM=resolute
ubuntu-resolute: DIST=ubuntu-resolute
ubuntu-resolute: SPIDERMONKEY=libmozjs-128-0
ubuntu-resolute: SPIDERMONKEY_DEV=libmozjs-128-dev
ubuntu-resolute: SM_VER=128
ubuntu-resolute: resolute
resolute: debian

# RPM default
centos: PKGDIR=../rpmbuild/RPMS/$(PKGARCH)
centos: find-couch-dist link-couch-dist build-rpm copy-pkgs

centos-8: DIST=centos-8
centos-8: centos8
centos8: SPIDERMONKEY=mozjs60
centos8: SPIDERMONKEY_DEV=mozjs60-devel
centos8: SM_VER=60
centos8: sm-ver-rpm make-rpmbuild centos

centos-9: DIST=centos-9
centos-9: centos9
centos9: SPIDERMONKEY=mozjs78
centos9: SPIDERMONKEY_DEV=mozjs78-devel
centos9: SM_VER=78
centos9: sm-ver-rpm make-rpmbuild centos

centos-10: DIST=centos-10
centos-10: centos10
centos10: JS_ENGINE=quickjs
centos10: sm-ver-rpm make-rpmbuild centos

# Almalinux 8 is a CentOS 8 alias
almalinux-8: centos-8
almalinux-8.8: centos-8
almalinux-8.9: centos-8
almalinux-8.10: centos-8

# Almalinux 9 is a CentOS 9 alias
almalinux-9: centos-9
almalinux-9.2: centos-9
almalinux-9.4: centos-9
almalinux-9.5: centos-9
almalinux-9.6: centos-9
almalinux-9.7: centos-9
almalinux-9.8: centos-9

# Almalinux 10 is a CentOS 10 alias
almalinux-10: centos-10
almalinux-10.1: centos-10
almalinux-10.2: centos-10

# aarch64 RHEL-based
aarch64-rhel: DIST=rhel
# Needs 68 for aarch compat, we're using the included one here
aarch64-rhel: SPIDERMONKEY=couch-js-68
aarch64-rhel: SPIDERMONKEY_DEV=couch-js-68-devel
aarch64-rhel: SM_VER=68
aarch64-rhel: sm-ver-rpm make-rpmbuild centos

# ######################################
get-couch:
	mkdir -p $(COUCHDIR)
	git clone https://github.com/apache/couchdb

download-couch:
	mkdir -p $(COUCHDIR)
	cd $(COUCHDIR) && curl -O $(URL) && tar xfz *.tar.gz

copy-couch:
	mkdir -p $(COUCHDIR)
	cp $(COUCHTARBALL) $(COUCHDIR)
	cd $(COUCHDIR) && tar xfz *.tar.gz

build-couch:
	cd $(COUCHDIR) && make dist

# ######################################
sm-ver-debian:
	sed 's/%SPIDERMONKEY%/$(SPIDERMONKEY)/g;s/%SPIDERMONKEY_DEV%/$(SPIDERMONKEY_DEV)/g;s/%JAVA_RUNTIME%/$(JAVA_RUNTIME)/g' \
	debian/control.in > debian/control
	echo 'SM_VER = $(SM_VER)' > debian/sm_ver.mk

find-couch-dist:
	$(eval SHORTDISTDIR := $(shell cd $(COUCHDIR) && find . -type d -name apache-couchdb-\*))
	$(eval VERSION := $(shell echo $(SHORTDISTDIR) | sed 's/.\/apache-couchdb-//'))
	$(eval DISTDIR := $(shell readlink -f $(COUCHDIR)/$(SHORTDISTDIR)))

copy-debian:
	rm -rf $(DISTDIR)/debian
	cp -R debian $(DISTDIR)

update-changelog:
	cd $(DISTDIR) && dch -v $(VERSION)~$(PLATFORM) $(DEBCHANGELOG)

dpkg:
	cd $(DISTDIR) && dpkg-buildpackage -b -us -uc

# lintian happens to be stuck on arm64 builds on some ubuntu/debian versions
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=964770
lintian:
	if [ "$(shell arch)" = "x86_64" ]; then cd $(DISTDIR)/.. && lintian --profile couchdb couch*.deb || true ; fi

# ######################################
link-couch-dist:
	rm -rf ../rpmbuild/BUILD
	ln -s $(DISTDIR) ../rpmbuild/BUILD
	$(eval VERSION := $(shell echo $(VERSION) | sed 's/-/\./'))

sm-ver-rpm:
	sed 's/%SPIDERMONKEY%/$(SPIDERMONKEY)/g;s/%SPIDERMONKEY_DEV%/$(SPIDERMONKEY_DEV)/g;s/%SM_VER%/$(SM_VER)/g' \
	rpm/SPECS/couchdb.spec.in > rpm/SPECS/couchdb.spec

make-rpmbuild:
	rm -rf ../rpmbuild
	mkdir -p ../rpmbuild
	cp -R rpm/* ../rpmbuild

# If we don't change $HOME it'll force building in ~/rpmbuild. Boo.
build-rpm:
	$(eval HOME := $(shell readlink -f ..))
	export HOME=$(HOME) && cd ../rpmbuild && rpmbuild --verbose -bb SPECS/couchdb.spec --define '_version $(VERSION)' --define '_js_engine $(JS_ENGINE)'

# ######################################
copy-pkgs:
	chmod a+rwx $(PKGDIR)/couchdb*
	mkdir -p pkgs/couch/$(DIST) && chmod 777 pkgs/couch/$(DIST)
	cp $(PKGDIR)/couchdb* pkgs/couch/$(DIST)

clean:
	if [ -f debian/control.bak ]; then mv -f debian/control.bak debian/control; fi
	if [ -f rpm/SPECS/couchdb.spec.bak ]; then mv -f rpm/SPECS/couchdb.spec.bak rpm/SPECS/couchdb.spec; fi
	rm -rf parts prime stage js/build debian/sm_ver.mk
