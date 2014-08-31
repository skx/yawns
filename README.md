
Yet Another Weblog/News System
==============================

YAWNS is a simple CMS which was originally writen by Denny De La Haye.

It was forked from that code by Steve Kemp, and updated considerably so that it could be used upon [his Debian-Administration website](http://www.debian-administration.org/).

The code stores articles, comments, weblogs, polls, and user-details ina simple MySQL database.


Installation
------------

Installation consists of several steps:

* Deploy the database.
    * Using the dump provided in `sql/`.
* Deploy the code.
    * This should just be a matter of using rsync, ftp, or similar.
* Configure Apache, etc.
    * There are several `mod_rewrite` rules present in `etc/apache/rewrite.rules.conf`.
* Creating your first user using your web-browser.
    * Then promote that user via `bin/make-admin`.

The Apache configuration can be copied from the sample located at `etc/apache/`.  There is also a HAProxy configuration file, but that shouldn't be required.



Live Usage
----------

The code is deployed upon five hosts which are configured like this:

* 1 x DB server
    * Runs MySQL, along with memcached for storing login-sessions.
* 4 x Web nodes.
    * Each node runs Apache to serve the application.
    * Each node also runs HAProxy to handle load-balancing and SSL termination.

Each of the four web-hosts has been configured with `ucarp`, such that one of them can claim a floating "master-IP".

The master-IP is the one that is published in DNS, and runs HAProxy on `:80` + `:443`.

HAProxy is used as a load-balancer/reverse-proxy which will attempt to proxy to each of the Apache instances on `:8080`.  In the sample configuration file you'll see that the back-ends run on private/internal IP addresses.  This is achieved via the `tinc` vpn software.  You'd probably just use their public IP addresses instead.

If a single backend fails, and it is not the master, the HAProxy instance will notice and stop sending traffic to it.  If the master host fails then another will take over and the same will occur.


Apache Setup
------------

Apache is configured to run on *:8080, handling only the single virtual host.  It runs on the high-port because HAProxy presents the front-end, and firewalling prevents that high port from being exposed generally.

The Apache server is configured to serve static-content beneath `htdocs/` and the CGI scripts that launch the site are located in `cgi-bin/`.  The CGI scripts run under FastCGI, for performance, and are invoked via pretty URLs via `mod_rewrite`, which is configured in `etc/apache`.


Steve
--
