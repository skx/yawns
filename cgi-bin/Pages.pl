#!/usr/bin/perl -w -I../lib/ # -*- cperl -*- #

=head1 NAME

Pages.pl  - Page generator code for Yawns

=cut

=head1 DESCRIPTION

  The various subroutines in this file are used to generate the actual
 page outputs.

  Control reaches here via a dispatch table in one of the front-ends,
 ajax.cgi, feeds.cgi, or index.cgi.

=cut

=head1 AUTHOR

 (c) 2001-2004 Denny De La Haye <denny@contentmanaged.org>
 (c) 2004-2006 Steve Kemp <steve@steve.org.uk>

 Steve
 --
 http://www.steve.org.uk/

 $Id: Pages.pl,v 1.649 2007-11-03 15:55:20 steve Exp $

=cut

#
#  Standard modules which we require.
use strict;
use warnings;


# standard perl modules
use Digest::MD5 qw(md5_base64 md5_hex);
use HTML::Entities;
use HTML::Template;    # Template library for webpage generation
use Mail::Verify;      # Validate Email addresses.
use Text::Diff;

use HTML::Linkize;
use Yawns::Adverts;
use Yawns::Article;
use Yawns::Comment::Notifier;
use Yawns::Date;
use Yawns::Formatters;
use Yawns::Preferences;
use Yawns::Submissions;
use Yawns::User;




=begin doc

  A filter to allow dynamic page inclusions.

=end doc

=cut

sub mk_include_filter    #
{
    my $page = shift;
    return sub {
        my $text_ref = shift;
        $$text_ref =~ s/###/$page/g;
    };
}


=begin doc

  Load a layout and a page snippet with it.

=end doc

=cut

sub load_layout    #
{
    my ( $page, %options ) = (@_);

    #
    #  Make sure the snippet exists.
    #
    if ( -e "../templates/pages/$page" )
    {
        $page = "../templates/pages/$page";
    }
    else
    {
        die "Page not found: $page";
    }

    #
    #  Load our layout.
    #
    #
    #  TODO: Parametize:
    #
    my $layout = "../templates/layouts/default.template";
    my $l = HTML::Template->new( filename => $layout,
                                 %options,
                                 filter => mk_include_filter($page) );

    #
    #  IPv6 ?
    #
    if ( $ENV{ 'REMOTE_ADDR' } =~ /:/ )
    {
        $l->param( ipv6 => 1 ) unless ( $ENV{ 'REMOTE_ADDR' } =~ /^::ffff:/ );
    }

    #
    #  If we're supposed to setup a session token for a FORM element
    # then do so here.
    #
    my $setSession = 0;
    if ( $options{ 'session' } )
    {
        delete $options{ 'session' };
        $setSession = 1;
    }

    if ($setSession)
    {
        my $session = Singleton::Session->instance();
        $l->param( session => md5_hex( $session->id() ) );
    }

    #
    # Make sure the sidebar text is setup.
    #
    my $sidebar = Yawns::Sidebar->new();
    $l->param( sidebar_text   => $sidebar->getMenu() );
    $l->param( login_box_text => $sidebar->getLoginBox() );
    $l->param( site_title     => get_conf('site_title') );
    $l->param( metadata       => get_conf('metadata') );

    my $logged_in = 1;

    my $session  = Singleton::Session->instance();
    my $username = $session->param("logged_in");
    if ( $username =~ /^anonymous$/i )
    {
        $logged_in = 0;
    }
    $l->param( logged_in => $logged_in );

    return ($l);
}



# ===========================================================================
# CSRF protection.
# ===========================================================================
sub validateSession    #
{
    my $session = Singleton::Session->instance();

    #
    #  We cannot validate a session if we have no cookie.
    #
    my $username = $session->param("logged_in") || "Anonymous";
    return if ( !defined($username) || ( $username =~ /^anonymous$/i ) );

    my $form = Singleton::CGI->instance();

    # This is the session token we're expecting.
    my $wanted = md5_hex( $session->id() );

    # The session token we recieved.
    my $got = $form->param("session");

    if ( ( !defined($got) ) || ( $got ne $wanted ) )
    {
        permission_denied( invalid_session => 1 );

        # Close session.
        $session->close();

        # close database handle.
        my $db = Singleton::DBI->instance();
        $db->disconnect();
        exit;

    }
}




