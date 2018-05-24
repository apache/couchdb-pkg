# Why?

First, Ubuntu and Debian dropped libmozjs185 as a supported package.

Then, RedHat/Fedora/CentOS broke our shipped, working package  by redefining a header in a patch release incompatibly, forcing a rebuild.

So, we're just building and shipping our own couch-libmozjs185 / couch-js packages now.

While we're at it, we're going to make sure both platforms have both sets of patches, so behaviour is consistent across Linux distributions. We're also going to be sure that we use the configure options that we know work (specifically, we add `--disable-methodjit` as we have found this increases runtime stability.)

The hope is that [all of this goes away and is replaced by ChakraCore](https://github.com/apache/couchdb/issues/1334).

# External sources

## Debian / Ubuntu / etc

* http://snapshot.debian.org/package/mozjs/1.8.5-1.0.0%2Bdfsg-8/ (last version before being dropped)
  * and, specifically, http://snapshot.debian.org/archive/debian/20180330T054232Z/pool/main/m/mozjs/mozjs_1.8.5-1.0.0%2Bdfsg-8.debian.tar.xz

## RedHat / CentOS / Fedora / etc

* https://git.centos.org/summary/rpms!js.git
* https://bugs.centos.org/view.php?id=14720
  * https://fedoraproject.org/wiki/Changes/aarch64-48bitVA

## Other links we shouldn't lose track of

* https://issues.apache.org/jira/browse/COUCHDB-1572
  * https://bugzilla.mozilla.org/show_bug.cgi?id=589735
  * https://bugzilla.mozilla.org/show_bug.cgi?id=577056
