#!/usr/bin/perl -w -I../lib/ -I./lib/

=head1 NAME

index.cgi - Dispatch handler for yawns, route control to the appropriate code.

=cut

=head1 AUTHOR

 Steve
 --
 http://www.steve.org.uk/

 $Id: index.cgi,v 1.259 2007-10-22 21:02:12 steve Exp $

=cut

=head1 LICENSE

Copyright (c) 2001-2004 Denny De La Haye <denny@contentmanaged.org>
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


# standard perl modules
use CGI::Cookie;
use Sys::CpuLoad;

# YAWNS perl modules

use conf::SiteConfig;
require 'Pages.pl';


use HTML::AddNoFollow;
use Yawns::About;
use Yawns::Article;
use Yawns::Articles;
use Yawns::Bookmarks;
use Yawns::Comment;
use Yawns::Comments;
use Yawns::Event;
use Yawns::Permissions;
use Yawns::Poll;
use Yawns::Polls;
use Yawns::RSS;
use Yawns::Sidebar;
use Yawns::Scratchpad;
use Yawns::Stats;
use Yawns::User;
use Yawns::Users;
use Yawns::Weblog;
use Yawns::Weblogs;



#
#  Look for a blcklist
#
my $remote_ip = $ENV{ 'REMOTE_ADDR' };
if ( $remote_ip =~ /^::ffff:(.*)/ )
{
    $remote_ip = $1;
}
if ( -e "/etc/blacklist.d/$remote_ip" )
{
    print <<EOF;
Content-type: text/plain


You're banned from this server: $remote_ip
EOF
    exit;
}

#
#  Are we using HTTPS?
#
my $protocol = "http://";

if ( defined( $ENV{ 'HTTPS' } ) && ( $ENV{ 'HTTPS' } =~ /on/i ) )
{
    $protocol = "https://";
}


# ===========================================================================
# Make our initial database connection.
# ===========================================================================

my $db = Singleton::DBI->instance();

if ( !$db )
{
    print "Content-type: text/plain\n\n";
    print "Cannot connect to database.";
    exit;
}


# ===========================================================================
# Gain access to any submitted CGI parameters.
# ===========================================================================
my $form = Singleton::CGI->instance();


# ===========================================================================
# Setup the session object, only lasting a week.
# ===========================================================================
my $session = Singleton::Session->instance();
$session->expires("+1d");



# ===========================================================================
# The sessions will be handled by our clients as a cookie.  Expire it at the
# same time as our session actually epires.
# ===========================================================================
my $sessionCookie = $form->cookie( -name    => 'CGISESSID',
                                   -value   => $session->id,
                                   -expires => '+1d'
                                 );



# ===========================================================================
# Make sure our server isn't on fire.
# ===========================================================================
my @load = Sys::CpuLoad::load();
if ( $load[0] > 7 )
{
    print "Content-Type: text/html; charset=UTF-8\n\n";
    permission_denied( load_too_high => 1,
                       title         => "Server load too high" );
    $session->close();
    $db->disconnect();
    exit;
}



# ===========================================================================
#  OK a non-login/logout request.  If we're not logged in pretend we're the
# anonymous user.
# ===========================================================================
if ( !$session->param("logged_in") )
{
    $session->param( "logged_in", "Anonymous" );
}


# ===========================================================================
# Suspended users can only view their own page + logout.
# ===========================================================================
if ( defined( $session->param('suspended') ) )
{
    print "Content-type: text/html; charset=UTF-8\n\n";
    view_user();
    $session->close();
    $db->disconnect();
    exit;
}

# ===========================================================================
# Should we test to see that the session cookie is bound to the IP?
# ===========================================================================
my $ip = $session->param("session_ip");
if ( defined($ip) && ( length($ip) ) && ( $ip ne $ENV{ 'REMOTE_ADDR' } ) )
{
    print "Content-type: text/html; charset=UTF-8\n\n";
    permission_denied( session_ip_changed => 1,
                       session_ip         => $ENV{ 'REMOTE_ADDR' } );
    $session->param( "logged_in",    undef );
    $session->param( "session_ip",   undef );
    $session->param( "failed_login", undef );
    $session->close();
    $db->disconnect();
    exit;
}

#
#  If we've got SSL on, and it isn't in use then redirect.
#
if ( ( $session->param("ssl") ) &&
     ( $protocol ne "https://" ) )
{
    print $form->redirect(
                   "https://" . $ENV{ "SERVER_NAME" } . $ENV{ 'REQUEST_URI' } );
    $session->close();
    $db->disconnect();
    exit;
}


#
#  Used in some of the target dispatch handlers.
#
my $username = $session->param("logged_in");
my $anonymous = ( ( !$username ) || ( $username =~ /^anonymous$/i ) );


