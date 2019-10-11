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

# Debian default
debian: find-couch-dist copy-debian update-changelog dpkg lintian copy-pkgs
debian-no-lintian: find-couch-dist copy-debian update-changelog dpkg copy-pkgs

# Debian 8
debian-jessie: PLATFORM=jessie
debian-jessie: DIST=debian-jessie
debian-jessie: jessie
jessie: debian

# Debian 9
debian-stretch: PLATFORM=stretch
debian-stretch: DIST=debian-stretch
debian-stretch: stretch
# AArch64 Debian 9
# Lintian doesn't install correctly into a cross-built Docker container ?!
arm64v8-debian-stretch: aarch64-debian-stretch
aarch64-debian-stretch: PLATFORM=stretch
aarch64-debian-stretch: DIST=debian-stretch
aarch64-debian-stretch: debian-no-lintian
ppc64le-debian-stretch: PLATFORM=stretch
ppc64le-debian-stretch: DIST=debian-stretch
ppc64le-debian-stretch: stretch
stretch: debian

# Debian 10
debian-buster: PLATFORM=buster
debian-buster: DIST=debian-buster
debian-buster: buster
# Lintian doesn't install correctly into a cross-built Docker container ?!
arm64v8-debian-buster: aarch64-debian-buster
aarch64-debian-buster: PLATFORM=buster
aarch64-debian-buster: DIST=debian-buster
aarch64-debian-buster: debian-no-lintian
buster: debian


# Ubuntu 12.04
ubuntu-precise: PLATFORM=precise
ubuntu-precise: DIST=ubuntu-precise
ubuntu-precise: precise
precise: find-couch-dist copy-debian precise-prep update-changelog dpkg copy-pkgs

precise-prep:
	sed -i '/dh-systemd/d' $(DISTDIR)/debian/control
	sed -i '/init-system-helpers/d' $(DISTDIR)/debian/control
	sed -i 's/ --with=systemd//' $(DISTDIR)/debian/rules

# Ubuntu 14.04
# Need to work around missing esl erlang-* pkgs for 1:18.3-1 :/
# No lintian run because of bogus failure on
# postrm-does-not-call-updaterc.d-for-init.d-script
# See Ubuntu ufw changelog for why they disabled this check
ubuntu-trusty: PLATFORM=trusty
ubuntu-trusty: DIST=ubuntu-trusty
ubuntu-trusty: trusty
trusty: find-couch-dist copy-debian trusty-prep update-changelog dpkg copy-pkgs

# see changelog for ubuntu ufw package, this is safe
trusty-prep:
	#sudo sed -i 's/conffile/conffile, postrm-does-not-call-updaterc.d-for-init.d-script/' /usr/share/lintian/profiles/couchdb/main.profile
	sed -i '/erlang-*/d' $(DISTDIR)/debian/control

# Ubuntu 16.04
ubuntu-xenial: PLATFORM=xenial
ubuntu-xenial: DIST=ubuntu-xenial
ubuntu-xenial: xenial
xenial: debian

# Ubuntu 18.04
ubuntu-bionic: PLATFORM=bionic
ubuntu-bionic: DIST=ubuntu-bionic
ubuntu-bionic: bionic
bionic: debian

# RPM default
centos: PKGDIR=../rpmbuild/RPMS/$(PKGARCH)
centos: find-couch-dist link-couch-dist build-rpm copy-pkgs

centos-6: DIST=centos-6
centos-6: centos6
centos6: make-rpmbuild centos

centos-7: DIST=centos-7
centos-7: centos7
centos7: make-rpmbuild centos

centos-8: DIST=centos-8
centos-8: centos8
centos8: make-rpmbuild centos

openSUSE: centos7

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

lintian:
	cd $(DISTDIR)/.. && lintian --profile couchdb couch*.deb

# ######################################
link-couch-dist:
	rm -rf ../rpmbuild/BUILD
	ln -s $(DISTDIR) ../rpmbuild/BUILD
	$(eval VERSION := $(shell echo $(VERSION) | sed 's/-/\./'))

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
	rm -rf parts prime stage js/build

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

