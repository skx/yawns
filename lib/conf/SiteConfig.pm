#!/usr/bin/perl

=head1 NAME

conf::SiteConfig - Configuration file for Yawns.

=cut


package conf::SiteConfig;
require Exporter;
@ISA    = qw ( Exporter );
@EXPORT = qw ( get_conf );



=head2 get_conf

Return the configuration value for the specified key

NOTE: Each configuration key/value are included inline in this method,
which should be replaced by Config::IniFiles or similar.

=cut

sub get_conf
{

    my $requested = $_[0];

    $dbuser = 'yawns';    # database username
    $dbpass = 'yawns';    # database user password
    $dbname = 'yawns';    # database name

    #
    # name of database server, if not localhost.
    # This is also used for memcached.
    #
    $dbserv = 'db.vpn.internal';


    #
    # The session-cache to use.
    #
    # If you uncomment this line then memcached will be used
    # for storing sessions.  If not then the redis-server located
    # lower down will be used.
    #
    #    $session = "memcache://127.0.0.1:11211/";

    #
    # The pointer to redis.
    #
    $redis = "db.vpn.internal:6379";

    #
    # If you wish to log DBI performance and queries you can
    # do so by setting the following to 1.
    #
    $dbi_log = 0;

    #
    # number of articles to display on the front page
    #
    $headlines = 10;

    #
    # number of headlines to put in RDF file
    #
    $rdf_headlines = 10;

    #
    #  Name of the site as shown in the page footers.
    #
    $sitename = 'Debian Administration';

    #
    #  Used in the title of pages.
    #
    $site_title  = 'Debian Administration';
    $site_slogan = 'Debian GNU/Linux System Administration Resources';

    #
    #  Seperator for page title.
    #
    $separator = ' :: ';

    #
    #  Tag-line, displayed upon each page.
    #
    $site_desc = 'Tips for a Debian GNU/Linux System Administrator.';

    #
    #  Address to and from which mails are sent via comment notifications
    # or new article submissions.  Also displayed at the foot of every
    # page.
    #
    $site_email = 'webmaster@example.org';

    #
    # Mail of a non-human for automated mails.
    #
    $bounce_email = 'bounces@example.org';

    #
    # Submission sender mail
    #
    $submission_mail = 'submissions@example.org';

    #
    # Link used in various output pages, and in the emails.
    #
    $home_url = 'http://www.debian-administration.org';

    #
    # Link used for the planet installation, leave as "undef" if not used.
    #
    $planet_url = 'http://planet.debian-administration.org';

    #
    # Binary to use for sending email notifications.
    #
    $sendmail_path = '/usr/lib/sendmail -t';


    #
    #  Do we send events to a central location?
    #
    #  If we do then this will specify the endpoint to submit to, if this
    # is unset then no events will be sent.
    #
    #  NOTE:  The event-server is not contained within Yawns, instead
    # it must be installed from its own repository:
    #
    #    http://git.steve.org.uk/yawns/events
    #
    $event_endpoint = "udp://misc.debian-administration.org:4433";


    #
    #  This is inserted into the top of each output page
    #
    $metadata = <<END_OF_META;
<meta name="description" content="$site_desc" />
<meta name="keywords"  content="Debian System Administration News, Debian Sysadmin, Linux Administration, Linux Sysadmin, Sysadmin" />
<meta name="copyright" content="(c) 2004-2016 $sitename" />
<meta name="author"  content="$sitename" />
<meta name="robots" content="index,follow" />
<meta name="resource-type" content="document" />
<meta name="classification" content="Personal" />
<meta name="language" content="en" />
<link rel="icon" href="/favicon.ico"  />
<link rel="shortcut icon" href="/favicon.ico" />
<link rel="top"    title="home"    href="/"  />
<link rel="stylesheet" type="text/css" href="/css/view.css" media="screen" title="Site Layout" />
<link rel="search" title="Search" href="/about/search" />
<link rel="alternate" title="Debian Administration RSS" href="/articles.rdf" type="application/rdf+xml" />
<link rel="alternate" title="Atom" href="/atom.xml" type="application/atom+xml" />
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
END_OF_META

    #
    #  Comment-filtering options.
    #
    #  Set this to zero to disable the testing entirely.
    $blogspam_test = 1;

    #
    #  If enabled specify the HTTP/JSON end-point here
    #
    $blogspam_url = "http://test.blogspam.net:9999/";

    #
    #  Options to pass to the filtering.
    #
    $blogspam_options =
      "exclude=dnsrbl,exclude=sfs,exclude=wordcount,exclude=bayasian,exclude=rdns";

    #
    #  Stop-words.
    #  Any of these mentioned in a comment will result in the post being
    # aborted - and the IP being blacklisted.
    #
    $stop_words = '';

    #
    # These are used for anti-spam purposes on the signup page.
    #
    # Signup here - https://www.google.com/recaptcha/
    #
    # You'll need to add the public/private keys
    #
    $rc_pubkey = "xxx-xx";
    $rc_secret = "xxx-yy";


    #
    # Return the requested config variable
    #
    return ($$requested);
}


1;


=head1 AUTHOR

Steve Kemp

http://www.steve.org.uk/



=head1 LICENSE

Copyright (c) 2005-2016 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut
