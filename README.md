
Yet Another Weblog/News System
==============================

YAWNS is a simple CMS which was originally writen by Danny.

It was forked from that code by Steve Kemp, and updated considerably
such that it could be used for [his Debian-Administration website](http://www.debian-administration.org/).

The code has undergone further work, and is now deployed as a cluster.

This re-development means that there are slightly more assumptions made
about the operating environment than in the past.  That said it is still
a bug if this cannot be installed by a perl-aware sysadmin, or developer.


Overview
--------

The codebase stores articles, comments, weblogs, polls, and user-details in
a simple MySQL database.

The code makes use of several classes in the `YAWNS::` namespace to interact
with these objects and presents the site interface.


Installation
------------

Installation is threefold:

* Deploy the database.
* Deploy the code.
* Configure Apache, etc.

The mysql configuration is simple.

The code assumes a Unix user called "yawns" is present - all code will be
installed beneath that users home-directory, specifically the code
**must** be installed in ~/current/.  This is because the path used to
generate RSS feeds, etc, assumes this prefix.

The sample "fabric" script demonstrates how this is done, via the GitHub
repository.

The Apache configuration can be copied from the included ~/apache/ file.



Live Usage
----------

The code is deployed upon five hosts:

* da-db1.vm
    MySQL running for storage.
    MemCached for caching.

* da-web1.vm
* da-web2.vm
* da-web3.vm
* da-web4.vm
    * pound
    * varnish
    * apache
    * Each host has a been configured with ucarp so that they can potentially own the master IP.

The master IP runs pound on port 80, which routes traffic to varnish on each host, listening on :8000, which passes traffic to Apache on localhost:8080.

All data is stored in MySQL *except* login sessions.  Login sessions go to memcached, which is on the same host as MySQL for reference.


This means the hosts run the following services:

* db-db1.dh - MySQL, memcache
* db-web1.dh - ucarp, varnish, pound, apache
* db-web2.dh - ucarp, varnish, pound, apache
* db-web3.dh - ucarp, varnish, pound, apache
* db-web4.dh - ucarp, varnish, pound, apache


Because only one host is the "master" at any given time the actual deployment is more like this:

* db-web1.dh - ucarp, memcache, varnish, pound, apache
* db-web2.dh - ucarp, apache
* db-web3.dh - ucarp, apache
* db-web4.dh - ucarp, apache

The use of ucarp ensures that the site is functional if only a single host is alive.


Apache Setup
------------

There are three FastCGI scripts beneath `/cgi-bin/` which should be configured to be
executable.  These are invoked via the pretty URLs which you can see listed in
`apache/rewrite.rules.conf`.


