#
# This is a CGI::Application class which is designed to handle
# our RSS-feeds.
#
#
# Links
# -----
#
#    /recent/comments/$user Show the comments by user $user
#    /recent/comments/N     Show the N most recent comments
#    /recent/comments       Show the 10 most recent comments
#
#    /submission/feed       Show the submitted/pending articles
#
#    /weblog/feeds/$user    Show the blog posts by user $user
#
#    /tag/feeds/$tag        Show things matching the given tag.
#


use strict;
use warnings;


#
# Hierarchy.
#
package Application::Feeds;
use base 'CGI::Application';


#
# Standard module(s)
#
use CGI::Session;
use HTML::Template;
use URI::Find;

#
# Our code
#
use conf::SiteConfig;
use Yawns::Comments;
use Yawns::Submissions;




=begin doc

Create our session, and connect to redis.

=end doc

=cut

sub cgiapp_init
{
    my $self = shift;
    my $form = $self->query();

    #
    #  Create a new session.
    #
    my $session = Singleton::Session->instance();
    $session->expires("+7d");

    #
    #  Get the cookie to send.
    #
    my $sessionCookie = $form->cookie( -name    => 'CGISESSID',
                                       -value   => $session->id,
                                       -expires => '+1d'
                                     );


    #
    # assign the session object to a param
    #
    $self->param( session => $session );

    # send a cookie if needed
    $self->header_props( -cookie => $sessionCookie );

    binmode STDIN,  ":encoding(utf8)";
    binmode STDOUT, ":encoding(utf8)";

}

=begin doc

Cleanup our session and close our redis connection.

=end doc

=cut

sub teardown
{
    my ($self) = shift;

    #
    #  Flush the sesions
    #
    my $session = $self->param('session');
    $session->flush() if ( defined($session) );

}



=begin doc

Redirect to the given URL.

=end doc

=cut

sub redirectURL
{
    my ( $self, $url ) = (@_);

    #
    #  Cookie name & expiry
    #
    my $cookie_name   = 'CGISESSID';
    my $cookie_expiry = '+7d';

    #
    #  Get the session identifier
    #
    my $query   = $self->query();
    my $session = $self->param('session');

    my $id = "";
    $id = $session->id() if ($session);

    #
    #  Create/Get the cookie
    #
    my $cookie = $query->cookie( -name    => $cookie_name,
                                 -value   => $id,
                                 -expires => $cookie_expiry,
                               );

    $self->header_add( -location => $url,
                       -status   => "302",
                       -cookie   => $cookie
                     );
    $self->header_type('redirect');
    return "";

}


=begin doc

Called when an unknown mode is encountered.

=end doc

=cut

sub unknown_mode
{
    my ( $self, $requested ) = (@_);

    $requested =~ s/<>/_/g;

    return ("mode not found $requested");
}




=begin doc

Setup our run-mode mappings, and the defaults for the application.

=end doc

=cut

sub setup
{
    my $self = shift;

    $self->run_modes(

        # Recent comments
        'recent_comments' => 'recent_comments',

        # Feed of the given user.
        'user_feed' => 'user_feed',

        # Weblog feed for a given user.
        'weblog_feed' => 'weblog_feed',

        # Articles matching the given tag
        'tag_feed' => 'tag_feed',

        # Pending submissions
        'pending_submissions' => 'pending_submissions',

        # Debug Handler
        'debug' => 'debug_handler',

        # called on unknown mode.
        'AUTOLOAD' => 'unknown_mode',
    );

    #
    #  Start mode + mode name
    #
    $self->header_add( -charset => 'utf-8' );
    $self->start_mode('debug');
    $self->mode_param('mode');

}


#
#  Handlers
#

sub debug_handler
{
    my ($self) = (@_);

    my $session = $self->param('session');

    if ( $session->param("logged_in") )
    {
        return "User: " . $session->param("logged_in");
    }
    else
    {
        return "Anonymous";
    }
}


# ===========================================================================
#  View recent comments
# ===========================================================================
sub recent_comments
{
    my ($self) = (@_);

    #
    # Load the XML template
    #
    my $template =
      HTML::Template->new( filename => "../templates/xml/comments.template" );

    #
    #  Setup recent comment type.
    #
    $template->param( site_slogan     => get_conf('site_slogan') );
    $template->param( home_url        => get_conf('home_url') );
    $template->param( recent_comments => 1 );


    my $form = Singleton::CGI->instance();
    my $count = $form->param('count') || 10;
    if ( $count =~ /([0-9]+)/ )
    {
        $count = $1;
    }

    my $c = Yawns::Comments->new();
    my ( $teasers, $comments ) = $c->getRecent($count);

    $template->param( comments => $comments,
                      teasers  => $teasers, );

    $self->header_add( 'Content-type' => 'application/rss+xml' );

    return ( $template->output() );
}



# ===========================================================================
#  Feed of comments by a given user.
# ===========================================================================
sub user_feed
{
    my ($self) = (@_);

    my $form = Singleton::CGI->instance();
    my $user = $form->param('user');

    #
    # Load the XML template
    #
    my $template =
      HTML::Template->new( filename => "../templates/xml/comments.template" );

    #
    #  Setup basics.
    #
    $template->param( site_slogan => get_conf('site_slogan') );
    $template->param( home_url    => get_conf('home_url') );

    #
    # Get access to the form
    #
    my $form = Singleton::CGI->instance();

    #
    # Get the comments.
    #
    my $c = Yawns::Comments->new();
    my ( $teasers, $comments ) = $c->getRecentByUser($user);

    $template->param( comments => $comments,
                      teasers  => $teasers,
                      username => $user,
                      byuser   => 1,
                    );


    $self->header_add( 'Content-type' => 'application/rss+xml' );
    return ( $template->output() );
}



# ===========================================================================
#  Find and return an XML feed of the given user's weblog.
# ===========================================================================
sub weblog_feed
{
    my ($self) = (@_);

    #
    # Gain acess to form objects we use.
    #
    my $form = Singleton::CGI->instance();

    #
    # Find out who and how many - then get the weblog data.
    #
    my $wanted = $form->param('user');

    #
    #  Get a feed of the weblog entries.
    #
    my $weblog = Yawns::Weblog->new( username => $wanted );
    my $entries = $weblog->getWeblogFeed();

    # open the html template
    my $template = HTML::Template->new(
                            filename => "../templates/xml/weblog_feed.template",
                            die_on_bad_params => 0 );

    $template->param( user => $wanted );

    #
    #  Only show the entries if present.
    #
    $template->param( entries => $entries ) if ( defined($entries) );


    $self->header_add( 'Content-type' => 'application/rss+xml' );
    return ( $template->output() );
}


# ===========================================================================
#  Return a feed of all articles with the given tag.
# ===========================================================================
sub tag_feed
{
    my ($self) = (@_);

    #
    # Gain access to the form.
    #
    my $form = Singleton::CGI->instance();
    my $tag  = $form->param("tag");

    #
    # Get the articles
    #
    my $holder   = Yawns::Tags->new();
    my $articles = $holder->_findByTagType( $tag, 'a' );
    my $weblogs  = $holder->_findByTagType( $tag, 'w' );
    my $home_url = get_conf('home_url');


    #
    #  The results we'll show.
    #
    my $results;

    #
    # For each article fill in the lead text.
    #
    foreach my $match (@$articles)
    {

        #
        #  Get lead text.
        #
        my $text;
        if ( $match->{ 'link' } =~ /([0-9]+)/ )
        {
            my $id = $1;
            my $article = Yawns::Article->new( id => $id );
            $text = $article->getLeadText();
        }

        # HTML Encode the text since it is for a feed.
        $text = HTML::Entities::encode_entities($text) if ($text);

        # Setup the text type + home url link
        $match->{ 'text' } = $text if ($text);

        # Make sure title is escaped.
        $match->{ 'title' } =
          HTML::Entities::encode_entities( $match->{ 'title' } )
          if ( $match->{ 'title' } );

        $match->{ 'home_url' } = $home_url;

        # Store the updated hash.
        push @$results, \%$match;
    }


    #
    # For each weblog insert the text.
    #
    foreach my $match (@$weblogs)
    {

        #
        #  Get lead text.
        #
        my $text;
        if ( $match->{ 'link' } =~ /\/users\/([^\/]+)\/weblog\/([0-9]+)/ )
        {
            my $user   = $1;
            my $id     = $2;
            my $weblog = Yawns::Weblog->new( username => $user, id => $id );

            my $entry =
              $weblog->getSingleWeblogEntry( gid => $weblog->getGID() );

            my @f = @$entry;
            $entry = $f[0];
            $text  = $entry->{ 'bodytext' };
        }

        # HTML Encode the text since it is for a feed.
        $text = HTML::Entities::encode_entities($text) if ($text);

        # Setup the text type + home url link
        $match->{ 'text' } = $text if ($text);

        # Make sure title is escaped.
        $match->{ 'title' } =
          HTML::Entities::encode_entities( $match->{ 'title' } )
          if ( $match->{ 'title' } );

        $match->{ 'home_url' } = $home_url;

        # Store the updated hash.
        push @$results, \%$match;
    }


    # read in the template file
    my $template = HTML::Template->new(
                                   filename => "../templates/xml/tags.template",
                                   die_on_bad_params => 0 );
    $template->param( matching => $results ) if ($results);

    # basics.
    $template->param( home_url    => get_conf('home_url') );
    $template->param( site_slogan => get_conf('site_slogan') );

    #
    #  Output the page
    #
    $self->header_add( 'Content-type' => 'application/rss+xml' );
    return ( $template->output() );
}




# ===========================================================================
# Return an RSS feed of pending submissions
# ===========================================================================
sub pending_submissions
{
    my( $self ) = ( @_ );

    #
    #  Find all the pending submissions.
    #
    my $queue = Yawns::Submissions->new();
    my $new   = $queue->getArticleFeed();

    #
    #  Load the template
    #
    my $template = HTML::Template->new(
                            filename => "../templates/xml/submissions.template",
                            global_vars       => 1,
                            die_on_bad_params => 0
    );

    #
    #  Setup basic things.
    #
    $template->param( site_slogan => get_conf('site_slogan') );
    $template->param( home_url    => get_conf('home_url') );

    #
    #
    #

    $template->param( submissions => $new, ) if ($new);

    $self->header_add( 'Content-type' => 'application/rss+xml' );
    return ( $template->output() );
}


1;
