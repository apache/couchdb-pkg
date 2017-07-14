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
#

%define name couchdb
%define prefix /opt/%{name}

Summary:       RESTful document oriented database
License:       Apache License v2.0
Name:          %{name}
Version:       %{_version}
Release:       1%{?dist}
Source:        https://www.apache.org/dist/couchdb/source/${version}/apache-couchdb-%{version}.tar.gz
Source1:       %{name}.service
Source2:       %{name}.init
Source3:       10-filelog.ini
Source5:       %{name}.logrotate
Prefix:        %{prefix}
Group:         Applications/Databases
URL:           https://couchdb.apache.org/
Vendor:        The Apache Software Foundation
BuildArch:     x86_64
ExclusiveArch: x86_64
Exclusiveos:   linux
Packager:      CouchDB Developers <dev@couchdb.apache.org>

BuildRequires: esl-erlang = %{erlang_version}
BuildRequires: gcc
BuildRequires: git
BuildRequires: help2man
#BuildRequires: js-devel = 1:1.8.5
BuildRequires: libcurl-devel
BuildRequires: libicu-devel
BuildRequires: nodejs >= 6.10.1
BuildRequires: python >= 2.6
#BuildRequires: python-pip
#BuildRequires: python-sphinx >= 1.5.3
#BuildRequires: shunit2

Requires(pre): shadow-utils

Requires(post): curl
Requires(post): js = 1:1.8.5
Requires(post): libicu >= 4.2.1
Requires(post): procps
Requires(post): python-progressbar
Requires(post): python-requests

%if 0%{?fedora} || 0%{?rhel} >= 7
BuildRequires:		xfsprogs-devel
%{?systemd_requires}
BuildRequires:		systemd
%else
Requires(post):		chkconfig
Requires(preun):	chkconfig, initscripts
Requires(postun):	initscripts
%endif

%description
Apache CouchDB is a distributed, fault-tolerant and schema-free
document-oriented database accessible via a RESTful HTTP/JSON API. Among other
features, it provides robust, incremental replication with bi-directional
conflict detection and resolution, and is queryable and indexable using a
table-oriented view engine with JavaScript acting as the default view
definition language.
.
CouchDB is written in Erlang, but can be easily accessed from any environment
that provides means to make HTTP requests. There are a multitude of third-party
client libraries that make this even easier for a variety of programming
languages and environments.

# NOTE: Stripping binaries causes issues so we skip it.
%define __os_install_post %{nil}

%build
./configure -c
%{__make} release

%clean
%{__rm} -rf %{buildroot}

%pre
if ! /usr/bin/getent passwd couchdb > /dev/null; then /usr/sbin/adduser \
  --system --home /opt/couchdb --no-create-home \
  --shell /bin/bash --comment "CouchDB Administrator" \
  --user-group couchdb; fi

%install
%{__install} -d -m0755 %{buildroot}/opt
%{__cp} -r rel/couchdb %{buildroot}/opt
%{__install} -d -m0750 %{buildroot}/var/log/%{name}
%{__install} -d -m0750 %{buildroot}%{_sharedstatedir}/%{name}
%{__install} -Dp -m0644 %{SOURCE3} %{buildroot}/opt/%{name}/etc/default.d/10-filelog.ini
%{__install} -Dp -m0644 %{SOURCE5} %{buildroot}/etc/logrotate.d/%{name}
/bin/find %{buildroot}/opt/%{name} -name *.ini -exec %{__chmod} 0640 {} \;

%if 0%{?fedora} || 0%{?rhel} >= 7
%{__install} -Dp -m0644 %{SOURCE1} %{buildroot}%{_unitdir}/%{name}.service
%else
%{__install} -Dp -m0755 %{SOURCE2} %{buildroot}%{_initrddir}/%{name}
%endif

%post
%{__chown} -R couchdb:couchdb /opt/%{name}
%{__chmod} a+x /opt/%{name}/bin/*
%{__ln_s} %{_sharedstatedir}/%{name} /opt/%{name}/data
%{__ln_s} /var/log/%{name} /opt/%{name}/var/log/%{name}
%if 0%{?fedora} || 0%{?rhel} >= 7
%systemd_post %{name}.service
%else
/sbin/chkconfig --add %{name} || :
%endif

%preun
%if 0%{?fedora} || 0%{?rhel} >= 7
%systemd_preun %{name}.service
%else
# stop couchdb only when uninstalling
if [ $1 -eq 0 ]; then
  /sbin/service %{name} stop >/dev/null 2>&1 || :
  /sbin/chkconfig --del %{name} || :
fi
killall -u couchdb epmd
%endif

%postun
%if 0%{?fedora} || 0%{?rhel} >= 7
%systemd_postun_with_restart %{name}.service
%else
# restart couchdb only when upgrading
if [ $1 -eq 1 ]; then
  /sbin/service %{name} condrestart >/dev/null 2>&1 || :
fi
%endif

%files
%attr(0755, %{name}, %{name}) /opt/couchdb
%attr(0755, %{name}, %{name}) %dir %{_sharedstatedir}/%{name}
%attr(0755, %{name}, %{name}) %dir /var/log/%{name}
%config(noreplace) /opt/couchdb/etc/local.ini
%config /etc/logrotate.d/%{name}
%if 0%{?fedora} || 0%{?rhel} >= 7
%{_unitdir}/%{name}.service
%else
%{_initrddir}/%{name}
%endif


%changelog
* Tue May 2 2017 CouchDB Developers <dev@couchdb.apache.org> 2.0.0-1
- New upstream version
- New sysvinit and systemd service files
- New backported couchup script
