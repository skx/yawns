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
# Login attempt?  If setup the session if it succeeded.
# ===========================================================================
if ( $form->param('login') )
{

    #
    #  Username and Password from the login form.
    #
    my $lname  = $form->param('lname');
    my $lpass  = $form->param('lpass');
    my $secure = $form->param('secure');
    my $ssl    = $form->param('ssl');


    #
    # Login results.
    #
    my ( $logged_in, $suspended ) = undef;

    #
    # Do the login
    #
    my $user = Yawns::User->new();
    ( $logged_in, $suspended ) =
      $user->login( username => $lname,
                    password => $lpass );

    #
    #  If it worked
    #
    if ( ($logged_in) and ( !( lc($logged_in) eq lc('Anonymous') ) ) )
    {

        my $event = Yawns::Event->new();
        my $link  = $protocol . $ENV{ "SERVER_NAME" } . "/users/$logged_in";
        $event->send(
                 "Successful login for <a href=\"$link\">$logged_in</a> from " .
                   $ENV{ 'REMOTE_ADDR' } );

        #
        #  Setup the session variables.
        #
        $session->param( "logged_in",    $logged_in );
        $session->param( "failed_login", undef );
        $session->param( "suspended",    $suspended ) if $suspended;

        #
        #  If the user wanted a secure login bind their cookie to the
        # remote address.
        #
        if ( defined($secure) && ($secure) )
        {
            $session->param( "session_ip", $ENV{ 'REMOTE_ADDR' } );
        }
        else
        {
            $session->param( "session_ip", undef );
        }

        #
        #  If the user wanted SSL all the time then set it up
        #
        if ( defined($ssl) && ($ssl) )
        {
            $session->param( "ssl", 1 );

            #
            # and reset the cookie to only use ssl:
            #
            $sessionCookie =
              $form->cookie( -name    => 'CGISESSID',
                             -value   => $session->id,
                             -expires => '+1d',
                             -secure  => 1
                           );
        }
        else
        {
            $session->param( "ssl", undef );
        }

        #
        # Login succeeded.  If we have a redirection target:
        #
        # 1:  Close session.
        # 2:  Redirect + Set-Cookie
        # 3:  Exit.
        #
        my $target = $form->param("target");
        if ( defined($target) && ( $target =~ /^\// ) )
        {
            $session->close();
            $db->disconnect();
            print $form->header(
                        -type     => 'text/html',
                        -cookie   => $sessionCookie,
                        -location => $protocol . $ENV{ "SERVER_NAME" } . $target
            );
            exit;
        }
    }
    else
    {

        my $event = Yawns::Event->new();
        $lname = "_unknown_" if ( !defined($lname) );
        $event->send( "Failed login for $lname from " . $ENV{ 'REMOTE_ADDR' } );

        #
        # Login failed:  Invalid username or wrong password.
        #
        $session->param( "failed_login", 1 );
    }
}


# ===========================================================================
# Logout attempt?  If so delete the session settings.
# ===========================================================================
if ( defined $form->param('logout') )
{

    # make sure we've got a sessioin token.
    my $token  = $form->param("session");
    my $wanted = md5_hex( $session->id() );

    if ( $token ne $wanted )
    {
        print "Content-type: text/html; charset=UTF-8\n\n";
        permission_denied( invalid_session => 1,
                           title           => "Invalid session" );

        # Close session.
        $session->close();

        # close database handle.
        my $db = Singleton::DBI->instance();
        $db->disconnect();
        exit;
    }

    {
        my $cur   = $session->param("logged_in") || "Anonymous";
        my $link  = $protocol . $ENV{ "SERVER_NAME" } . "/users/$cur";
        my $event = Yawns::Event->new();
        $event->send("Logout for <a href=\"$link\">$cur</a>");
    }



    # delete the current session.
    $session->param( "logged_in",    undef );
    $session->param( "failed_login", undef );
    $session->param( "session_ip",   undef );
    $session->delete();

    my $logoutCookie = $form->cookie( -name    => 'CGISESSID',
                                      -value   => $session->id,
                                      -expires => '-1d'
                                    );

    #
    # Redirect to the server /, whilst making sure we don't setup the cookie.
    #
    print $form->redirect(
        -type   => 'text/html',
        -cookie => $logoutCookie,

        -location => "/"
                         );
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
    "comment" =>    # Submit a comment
      { sub   => \&submit_comment,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },

    "dump" =>       # Dump details of a request.
      { sub  => \&dump_details,
        type => "Content-Type: text/plain\n\n",
      },

    "add_weblog" =>    # Add a new weblog entry
      { sub   => \&add_weblog,
        login => 1,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },

    # end explicit ordering.
    "about" =>         # View a static page
      { sub  => \&view_about_section,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
      },

    "add_advert" =>    # Add an advert
      { sub   => \&add_new_advert,
        login => 1,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },

    "add_related" =>    # Add a related link to an article
      { sub   => \&add_related,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        priv  => "related_admin",
        cache => 1,
      },

    "add_submission_note" =>    # Add a note to a pending article
      { sub   => \&add_submission_note,
        priv  => "article_admin",
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },
    "adverts_byuser" =>         # View all adverts by a given user.
      { sub   => \&adverts_byuser,
        login => 1,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
      },

    "advert_stats" =>           # View the statistics of an advert
      { sub   => \&advert_stats,
        login => 1,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
      },

    "all_adverts" =>            # View all adverts
      { sub  => \&view_all_adverts,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
      },

    "archive" =>                # View previous submissions.
      { sub  => \&show_archive,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
      },

    "article" =>                # Read an article.
      { sub  => \&read_article,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
      },

    "author_search" =>          # Search for articles by the given user.
      { sub  => \&search_results,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
      },

    "bookmarks" =>              # View a users bookmark list.
      { sub  => \&view_bookmarks,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
      },

    "delete_advert" =>          # Remove an existing advert
      { sub   => \&delete_advert,
        priv  => "advert_admin",
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },

    "delete_bookmark" =>        # Remove an existing bookmark.
      { sub      => \&bookmark_delete,
        login    => 1,
        redirect => "/users/$username/bookmarks",
        cache    => 1,
      },

    "delete_related" =>         # Remove a related link from an article
      { sub   => \&delete_related,
        priv  => "related_admin",
        cache => 1,
      },

    "delete_weblog" =>          # Delete a weblog entry
      { sub   => \&delete_weblog,
        login => 1,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },

    "disable_advert" =>         # Disable an advert
      { sub   => \&disable_advert,
        priv  => "advert_admin",
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },

    "edit_about" =>             # Edit a static page
      { sub   => \&edit_about,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        priv  => "edit_about",
        cache => 1,
      },

    "edit_adverts" =>           # Edit a site advert
      { sub   => \&edit_adverts,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        priv  => "advert_admin",
        cache => 1,
      },

    "edit_article" =>           # Edit an existing, live, advert.
      { sub   => \&edit_article,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },

    "edit_comment" =>           # Edit a comment
      { sub   => \&edit_comment,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        priv  => "edit_comments",
        cache => 1,
      },

    "edit_user" =>              # Edit a user.
      { sub   => \&edit_user,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },

    "edit_permissions" =>       # Edit the permissions associated with a user.
      { sub   => \&edit_permissions,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },

    "edit_prefs" =>             # Edit a users preferences
      { sub   => \&edit_prefs,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },

    "edit_scratchpad" =>        # Edit a users scratchpad
      { sub   => \&edit_scratchpad,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },

    "edit_weblog" =>            # Edit a weblog entry
      { sub   => \&edit_weblog,
        login => 1,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },

    "enable_advert" =>          # Enable an advert
      { sub   => \&enable_advert,
        priv  => "advert_admin",
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },

    "front_page" =>             # view the front-page
      { sub  => \&front_page,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
      },

    "follow_advert" =>          # Click on a user-advert
      { sub => \&follow_advert, },

    "loginform" =>              # Login options
      { sub  => \&login_form,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
      },

    "new_user" =>               # Create a new user account
      { sub  => \&new_user,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
      },

    "send_reset_password" =>    # Mail the user a link to reset their password.
      { sub  => \&send_reset_password,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
      },

    "change_password" =>        # Allow a user to change their password.
      { sub  => \&change_password,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
      },

    "pollvote" =>               # Vote in a poll.
      { sub   => \&pollvote,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },

    "poll" =>                   # View a poll.
      { sub  => sub {poll_results( 0, 0, 0 );},
        type => "Content-Type: text/html; charset=UTF-8\n\n",
      },

    "poll_edit" =>              # Edit a pending poll submissions
      { sub   => \&poll_edit,
        priv  => "poll_admin",
        type  => "Content-type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },

    "poll_list" =>              # View archive of old polls
      { sub  => \&poll_list,
        type => "Content-type: text/html; charset=UTF-8\n\n",
      },

    "poll_post" =>              # Post a pending poll submissions
      { sub      => \&poll_post,
        priv     => "poll_admin",
        redirect => "/submissions/polls",
        cache    => 1,
      },

    "poll_reject" =>            # Reject pending poll submissions
      { sub      => \&poll_reject,
        priv     => "poll_admin",
        redirect => "/submissions/polls",
        cache    => 1,
      },

    "poll_submissions" =>       # View pending poll submissions
      { sub   => \&poll_submissions,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        priv  => "poll_admin",
        cache => 1,
      },

    "printable" =>              # Display the printable version of an article
      { sub => \&printable, },

    "recent_users" =>           # See recently joined users.
      { sub  => \&recent_users,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
        priv => "recent_users",
      },

    "report" =>                 # Report an abusive comment.
      { sub   => \&report_comment,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },

    "report_weblog" =>          # Report a weblog entry.
      { sub   => \&report_weblog,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },

    "scratchpad" =>             # View a users scratchpad area.
      { sub  => \&view_scratchpad,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
      },

    "search_articles" =>                 # Search articles
      { sub   => \&search_articles,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
      },

    "single_weblog" =>          # View a single weblog entry.
      { sub  => \&view_single_weblog,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
      },

    "stats" =>                  # View our hall of fame page.
      { sub  => \&stats_page,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
      },

    "submission_edit" =>        # Edit a pending article
      { sub   => \&edit_submission,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },

    "submission_view" =>        # View a pending article
      { sub  => \&submission_view,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
      },

    "submission_list" =>        # View pending article submissions
      { sub  => \&submission_list,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
        priv => "article_admin",
      },

    "submission_post" =>        # Post a pending article to the site.
      { sub   => \&submission_post,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        priv  => "article_admin",
        cache => 1,
      },

    "submission_reject" =>      # Reject a pending article submissions
      { sub   => \&submission_reject,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        priv  => "article_admin",
        cache => 1,
      },

    "submit" =>                 # Submit an article
      { sub   => \&submit_article,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },

    "submit_poll" =>            # Submit a new poll
      { sub   => \&submit_poll,
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },

    "tag_browse" =>             # See the tag field
      { sub  => \&tag_browse,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
      },

    "tag_search" =>             # Perform a search by tag
      { sub  => \&tag_search,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
      },


    "title" => { sub  => \&article_by_title,
               },
    "title_print" => { sub => \&article_by_title_print, },

    "user" =>                   # View a users profile page.
      { sub  => \&view_user,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
      },

    "user_admin" =>             # User administration.
      { sub   => \&user_administration,
        priv  => "user_admin",
        type  => "Content-Type: text/html; charset=UTF-8\n\n",
        cache => 1,
      },

    "weblog" =>                 # View a users weblog.
      { sub  => \&view_user_weblog,
        type => "Content-Type: text/html; charset=UTF-8\n\n",
      }


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

    my $u = "<a href=\"http://www.debian-administration.org/users/$username\">$username</a>";
    $event->send("Flushing cache due to POST to " . $ENV{'QUERY_STRING'} . " by $u" );

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

