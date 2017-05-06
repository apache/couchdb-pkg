#% global hgdate 51702867d932

Summary:		JavaScript interpreter and libraries
Name:		js
Version:		1.8.5
Release:		7%{?hgdate:.hg%{hgdate}}%{?dist}
License:		GPLv2+ or LGPLv2+ or MPLv1.1
Group:		Development/Languages
URL:			http://www.mozilla.org/js/
Source0:		http://ftp.mozilla.org/pub/mozilla.org/js/js185-1.0.0.tar.gz
Patch0:			js-1.8.5-64bit-big-endian.patch
Patch1:			js-1.8.5-secondary-jit.patch
Patch2:			js185-destdir.patch
Provides:		libjs = %{version}-%{release}
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root
Buildrequires:	python, zip
Buildrequires:	ncurses-devel, autoconf213
Epoch:		1


%description
JavaScript is the Netscape-developed object scripting language used in millions
of web pages and server applications worldwide. Netscape's JavaScript is a
superset of the ECMA-262 Edition 3 (ECMAScript) standard scripting language,
with only mild differences from the published standard.


%package devel
Summary: Header files, libraries and development documentation for %{name}
Group: Development/Libraries
Requires: %{name} = %{epoch}:%{version}-%{release}
Requires: pkgconfig
Requires: ncurses-devel readline-devel
Provides: libjs-devel = %{version}-%{release}

%description devel
This package contains the header files, static libraries and development
documentation for %{name}. If you like to develop programs using %{name},
you will need to install %{name}-devel.


%prep
# All patches come from old version and maintainer. I think it is Fedora related only
%setup -q -n %{name}-%{version}
%patch0 -p2 -b .64bit-big-endian
%patch1 -p2 -b .secondary-jit
%patch2 -p0 -b .destdir
cd js

# Rm parts with spurios licenses, binaries
# Some parts under BSD (but different suppliers): src/assembler
#rm -rf src/assembler src/yarr/yarr src/yarr/pcre src/yarr/wtf src/v8-dtoa
rm -rf src/ctypes/libffi src/t src/tests/src/jstests.jar src/tracevis src/v8

pushd src
autoconf-2.13
%configure \
    --with-system-nspr \
    --disable-tests \
    --disable-strip \
    --disable-ctypes

popd

# Create pkgconfig file
%{__cat} > libjs.pc << 'EOF'
prefix=%{_prefix}
exec_prefix=%{_prefix}
libdir=%{_libdir}
includedir=%{_includedir}

Name: libjs
Description: JS library
Requires: nspr >= 4.7
Version: %{version}
Libs: -L${libdir} -ljs
Cflags: -DXP_UNIX=1 -DJS_THREADSAFE=1 -I${includedir}/js
EOF


%build
cd js
%{__make} %{?_smp_mflags} -C src

%install
cd js
%{__make} -C src install DESTDIR=%{buildroot}
# We don't want this
%{__rm} -f %{buildroot}%{_bindir}/js-config
%{__install} -m 0755 src/jscpucfg src/shell/js %{buildroot}%{_bindir}/
#%{__rm} -rf %{buildroot}%{_libdir}/*.a
#%{__rm} -rf %{buildroot}%{_libdir}/*.la

%{__install} -m 0644 src/js*.h src/prmjtime.h src/js.msg src/*.tbl %{buildroot}%{_includedir}/

# For compatibility
pushd %{buildroot}%{_libdir}
%{__ln_s} libmozjs185.so.1.0 libmozjs.so.1 
%{__ln_s} libmozjs185.so.1.0 libjs.so.1 
%{__ln_s} libmozjs185.so libmozjs.so
%{__ln_s} libmozjs185.so libjs.so
popd

%{__install} -m 0644 libjs.pc %{buildroot}%{_libdir}/pkgconfig/

%clean
%{__rm} -rf %{buildroot}


%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig


%files
%defattr(-,root,root,-)
%doc js/src/README.html
%{_bindir}/js
%{_libdir}/*.so.*

%files devel
%defattr(-,root,root,-)
%{_bindir}/jscpucfg
%{_libdir}/pkgconfig/*.pc
%{_libdir}/*.so
%{_libdir}/*.a
%{_includedir}/js
%{_includedir}/js*.h
%{_includedir}/*.tbl
%{_includedir}/js.msg
%{_includedir}/prmjtime.h

%changelog
* Thu Jun 23 2011 Pavel Alexeev <Pahan@Hubbitus.info> - 1:1.8.5-7
- Make build system more proper (bz#710837), thanks to Jasper St. Pierre.
- Add missing header prmjtime.h (bz#709955), thanks to Jim Meyering.
- Merge Colin Walters build changes http://www.spinics.net/lists/fedora-devel/msg153214.html (1:1.8.5-6)

* Wed Jun 22 2011 Colin Walters <walters@verbum.org> - 1:1.8.5-6
- Include mozjs185.pc, clean up build
- Based on work from Christopher Aillon <caillon@redhat.com>
- Switch to using make install DESTDIR=, instead of hardcoding build rules.
- Add DESTDIR= patch from GNOME 3.2 jhbuild
- Make mozjs185 the canonical target for both libmozjs and libmozjs185.

* Fri May 27 2011 Dan Horák <dan[at]danny.cz> - 1.8.5-5
- add secondary arch patches from xulrunner

* Tue Apr 12 2011 Christopher Aillon <caillon@redhat.com> - 1.8.5-4
- devel subpackage needs to ask for the newly added epoch

* Tue Apr 12 2011 Pavel Alexeev <Pahan@Hubbitus.info> - 1.8.5-3
- Add Epoch: 1 to allow update of 1.70-13 version.

* Sat Apr 9 2011 Pavel Alexeev <Pahan@Hubbitus.info> - 1.8.5-2
- Correct symlink to provide backward capabiliies libjs.so.1

* Wed Apr 6 2011 Pavel Alexeev <Pahan@Hubbitus.info> - 1.8.5-1
- Update to release.
- Remove unneeded anymore patches.
- Add backward capability symlink.

* Sat Feb 12 2011 Pavel Alexeev <Pahan@Hubbitus.info> - 1.8.5-0.hg51702867d932
- Build version 1.8.5 by update request - BZ#676441 from Firefox 4.0 mercurial repository.
- Gone -DJS_C_STRINGS_ARE_UTF8
- Add BR autoconf213, change build system to use configure.
- Adopt patch0 (js-1.7.0-make.patch -> js-1.8.5-make.patch)
- Adopt patch1 (js-shlib.patch -> js-1.8.5-shlib.patch)
- Remove Patch2 (js-1.5-va_copy.patch) and Patch3 (js-ldflags.patch)
- Add BR python, zip.

* Wed Feb 09 2011 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.70-13
- Rebuilt for https://fedoraproject.org/wiki/Fedora_15_Mass_Rebuild

* Wed Jun 16 2010 Pavel Alexeev <Pahan@Hubbitus.info> - 1.70-12
- Add UTF-8 support (add -DJS_C_STRINGS_ARE_UTF8 ) by request Peter Halliday: BZ#576585

* Mon Jun 14 2010 Dan Horák <dan[at]danny.cz> - 1.70-11
- updated the va_copy patch for s390

* Mon Jan 25 2010 Pavel Alexeev <Pahan@Hubbitus.info> - 1.70-10
- Remove static library from -devel - %%{_libdir}/*.a (bz#556057) to meet guidelines.

* Sun Aug 2 2009 Pavel Alexeev <Pahan@Hubbitus.info> - 1.70-8
- Reformat spec with tabs.
- By report of Thomas Sondergaard (BZ#511162) Add -DXP_UNIX=1 -DJS_THREADSAFE=1 flags and nspr requires into libjs.pc

* Fri Jul 24 2009 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.70-7
- Rebuilt for https://fedoraproject.org/wiki/Fedora_12_Mass_Rebuild

* Fri May 29 2009 Dan Horak <dan[at]danny.cz> 1.70-6
- update the va_copy patch for s390x

* Thu Apr  9 2009 Matthias Saou <http://freshrpms.net/> 1.70-5
- Update description (#487903).

* Wed Feb 25 2009 Fedora Release Engineering <rel-eng@lists.fedoraproject.org>
- Rebuilt for https://fedoraproject.org/wiki/Fedora_11_Mass_Rebuild

* Wed Jun  4 2008 Jon McCann <jmccann@redhat.com> - 1.70-3
- Add two missing files (#449715)

* Wed Feb 27 2008 Tom "spot" Callaway <tcallawa@redhat.com> - 1.70-2
- Rebuild for perl 5.10 (again)

* Sun Feb  3 2008 Matthias Saou <http://freshrpms.net/> 1.70-1
- Update to 1.7.0, as 1.70 to avoid introducing an epoch for now...
- Remove no longer provided perlconnect parts.

* Thu Jan 24 2008 Tom "spot" Callaway <tcallawa@redhat.com> 1.60-6
- BR: perl(ExtUtils::Embed)

* Sun Jan 20 2008 Tom "spot" Callaway <tcallawa@redhat.com> 1.60-5
- rebuild for new perl

* Wed Aug 22 2007 Matthias Saou <http://freshrpms.net/> 1.60-4
- Rebuild for new BuildID feature.

* Mon Aug  6 2007 Matthias Saou <http://freshrpms.net/> 1.60-3
- Update License field.
- Add perl(ExtUtils::MakeMaker) build requirement to pull in perl-devel.

* Fri Feb  2 2007 Matthias Saou <http://freshrpms.net/> 1.60-2
- Include jsopcode.tbl and js.msg in devel (#235481).
- Install static lib mode 644 instead of 755.

* Fri Feb  2 2007 Matthias Saou <http://freshrpms.net/> 1.60-1
- Update to 1.60.
- Rebuild in order to link against ncurses instead of termcap (#226773).
- Add ncurses-devel build requirement and patch s/termcap/ncurses/ in.
- Change mode of perl library from 555 to 755 (#224603).

* Mon Aug 28 2006 Matthias Saou <http://freshrpms.net/> 1.5-6
- Fix pkgconfig file (#204232 & dupe #204236).

* Mon Jul 24 2006 Matthias Saou <http://freshrpms.net/> 1.5-5
- FC6 rebuild.
- Enable JS_THREADSAFE in the build (#199696), add patch and nspr build req.

* Mon Mar  6 2006 Matthias Saou <http://freshrpms.net/> 1.5-4
- FC5 rebuild.

* Thu Feb  9 2006 Matthias Saou <http://freshrpms.net/> 1.5-3
- Rebuild for new gcc/glibc.

* Mon Jan 30 2006 Matthias Saou <http://freshrpms.net/> 1.5-2
- Fix .pc file.

* Thu Jan 26 2006 Matthias Saou <http://freshrpms.net/> 1.5-1
- Update to 1.5.0 final.
- Spec file cleanups.
- Move docs from devel to main, since we need the license there.
- Remove no longer needed js-perlconnect.patch.
- Update js-1.5-va_copy.patch.
- Include a pkgconfig file (#178993).

* Tue Apr 19 2005 Ville Skyttä <ville.skytta at iki.fi> - 1.5-0.rc6a.6
- Link shared lib with libperl.

* Fri Apr  7 2005 Michael Schwendt <mschwendt[AT]users.sf.net>
- rebuilt

* Mon Feb 14 2005 David Woodhouse <dwmw2@infradead.org> - 1.5-0.rc6a.4
- Take js-va_copy.patch out of %%ifarch x86_64 so it fixes the PPC build too

* Sun Feb 13 2005 Thorsten Leemhuis <fedora at leemhuis dot info> - 1.5-0.rc6a.3
- Add js-va_copy.patch to fix x86_64; Patch was found in a Mandrake srpm

* Sat Dec 11 2004 Ville Skyttä <ville.skytta at iki.fi> - 1.5-0.rc6a.2
- Include perlconnect.
- Include readline support, rebuild using "--without readline" to disable.
- Add libjs* provides for upstream compatibility.
- Install header files in %%{_includedir} instead of %%{_includedir}/js.

* Tue Jun 15 2004 Matthias Saou <http://freshrpms.net> 1.5-0.rc6a
- Update to 1.5rc6a.

* Tue Mar 02 2004 Dag Wieers <dag@wieers.com> - 1.5-0.rc6
- Initial package. (using DAR)
