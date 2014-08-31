#!/usr/bin/perl

use strict;
use warnings;

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
    # If this is set then we'll use memcached for login-sessions,
    # if this is set to zero instead we'll use MySQL for session-storage.
    #
    # See L<CGI::Session> for the required database table definition in
    # that case.
    #
    $memcached = 1;

    #
    # number of articles to display on the front page
    #
    $headlines     = 10;

    #
    # number of headlines in previous articles sidebox
    #
    $old_headlines = 10;

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
    #  Do we send alerts?
    #
    $alerts = 1;

    #
    #  This is inserted into the top of each output page
    #
    $metadata = <<END_OF_META;
<meta name="description" content="$site_desc" />
<meta name="keywords"  content="Debian System Administration News, Debian Sysadmin, Linux Administration, Linux Sysadmin, Sysadmin" />
<meta name="copyright" content="(c) 2004-2014 $sitename" />
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
    #  Should the sidebar show polls for anonymous users?
    #
    $sidebar_polls = 1;

    #
    #  Should the sidebar show previous article titles for anonymous users?
    #
    $sidebar_previous = 1;

    #
    #  Should the sidebar show blog entries for anonymous users?
    #
    $sidebar_blogs = 1;

    #
    #  Comment-filtering options.
    #
    #  Set this to zero to disable the testing entirely.
    $blogspam_test = 1;

    #
    #  If enabled specify the HTTP/JSON end-point here
    #
    $blogspam_url  = "http://test.blogspam.net:9999/";

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
    # Return the requested config variable
    #
    return ($$requested);
}


1;


=head1 AUTHOR

Steve Kemp

http://www.steve.org.uk/



=head1 LICENSE

Copyright (c) 2005-2014 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut

