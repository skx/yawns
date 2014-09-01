
Notes
-----

Some parts of the deployment/code need a little explanation.



Configuration File
------------------

The application(s) are configured via the configuration file located at:

* `lib/conf/SiteConfig.pm`

Most of the defaults will be fine as-is, but some control functionality you might want to tweak.

Most notably the MySQL databaase, and session-setup are controlled via this configuration file.





Search Setup
------------

The search index is built using the script "`bin/build-search-index`", which uses the `Lucy::Simple` perl module.   You will need to add that to cron.

`liblucy-perl` is present in Debian from Jessie onwards, for Wheezy you will need to either install from CPAN, or via my personal [apt-get repository](http://packages.steve.org.uk/lucy/).



Events
------

Some parts of the code use the `Yawns/Event` module to send "event notices".

In brief there is a server listening for UDP submissions, on a remote host, which will bundle up received messages into a simple dashboard.

The dashboard may be viewed here:

* http://misc.debian-administration.org/events/

This behaviour is disabled by setting `alerts = 0` in the configuration file.

You can see the server-side code to this system at the following location:

* http://git.steve.org.uk/yawns/events

