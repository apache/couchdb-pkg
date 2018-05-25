# Why?

First, Ubuntu and Debian [dropped libmozjs185 as a supported package](https://tracker.debian.org/news/944342/removed-185-100dfsg-8-from-unstable/).

Then, RedHat/Fedora/CentOS [broke our shipped, working package](https://github.com/apache/couchdb/issues/1293) by [redefining a header in a patch release incompatibly, forcing a rebuild](https://bugs.centos.org/view.php?id=14720).

So, we're just building and shipping our own couch-libmozjs185 / couch-js packages now.

While we're at it, we're going to make sure both platforms have both sets of patches, so behaviour is consistent across Linux distributions. We're also going to be sure that we use the configure options that we know work (specifically, we add `--disable-methodjit` as we have found this increases runtime stability.)

The hope is that [all of this goes away and is replaced by ChakraCore](https://github.com/apache/couchdb/issues/1334).

# The great patchset merge

To keep things simpler to maintain, the exact same set of patches is used in building rpms and debs. (Symlinks aren't used, but could be. The contents of `js/rpm/SOURCES` and `js/debian/patches` are identical except for Debian's `series` file.) In general, the deb patches are of a higher quality, most of them originating from upstream.

With that in mind, the rpm patches as of js-1.8.5-20 (c7) were reviewed and handled thusly:

## Unique
* 0001-Make-js-config.h-multiarch-compatible.patch
  * supports co-installation of 32-bit and 64-bit packages (though we only build 64-bit ones)
* js185-libedit.patch
  * allows linking against libedit instead of readline
  * we don't --enable-readline anyway, but it's a nice to have
* mozjs1.8.5-tag.patch
  * the infamous 48 vs. 47 bit patch that started the entire process, and should fix aarch64 support
* ppc64le.patch
  * improves some of the ifdefs in Platform.h, adds explicit ppc64le support to configure.in
  * Makefile.in change needs backing out due to superior approach in debian's Bug-638056-Avoid-The-cacheFlush-support-is-missing-o.patch

## Superceded
* js-1.8.5-537701.patch
* js-1.8.5-64bit-big-endian.patch
  * these are replaced by debian:64bit-big-endian.patch
* bz1027492-aarch64.patch
* js-1.8.5-secondary-jit.patch
  * there is a much better approach in debian:Bug-638056-Avoid-The-cacheFlush-support-is-missing-o.patch
* js185-arm-nosoftfp.patch
  * Debian's patches come from upstream, this one is RHEL specific
  * debian: Bug-626035-Modify-the-way-arm-compiler-flags-are-set.patch
  * debian: autoconf.patch

## Duplicate
* js185-destdir.patch

# Testing

On rpm systems, use `yum localinstall path/to/file.rpm path/to/next.rpm` to install local rpm files.

On deb systems, use `apt install path/to/file.deb path/to/next.deb` to install local deb files.


# External references

## Debian / Ubuntu / etc

* http://snapshot.debian.org/package/mozjs/1.8.5-1.0.0%2Bdfsg-8/ (last version before being dropped)
  * and, specifically, http://snapshot.debian.org/archive/debian/20180330T054232Z/pool/main/m/mozjs/mozjs_1.8.5-1.0.0%2Bdfsg-8.debian.tar.xz
* https://www.debian.org/doc/manuals/maint-guide/

## RedHat / CentOS / Fedora / etc

* https://git.centos.org/summary/rpms!js.git
* https://bugs.centos.org/view.php?id=14720
  * https://fedoraproject.org/wiki/Changes/aarch64-48bitVA
* https://docs-old.fedoraproject.org/en-US/Fedora_Draft_Documentation/0.1/html/RPM_Guide/index.html

## Other links we shouldn't lose track of

* https://issues.apache.org/jira/browse/COUCHDB-1572
  * https://bugzilla.mozilla.org/show_bug.cgi?id=589735
  * https://bugzilla.mozilla.org/show_bug.cgi?id=577056
