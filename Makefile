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

# Debian default
debian: find-couch-dist copy-debian update-changelog dpkg lintian

# Debian 8
debian-jessie: jessie
jessie: debian

# Debian 9
debian-stretch: stretch
stretch: debian

# Ubuntu 12.04
ubuntu-precise: precise
precise: find-couch-dist copy-debian precise-prep update-changelog dpkg

precise-prep:
	sed -i '/dh-systemd/d' $(DISTDIR)/debian/control
	sed -i '/init-system-helpers/d' $(DISTDIR)/debian/control
	sed -i 's/ --with=systemd//' $(DISTDIR)/debian/rules

# Ubuntu 14.04
# Need to work around missing esl erlang-* pkgs for 1:18.3-1 :/
# No lintian run because of bogus failure on
# postrm-does-not-call-updaterc.d-for-init.d-script
# See Ubuntu ufw changelog for why they disabled this check
ubuntu-trusty: trusty
trusty: find-couch-dist copy-debian trusty-prep update-changelog dpkg

# see changelog for ubuntu ufw package, this is safe
trusty-prep:
	#sudo sed -i 's/conffile/conffile, postrm-does-not-call-updaterc.d-for-init.d-script/' /usr/share/lintian/profiles/couchdb/main.profile
	sed -i '/erlang-*/d' $(DISTDIR)/debian/control

# Ubuntu 16.04
ubuntu-xenial: xenial
xenial: debian

# Ubuntu 18.04
ubuntu-bionic: bionic
bionic: debian

# RPM default
centos: find-couch-dist link-couch-dist build-rpm

centos-6: centos6
centos6: make-rpmbuild centos

centos-7: centos7
centos7: make-rpmbuild centos

# Erlang is built from source on ARMv8
# These packages are not installed, but the files are present
drop-deb-deps-for-source-arch:
	if [ "$(shell arch)" = "aarch64" ]; then                          \
		sed -i '/erlang-dev/d' $(DISTDIR)/debian/control;         \
		sed -i '/erlang-crypto/d' $(DISTDIR)/debian/control;      \
		sed -i '/erlang-dialyzer/d' $(DISTDIR)/debian/control;    \
		sed -i '/erlang-eunit/d' $(DISTDIR)/debian/control;       \
		sed -i '/erlang-inets/d' $(DISTDIR)/debian/control;       \
		sed -i '/erlang-xmerl/d' $(DISTDIR)/debian/control;       \
		sed -i '/erlang-os-mon/d' $(DISTDIR)/debian/control;      \
		sed -i '/erlang-reltool/d' $(DISTDIR)/debian/control;     \
		sed -i '/erlang-syntax-tools/d' $(DISTDIR)/debian/control;\
	fi

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

update-changelog: drop-deb-deps-for-source-arch
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
	mkdir -p pkgs/$(PLATFORM)
	-cp ../rpmbuild/RPMS/x86_64/*.rpm pkgs/$(PLATFORM)
	-cp ../couchdb/*deb pkgs/$(PLATFORM)
	-chmod -R a+rwx pkgs/$(PLATFORM)

clean:
	rm -rf couchdb_2.0_amd64.snap parts prime snap/.snapcraft stage js/build

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

