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
JS_VERSION=1.8.5-1.0.0+couch-2

export DEBFULLNAME="CouchDB Developers"
export DEBEMAIL="dev@couchdb.apache.org"

# Default package directory (over-written for RPM based builds)
PKGDIR=$(COUCHDIR)

ifeq ($(shell arch),aarch64)
PKGARCH=arm64
else ifeq ($(shell arch),arm64v8)
PKGARCH=arm64
else
PKGARCH=$(shell arch)
endif

# Overridden for targets with SM60 in per-target env vars below.
SPIDERMONKEY=couch-libmozjs185-1.0
SPIDERMONKEY_DEV=couch-libmozjs185-dev
SM_VER=1.8.5


# Try and guess the correct target...
all:
	make `bin/detect-target.sh`

# Debian default
debian: sm-ver-debian find-couch-dist copy-debian update-changelog dpkg lintian copy-pkgs

# Debian 11 - bullseye
debian-bullseye: PLATFORM=bullseye
debian-bullseye: DIST=debian-bullseye
debian-bullseye: SPIDERMONKEY=libmozjs-78-0
debian-bullseye: SPIDERMONKEY_DEV=libmozjs-78-dev
debian-bullseye: SM_VER=78
debian-bullseye: bullseye

arm64-debian-bullseye: aarch64-debian-bullseye
arm64v8-debian-bullseye: aarch64-debian-bullseye
aarch64-debian-bullseye: PLATFORM=bullseye
aarch64-debian-bullseye: DIST=debian-bullseye
aarch64-debian-bullseye: SPIDERMONKEY=libmozjs-78-0
aarch64-debian-bullseye: SPIDERMONKEY_DEV=libmozjs-78-dev
aarch64-debian-bullseye: SM_VER=78
aarch64-debian-bullseye: bullseye

ppc64le-debian-bullseye: PLATFORM=bullseye
ppc64le-debian-bullseye: DIST=debian-bullseye
ppc64le-debian-bullseye: SPIDERMONKEY=libmozjs-78-0
ppc64le-debian-bullseye: SPIDERMONKEY_DEV=libmozjs-78-dev
ppc64le-debian-bullseye: SM_VER=78
ppc64le-debian-bullseye: bullseye

s390x-debian-bullseye: PLATFORM=bullseye
s390x-debian-bullseye: DIST=debian-bullseye
s390x-debian-bullseye: SPIDERMONKEY=libmozjs-78-0
s390x-debian-bullseye: SPIDERMONKEY_DEV=libmozjs-78-dev
s390x-debian-bullseye: SM_VER=78
s390x-debian-bullseye: bullseye


bullseye: debian

# Debian 12 - bookworm
debian-bookworm: PLATFORM=bookworm
debian-bookworm: DIST=debian-bookworm
debian-bookworm: SPIDERMONKEY=libmozjs-78-0
debian-bookworm: SPIDERMONKEY_DEV=libmozjs-78-dev
debian-bookworm: SM_VER=78
debian-bookworm: bookworm

arm64-debian-bookworm: aarch64-debian-bookworm
arm64v8-debian-bookworm: aarch64-debian-bookworm
aarch64-debian-bookworm: PLATFORM=bookworm
aarch64-debian-bookworm: DIST=debian-bookworm
aarch64-debian-bookworm: SPIDERMONKEY=libmozjs-78-0
aarch64-debian-bookworm: SPIDERMONKEY_DEV=libmozjs-78-dev
aarch64-debian-bookworm: SM_VER=78
aarch64-debian-bookworm: bookworm

ppc64le-debian-bookworm: PLATFORM=bookworm
ppc64le-debian-bookworm: DIST=debian-bookworm
ppc64le-debian-bookworm: SPIDERMONKEY=libmozjs-78-0
ppc64le-debian-bookworm: SPIDERMONKEY_DEV=libmozjs-78-dev
ppc64le-debian-bookworm: SM_VER=78
ppc64le-debian-bookworm: bookworm

s390x-debian-bookworm: PLATFORM=bookworm
s390x-debian-bookworm: DIST=debian-bookworm
s390x-debian-bookworm: SPIDERMONKEY=libmozjs-78-0
s390x-debian-bookworm: SPIDERMONKEY_DEV=libmozjs-78-dev
s390x-debian-bookworm: SM_VER=78
s390x-debian-bookworm: bookworm


bookworm: debian

# Ubuntu 22.04 (Jammy)
ubuntu-jammy: PLATFORM=jammy
ubuntu-jammy: DIST=ubuntu-jammy
ubuntu-jammy: SPIDERMONKEY=libmozjs-78-0
ubuntu-jammy: SPIDERMONKEY_DEV=libmozjs-78-dev
ubuntu-jammy: SM_VER=78
ubuntu-jammy: jammy
jammy: debian

