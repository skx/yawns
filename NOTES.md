
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

The search index is built using the script "`bin/build-search-index`", which uses the `Lucy::Simple` perl module.

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



Links
-----

Useful links, using the live-site as an example:

* Recent members
    * https://debian-administration.org/recent/users/10
* Recent comments
    * https://debian-administration.org/recent/comments
* Recently reported comments
    * https://debian-administration.org/recent/reported
* Recently reported weblog entries
    * https://debian-administration.org/recent/reported/weblogs



Comment Reporting
-----------------

Reporting comments decrements the score associated with that comment by one point.  If a comment hits zero then it will be hidden.

The feed of reporte-comments will show comments, and their scores.  To remove items from the feed:

     $ update comment set score=-1 WHERE score=0;

If you wish to suspend a user, via the command-line, run:

     $ ./bin/suspend-user --user=taxation --reason="<p>Spammer</p>" [--delete-weblogs]

The `--reason` you give will be visible upon the suspended users' profile page.



Cron Jobs
---------

A sample `crontab` file is provided beneath `etc/cron`, and is installed via the `fabfile.py` installation script I use.

In short:

* One job runs often to update the RSS feeds if a new article has been posted.
    * This is required because the CGI script might promote an article upon a single host, and the others wouldn't know about it.
* One job runs once per day to update the search index.
