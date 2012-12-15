
Yet Another Weblog/News System
==============================

YAWNS is a simple CMS which was originally writen by Danny.

It was forked from that code by Steve Kemp, and updated considerably
such that it could be used for the website :

* http://www.debian-administration.org/

The code is now undergoing more work such that I can re-deploy it upon
a modular architecture.


Overview
--------

The codebase stores articles, comments, weblogs, polls, and user-details in
a simple MySQL database.

The code makes use of several classes, in the `YAWNS::` namespace to interact
with these objects and presents the site interface.


Caching
-------

Lots of the SQL queries are suboptimal.  To counter this two layers of caching
were added:

* memcached caching of SQL queries/results
* static file caching of rendered articles

This is currently being removed and reworked to allow Varnish to be used instead.


Installation
------------

Installation is threefold:

* Deploy the database.
* Deploy the code.
* Configure Apache, etc.

The mysql configuration is simple.  The code assumes a Unix user called "yawns"
is present - all code will be installed beneath that users homedirectory.
There is a supplied "fabric" file which can be used to do that.

The Apache configuration can be copied from the included ~/apache/ file.
