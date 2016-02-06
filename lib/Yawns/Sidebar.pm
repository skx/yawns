# -*- cperl -*- #

=head1 NAME

Yawns::Sidebar - A module for retrieving the user's sidebar

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Sidebar;
    use strict;

    my $bar   = Yawns::Sidebar->new();

    my $menu  = $bar->getMenu();


=for example end


=head1 DESCRIPTION

This module contains code for retrieving the users' menu.

=cut


package Yawns::Sidebar;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.43 $' =~ m/Revision:\s*(\S+)/;


#
#  Standard modules which we require.
#
use strict;
use warnings;
use Digest::MD5 qw(md5_base64 md5_hex);
use HTML::Template;


#
#  Yawns modules which we use.
#
use Yawns::Adverts;
use Yawns::Articles;
use Yawns::Permissions;
use Yawns::Poll;
use Yawns::Polls;
use Yawns::Submissions;
use Yawns::User;
use Yawns::Weblogs;



=head2 new

  Create a new instance of this object.

=cut

sub new
{
    my ( $self, %supplied ) = (@_);

    my $class = ref($self) || $self;

    return bless {}, $class;
}


=head2 getMenu

  Return the menu bar, which has the weblogs, etc, upon it.

=cut

sub getMenu
{
    my ( $class, $session ) = (@_);

    #
    #  Get the current username, and see if we're anonymous.
    #
    my $username = $session->param("logged_in") || "Anonymous";

    my $anonymous = 0;
    $anonymous = 1 if ( $username =~ /^anonymous$/i );

    #
    #  Permission checking for sidebar display content
    #
    my $perms;
    $perms = Yawns::Permissions->new( username => $username )
      unless ($anonymous);

    #
    # Determine the default display options for the sidebar.
    #
    my $show_polls = conf::SiteConfig::get_conf('sidebar_polls');
    my $show_blogs = conf::SiteConfig::get_conf('sidebar_blogs');


    #
    #  Override sidebar sections based on user preferences.
    #
    if ( defined($username) && ( !( $username =~ /^anonymous$/i ) ) )
    {
        my $user = Yawns::User->new( username => $username );
        my $userprefs = $user->get();
        $show_polls = $userprefs->{ 'polls' };
        $show_blogs = $userprefs->{ 'blogs' };

    }

    #
    #  Data used when showing the polls.
    #
    my $poll_id            = '';
    my $poll_question      = '';
    my $poll_comment_count = 0;
    my $poll_total_votes   = 0;
    my $poll_answers       = ();

    if ($show_polls)
    {

        #
        #  If showing polls find the relevant information.
        #
        my $polls = Yawns::Polls->new();
        $poll_id = $polls->getCurrentPoll();

        #
        #  Only show the comment count, and poll answers if we
        # *actually* have a poll.
        #
        if ( $poll_id > 0 )
        {
            my $poll = Yawns::Poll->new( id => $poll_id );
            $poll_comment_count = $poll->commentCount();

            #
            #  Get the data from the relevant poll.
            #
            my $answers;
            ( $poll_question, $poll_total_votes, $answers, undef ) =
              $poll->get();

            #
            #  Build up the answers, and IDs for displaying in a tmpl_loop.
            #
            foreach (@$answers)
            {
                my @answer = @$_;

                push( @$poll_answers,
                      {  id       => $answer[2],
                         response => $answer[0] } );
            }
        }
    }

    #
    # read in the template file
    #
    my $sidebar = HTML::Template->new(
                           filename => "../templates/includes/sidebar.template",
                           global_vars => 1 );

    #
    # Setup the default parameters.
    #
    $sidebar->param( show_pollbooth => $show_polls,
                     show_blogs     => $show_blogs, );

    if ($show_polls)
    {
        if ($poll_id)
        {

            #
            # Fill in poll data.
            #
            $sidebar->param( poll_id            => $poll_id,
                             poll_comment_count => $poll_comment_count,
                             poll_question      => $poll_question,
                             poll_total_votes   => $poll_total_votes,
                             poll_answers       => $poll_answers
                           );

        }
        else
        {
            $sidebar->param(
                          poll_error => "The administrator should add a poll" );
        }
    }
    if ($show_blogs)
    {

        #
        # Fetch the blog data, only if it is supposed to be displayed.
        #
        my $weblogs        = Yawns::Weblogs->new();
        my $recent_weblogs = $weblogs->getRecent();

        if ($recent_weblogs)
        {
            $sidebar->param( recent_weblogs => $recent_weblogs );
        }

        #
        #  Show the planet link?
        #
        my $planet_url = conf::SiteConfig::get_conf("planet_url");
        if ( defined($planet_url) )
        {
            $sidebar->param( planet_url  => $planet_url,
                             planet_site => 1,
                             sitename => conf::SiteConfig::get_conf("sitename")
                           );
        }
    }


    #
    #  Should we show the different submissions?
    #
    if ( !$anonymous )
    {
        my $show_pending_adverts  = $perms->check( priv => "advert_admin" );
        my $show_pending_articles = $perms->check( priv => "article_admin" );
        my $show_pending_polls    = $perms->check( priv => "poll_admin" );

        #
        #  Show the submissions header?
        #
        my $show_pending_header = $show_pending_adverts ||
          $show_pending_articles ||
          $show_pending_polls;

        if ($show_pending_header)
        {
            $sidebar->param( show_pending_header => 1 );

            #
            #  Display advert count
            #
            if ($show_pending_adverts)
            {
                my $adverts              = Yawns::Adverts->new();
                my $pending_advert_count = $adverts->countPending();
                $sidebar->param( pending_advert_count => $pending_advert_count,
                                 show_pending_advert_count => 1 );

            }

            #
            #  Article + poll count.
            #
            my $submissions = Yawns::Submissions->new();

            if ($show_pending_articles)
            {
                my $pending_article_count = $submissions->articleCount();
                $sidebar->param(pending_article_count => $pending_article_count,
                                show_pending_article_count => 1 );
            }

            if ($show_pending_polls)
            {
                my $pending_poll_count = $submissions->pollCount();
                $sidebar->param( pending_poll_count      => $pending_poll_count,
                                 show_pending_poll_count => 1 );
            }
        }

        #
        #  Should we show more site-admin stuff?
        #
        my $show_recent_users = $perms->check( priv => "recent_users" );
        my $show_static_edit  = $perms->check( priv => "edit_about" );
        my $show_edit_users   = $perms->check( priv => "edit_user" );

        if ($show_recent_users)
        {
            $sidebar->param( show_recent_users => 1,
                             show_misc_header  => 1 );
        }
        if ($show_static_edit)
        {
            $sidebar->param( "show_static_edit" => 1,
                             show_misc_header   => 1 );
        }
        if ($show_edit_users)
        {
            $sidebar->param( "show_edit_users" => 1,
                             show_misc_header  => 1 );
        }
    }

    # generate the output
    return ( $sidebar->output );

}



1;



=head1 AUTHOR

Steve Kemp

http://www.steve.org.uk/



=head1 LICENSE

Copyright (c) 2005,2006 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut
