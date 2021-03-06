Source Repository:
    https://github.com/skx/yawns/

Mirror:
    http://git.steve.org.uk/yawns


Yet Another Weblog/News System
==============================

YAWNS is a simple CMS which was originally writen by Denny De La Haye.

It was forked from that code by Steve Kemp, and updated considerably so that it could be used upon [his Debian-Administration website](http://www.debian-administration.org/).

The code stores articles, comments, weblogs, polls, and user-details ina simple MySQL database, and is setup for easy clustering with no local-state.


Installation
------------

Installation consists of several steps:

* Deploy the database.
    * Using the table-structure provided in `sql/`.
* Deploy the code.
    * This should just be a matter of using rsync, FTP, or similar.
    * I deploy via [fabric](http://fabfile.org/) and the top-level `fabfile.py` shows how that is done.
* Configure Apache, etc.
    * There are several `mod_rewrite` rules present in `etc/apache/rewrite.rules.conf`.
* Creating your first user using your web-browser.
    * Then promote that user via `bin/make-admin` to gain all site-admin permissions.

The Apache configuration can be copied from the sample located at `etc/apache/`.  There is also a HAProxy configuration file, but that shouldn't be required.

There are some notes included in the file `NOTES.md` which should also be examined for configuration details.


Live Deployment
---------------

The code is deployed upon five hosts which are configured like this:

* 1 x DB server
    * Runs MySQL, along with memcached for storing login-sessions.
* 4 x Web nodes.
    * Each node runs Apache to serve the application, and static-resources.
    * Each node also runs HAProxy to handle load-balancing and SSL termination.

Each of the four web-hosts has been configured with `ucarp`, such that one of them can claim a floating "master-IP".

The master-IP is the one that is published in DNS, and runs HAProxy on `:80` + `:443`.

HAProxy is used as a load-balancer/reverse-proxy which will attempt to proxy to each of the Apache instances on `:8080`.  In the sample configuration file you'll see that the back-ends run on private/internal IP addresses.  This is achieved via the `tinc` vpn software.  You'd probably just use their public IP addresses instead.

If a single backend fails, and it is not the master, the HAProxy instance will notice and stop sending traffic to it.  If the master host fails then another will take over and the same will occur.


Apache Setup
------------

Apache is configured to run on `*:8080`, handling only the single virtual host.  It runs on the high-port because HAProxy presents the front-end, and firewalling prevents that high port from being exposed generally.

The Apache server is configured to serve static-content from beneath `htdocs/` and the CGI scripts that launch the site are located in `cgi-bin/`.  The CGI scripts run under FastCGI, for performance, and are invoked via pretty URLs via `mod_rewrite`, which is configured in `etc/apache`.

If you run things on only a single node then you can drop the idea of using `haproxy` as a reverse-proxy and just configure apache as vhost.  There's nothing else special involved.


History
-------

* Originally written by Denny.
* Updated by Steve to move code into modules, add test-cases, etc.
* Deployed on Debian Administration.
* Deployed on Police State UK.
* Updated by Steve to use [CGI::Application](http://search.cpan.org/perldoc?CGI%3A%3AApplication) framework.

Over time several things were added/removed, largely reolving around caching, these things still exist as historical artifacts in the repository history, but no longer in the live codebase.


Current status
--------------

* Things are functional, but we've not had a lot of testing in-anger of the new `CGI::Application`-based codebase.

TODO:

* Overhaul the test-cases, some of which are broken.
* Your issue here?


Steve
--