#
#  Permission checking object which we'll use to test access
# for various things.
#
my $perms = Yawns::Permissions->new( username => $username );

#
#  Before we output any headers, etc, we should make sure that the
# cookie is sent to the clients browser/user-agent.
#
print "Set-Cookie: $sessionCookie; HttpOnly\n" unless ($anonymous);



# ===========================================================================
#  Iterate over all the submitted form parameters, and sanitize them.
#  Unless the user has "raw_html" permissions.
# ===========================================================================
if ( !$perms->check( priv => "raw_html" ) )
{

    #
    #  We don't sanitizie "add weblog", or "add comment", since
    # these get their own sanitization added.
    #
    $form = HTML::AddNoFollow::sanitize($form)
      unless ( ( $form->param('add_weblog') ) ||
               ( $form->param('edit_weblog') ) ||
               ( $form->param('comment') ) )

}




# ===========================================================================
#  Dispatch hander.  Attempt to redirect control to the function which
# handles the request the user made.
#
#  The dispatch list has several possible keys:
#
#   1.  sub      - The code to call on a match.
#   2.  type     - The content type to specify when serving the page.
#   3.  redirect - An URI to redirect to once the routine has been called.
#   4.  login    - Should this function require a user-login?
#   5.  priv     - A permissions check to test access against.
#   6.  cache    - Should the cache be flushed once this is completed?
#
# ===========================================================================
my %dispatch = (

    #
    # start explicit ordering.
    #
    #  Since these two methods do their own sanitization they
    # are not filtered already - so we must make sure these
    # routines come first.
    #

    "dump" =>       # Dump details of a request.
      { sub  => \&dump_details,
        type => "Content-Type: text/plain\n\n",
      },

    "front_page" =>    # view the front-page
      { sub  => \&front_page,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
      },

    "new_user" =>      # Create a new user account
      { sub  => \&new_user,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
      },


    "submit" =>        # Submit an article
      { sub   => \&submit_article,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },

);


# ===========================================================================
#  Dispatch control to the appropriate handler.  Test authentication and
# permissions if we're supposed to.
# ===========================================================================
my $match = undef;

foreach my $key ( $form->param() )
{

    # we use the first match.
    next if ($match);

    #
    #  See if the parameter is in our dispatch table.
    #
    $match = $dispatch{ $key };
}


#
#  If we didn't get a match then we use "frontpage";
#
$match = $dispatch{ 'front_page' } if ( !$match );


#
#  Print the appropriate content type.
#
print $match->{ 'type' } if ( $match->{ 'type' } );

#
#  Do we need to be logged in?
#
if ( defined( $match->{ 'login' } ) )
{

    #
    #  If we requre a privilege then we also require
    # a login.
    #
    if ($anonymous)
    {

        #  If the handler didn't print a content type we should
        # send one before attempting to return the error message.
        #
        if ( !$match->{ 'type' } )
        {
            print "Content-type: text/html; charset=UTF-8\n\n";
        }

        #
        #  Not currently logged in so show an error.
        #
        permission_denied( login_required => 1 );
        $session->close();
        $db->disconnect();
        exit;
    }
}

#
#  Now we're logged in - but do we have the privilege?
#
my $required_priv = $match->{ 'priv' };

if ( $required_priv && ( !$perms->check( priv => $required_priv ) ) )
{

    #
    #  If the handler didn't print a content type we should
    # send one before attempting to return the error message.
    #
    if ( !$match->{ 'type' } )
    {
        print "Content-type: text/html; charset=UTF-8\n\n";
    }

    #
    #  We required a given permission, which isn't present.
    # Show error message.
    #
    #
    permission_denied( admin_only => 1 );
    $session->close();
    $db->disconnect();
    exit;
}

#
#  Now we can call the appropriate handler.
#
$match->{ 'sub' }->();

#
#  Should we redirect afterwards?  If so do it.
#
if ( $match->{ 'redirect' } )
{
    print $form->redirect(
                   $protocol . $ENV{ "SERVER_NAME" } . $match->{ 'redirect' } );
}

my $flush = $match->{ 'cache' } || 0;
if ( ($flush) && ( $ENV{ 'REQUEST_METHOD' } =~ /post/i ) )
{
    my $event = Yawns::Event->new();

    my $u =
      "<a href=\"http://www.debian-administration.org/users/$username\">$username</a>";
    $event->send(
         "Flushing cache due to POST to " . $ENV{ 'QUERY_STRING' } . " by $u" );

    my $cmd = "/root/current/bin/expire-varnish";
    system("$cmd >/dev/null 2>&1 &");
}



#
#  Now cleanup and exit since each incoming request will only
# do one thing.
#
$session->close();
$db->disconnect();
exit;