s390x-ubuntu-jammy: ubuntu-jammy
arm64-ubuntu-jammy: ubuntu-jammy
aarch64-ubuntu-jammy: ubuntu-jammy
ppc64le-ubuntu-jammy: ubuntu-jammy

# Ubuntu 24.04 (Noble)
ubuntu-noble: PLATFORM=noble
ubuntu-noble: DIST=ubuntu-noble
ubuntu-noble: SPIDERMONKEY=libmozjs-115-0
ubuntu-noble: SPIDERMONKEY_DEV=libmozjs-115-dev
ubuntu-noble: SM_VER=115
ubuntu-noble: noble
noble: debian

s390x-ubuntu-noble: ubuntu-noble
arm64-ubuntu-noble: ubuntu-noble
aarch64-ubuntu-noble: ubuntu-noble
ppc64le-ubuntu-noble: ubuntu-noble

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

# Almalinux 8 is a CentOS 8 alias
almalinux-8: centos-8
almalinux-8.8: centos-8
almalinux-8.9: centos-8
almalinux-8.10: centos-8
aarch64-almalinux-8.10: PKGARCH=aarch64
aarch64-almalinux-8.10: centos-8
aarch64-almalinux-8: PKGARCH=aarch64
aarch64-almalinux-8: centos-8

# Almalinux 9 is a CentOS 9 alias
almalinux-9: centos-9
almalinux-9.2: centos-9
almalinux-9.4: centos-9
almalinux-9.5: centos-9
almalinux-9.6: centos-9
aarch64-almalinux-9.4: PKGARCH=aarch64
aarch64-almalinux-9.4: centos-9
aarch64-almalinux-9.5: PKGARCH=aarch64
aarch64-almalinux-9.5: centos-9
aarch64-almalinux-9.6: PKGARCH=aarch64
aarch64-almalinux-9.6: centos-9
aarch64-almalinux-9: PKGARCH=aarch64
aarch64-almalinux-9: centos-9
# s390x RHEL 8 clone based
s390x-centos-8: centos-8
ppc64le-centos-8: centos-8
# s390x RHEL 9 clone based
s390x-centos-9: centos-9

arm64-centos-9: PKGARCH=aarch64
arm64-centos-9: centos-9
ppc64le-centos-9: centos-9

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
	sed 's/%SPIDERMONKEY%/$(SPIDERMONKEY)/g;s/%SPIDERMONKEY_DEV%/$(SPIDERMONKEY_DEV)/g' \
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
	export HOME=$(HOME) && cd ../rpmbuild && rpmbuild --verbose -bb SPECS/couchdb.spec --define '_version $(VERSION)'

# ######################################
copy-pkgs:
	chmod a+rwx $(PKGDIR)/couchdb*
	mkdir -p pkgs/couch/$(DIST) && chmod 777 pkgs/couch/$(DIST)
	cp $(PKGDIR)/couchdb* pkgs/couch/$(DIST)

clean:
	if [ -f debian/control.bak ]; then mv -f debian/control.bak debian/control; fi
	if [ -f rpm/SPECS/couchdb.spec.bak ]; then mv -f rpm/SPECS/couchdb.spec.bak rpm/SPECS/couchdb.spec; fi
	rm -rf parts prime stage js/build debian/sm_ver.mk

# ######################################
couch-js-clean:
	rm -rf js/build ../rpmbuild

couch-js-debs: couch-js-clean
	mkdir js/build && cd js/build && tar xf ../src/js185-1.0.0.tar.gz --strip-components=1
	cp -r js/debian js/build
	if [ "$(shell arch)" = "armv7l" ]; then rm js/build/debian/*symbols; fi
	cd js/build && dch -v $(JS_VERSION)~$(PLATFORM) $(JS_DEBCHANGELOG)
	cd js/build && dpkg-buildpackage -b -us -uc

couch-js-rpms: couch-js-clean
	mkdir -p ../rpmbuild
	cp -R js/rpm/* ../rpmbuild
	cp js/src/js185-1.0.0.tar.gz ../rpmbuild/SOURCES
	cd ../rpmbuild && rpmbuild --verbose -bb SPECS/js.spec

couch-js-68-rpms: couch-js-clean
	mkdir -p ../rpmbuild
	cp -R js68/rpm/* ../rpmbuild
	cd ../rpmbuild/SOURCES && curl -O https://ftp.mozilla.org/pub/firefox/releases/68.12.0esr/source/firefox-68.12.0esr.source.tar.xz
	cd ../rpmbuild && rpmbuild --verbose -bb SPECS/js68.spec
