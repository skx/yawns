
Yet Another Weblog/News System
==============================

YAWNS is a simple CMS which was originally writen by Denny De La Haye.

It was forked from that code by Steve Kemp, and updated considerably
so that it could be used upon [his Debian-Administration website](http://www.debian-administration.org/).

The code stores articles, comments, weblogs, polls, and user-details in
a simple MySQL database.


Installation
------------

Installation consists of several steps:

* Deploy the database.
   * Using the dump provided in `sql/`.
* Deploy the code.
   * This should just be a matter of using rsync, ftp, or similar.
* Configure Apache, etc.
   * There are several `mod_rewrite` rules present.
* Creating your first user.
   * Using the interface you can create a new user.
   * Then promote that user via `bin/make-admin`.

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


