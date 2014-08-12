#!/usr/bin/perl -w -I../lib/ -I./lib/

=head1 NAME

feeds.cgi - Backend routines for fetching dynamic RSS feeds of things.

=cut

=head1 AUTHOR

 Steve
 --
 http://www.steve.org.uk/

 $Id: feeds.cgi,v 1.9 2007-05-21 22:48:58 steve Exp $

=cut

=head1 LICENSE

Copyright (c) 2005-2006 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut



# Enforce good programming practices
use strict;
use warnings;

# UTF is the way of the future.
use utf8;
binmode STDOUT, ":utf8";

#
#  Singleton objects we create and use
#
use Singleton::DBI;
use Singleton::CGI;
use Singleton::Session;

#
# standard perl modules
#
use CGI::Cookie;

#
# Yawns modules we use.
#
use conf::SiteConfig;
require 'Pages.pl';
use HTML::AddNoFollow;



# ===========================================================================
# Make an initial database connection, to make the singleton live.
# ===========================================================================

my $db = Singleton::DBI->instance();

if ( !$db )
{
    print "Content-type: text/plain\n\n";
    print "Cannot connect to database.";
    exit;
}


# ===========================================================================
# Gain access to any parameters from URL and any submitted form.
# ===========================================================================
my $form = Singleton::CGI->instance();


# ===========================================================================
# Setup the session object for the code, only lasting a week.
# ===========================================================================
my $session = Singleton::Session->instance();
$session->expires("+7d");


# ===========================================================================
# The sessions will be handled by our clients as a cookie.  Expire it at the
# same time as our session actually epires.
# ===========================================================================
my $sessionCookie = $form->cookie( -name    => 'CGISESSID',
                                   -value   => $session->id,
                                   -expires => '+1d'
                                 );



#
#  Get the username of the current user, unless they are not logged in.
#
my $username = $session->param("logged_in") || "Anonymous";

#
#  Make sure our session cookie is always served.
#
print "Set-Cookie: $sessionCookie; HttpOnly\n";


# ===========================================================================
#  Iterate over all the submitted form parameters, and sanitize them.
#  We trust administrators, so they don't get scrubbed.
# ===========================================================================
my $perms = Yawns::Permissions->new( username => $username );
if ( !$perms->check( priv => "raw_html" ) )
{
    $form = HTML::AddNoFollow::sanitize($form);
}



#
#  Setup a dispatch table to control where we will handle
# the different incoming request types.
#
my %dispatch = (
               );



#
#  Examine the submitted parameters and dispatch control to the appropriate
# routine.
#
foreach my $key ( $form->param() )
{

    #
    #  See if the parameter is in our dispatch table.
    #
    my $match = $dispatch{ $key };

    #
    #  If it is we can use it.
    #
    if ($match)
    {

        #
        #  Print the appropriate content type.
        #
        #  TODO:  Maybe remove since they are all the same?
        #
        print $match->{ 'type' } if ( $match->{ 'type' } );

        #
        #  Now call the function.
        #
        $match->{ 'sub' }->();

        #
        #  Cleanup and exit since each incoming request will only
        # do one thing.
        #
        $session->close();
        $db->disconnect();
        exit;
    }
}



#
#  If we didn't get handled then we'll redirect to /about/404.
#
print $form->header(
                -type     => 'text/html',
                -cookie   => $sessionCookie,
                -location => => "http://" . $ENV{ "SERVER_NAME" } . "/about/404"
);


#
#  All done, clean up session and database then exit.
#
$session->close();
$db->disconnect();

exit;