# ===========================================================================
# front page
# ===========================================================================

#
##
#
#  This function is a mess.
#
#  It must allow the user to step through the articles on the front-page
# either by section, or just globally.
#
##
#
sub front_page    #
{

    #
    #  Gain access to the objects we use.
    #
    my $form     = Singleton::CGI->instance();
    my $session  = Singleton::Session->instance();
    my $username = $session->param("logged_in");


    #
    # Gain access to the articles
    #
    my $articles = Yawns::Articles->new();

    #
    # Get the last article number.
    #
    my $last = $articles->count();
    $last += 1;

    #
    # How many do we show on the front page?
    #
    my $count = get_conf('headlines');

    #
    # Get the starting (maximum) number of the articles to view.
    #
    my $start = $last;
    $start = $form->param('start') if $form->param('start');
    if ( $start =~ /([0-9]+)/ )
    {
        $start = $1;
    }

    $start = $last if ( $start > $last );

    #
    # get required articles from database
    #
    my ( $the_articles, $last_id ) = $articles->getArticles( $start, $count );

    $last_id = 0 unless $last_id;


    #
    # Data for pagination
    #
    my $shownext  = 0;
    my $nextfrom  = 0;
    my $nextcount = 0;

    my $showprev  = 0;
    my $prevfrom  = 0;
    my $prevcount = 0;


    $nextfrom = $start + 10;
    if ( $nextfrom > $last ) {$nextfrom = $last;}

    $nextcount = 10;
    if ( $nextfrom + 10 > $last ) {$nextcount = $last - $start;}
    while ( $nextcount > 10 )
    {
        $nextcount -= 10;
    }

    $prevfrom = $last_id - 1;
    if ( $prevfrom < 0 ) {$prevfrom = 0;}

    $prevcount = 10;
    if ( $prevfrom - 10 < 0 ) {$prevcount = $start - 11;}

    if ( $start < $last )
    {
        $shownext = 1;
    }
    if ( $start > 10 )
    {
        $showprev = 1;
    }

    # read in the template file
    my $template = load_layout( "index.inc", loop_context_vars => 1 );


    # fill in all the parameters we got from the database
    if ($last_id)
    {
        $template->param( articles => $the_articles );
    }


    $template->param( shownext  => $shownext,
                      nextfrom  => $nextfrom,
                      nextcount => $nextcount,
                      showprev  => $showprev,
                      prevfrom  => $prevfrom,
                      prevcount => $prevcount,
                      content   => $last_id,
                    );

    #
    #  Add in the tips
    #
    my $weblogs     = Yawns::Weblogs->new();
    my $recent_tips = $weblogs->getTipEntries();
    $template->param( recent_tips => $recent_tips ) if ($recent_tips);


    # generate the output
    print $template->output;
}





# ===========================================================================
# Permission Denied - or other status message
# ===========================================================================
sub permission_denied    #
{
    my (%parameters) = (@_);

    # set up the HTML template
    my $template = load_layout("permission_denied.inc");

    # title
    my $title = $parameters{ 'title' } || "Permission Denied";
    $template->param( title => $title );

    #
    # If we got a custom option then set that up.
    #
    if ( scalar( keys(%parameters) ) )
    {
        $template->param(%parameters);
        $template->param( custom_error => 1 );
    }

    # generate the output
    print $template->output;
}


sub dump_details    #
{
    my $date = `date`;
    chomp($date);
    my $host = `hostname`;
    chomp($host);

    print "This request was received at $date on $host.\n\n";

    #
    #  Environment dump.
    #
    print "\n\n";
    print "Environment\n";
    foreach my $key ( sort keys %ENV )
    {
        print "$key\t\t\t$ENV{$key}\n";
    }

    print "\n\n";
    print "Submissions\n";
    my $form = Singleton::CGI->instance();

    foreach my $key ( $form->param() )
    {
        print $key . "\t\t\t" . $form->param($key);
        print "\n";
    }
}



1;



=head1 LICENSE

Copyright (c) 2005-2007 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut
