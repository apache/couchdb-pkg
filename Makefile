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
ERLANG_VERSION=18.3

export DEBFULLNAME="CouchDB Developers"
export DEBEMAIL="dev@couchdb.apache.org"

# Debian default
debian: find-couch-dist copy-debian update-changelog dpkg lintian

# Debian 8
jessie: debian

# Ubuntu 12.04
precise: find-couch-dist copy-debian precise-prep dpkg lintian

precise-prep:
	sed -i '/dh-systemd/d' $(DISTDIR)/debian/control
	sed -i '/init-system-helpers/d' $(DISTDIR)/debian/control
	sed -i 's/ --with=systemd//' $(DISTDIR)/debian/rules

# Ubuntu 14.04
# Need to work around missing esl erlang-* pkgs for 1:18.3-1 :/
# No lintian run because of bogus failure on
# postrm-does-not-call-updaterc.d-for-init.d-script
# See Ubuntu ufw changelog for why they disabled this check
trusty: find-couch-dist copy-debian trusty-prep update-changelog dpkg

# see changelog for ubuntu ufw package, this is safe
trusty-prep:
	#sudo sed -i 's/conffile/conffile, postrm-does-not-call-updaterc.d-for-init.d-script/' /usr/share/lintian/profiles/couchdb/main.profile
	sed -i '/erlang-*/d' $(DISTDIR)/debian/control

# Ubuntu 16.04
xenial: debian

# RPM default
centos: find-couch-dist link-couch-dist build-rpm

centos6: make-rpmbuild centos

centos7: make-rpmbuild centos rm-js185-rpms

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
	cd $(DISTDIR)/.. && lintian --profile couchdb couch*deb

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
	export HOME=$(HOME) && cd ../rpmbuild && rpmbuild --verbose -bb SPECS/couchdb.spec --define "erlang_version $(ERLANG_VERSION)" --define '_version $(VERSION)'

# ######################################
make-js185:
	spectool -g -R rpm/SPECS/js-1.8.5.spec
	cd ../rpmbuild && rpmbuild --verbose -bb SPECS/js-1.8.5.spec

install-js185:
	sudo rpm -i ../rpmbuild/RPMS/x86_64/js-1*
	sudo rpm -i ../rpmbuild/RPMS/x86_64/js-devel*

rm-js185-rpms:
	rm -f ../rpmbuild/RPMS/x86_64/js*

# ######################################
copy-pkgs:
	mkdir -p pkgs/$(PLATFORM)
	-cp ../rpmbuild/RPMS/x86_64/*.rpm pkgs/$(PLATFORM)
	-cp ../couchdb/*deb pkgs/$(PLATFORM)
	-chmod -R a+rwx pkgs/$(PLATFORM)
