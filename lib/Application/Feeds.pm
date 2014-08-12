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
#    /recent/reported/weblogs  Show the reported weblogs
#    /recent/reported/N        Show the N most recently reported comments.
#    /recent/reported          Show the 10 most recent reported comments.
#
#    /comment/feed/onweblog/N   General feed.
#    /comment/feed/onarticle/N  General feed.
#    /comment/feed/onpoll/N     General feed.
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
use HTML::Template;
use URI::Find;

#
# Our code
#
use conf::SiteConfig;
use Yawns::Comments;
use Yawns::Submissions;
use Yawns::Weblogs;



=begin doc

Setup - Just setup UTF.

=end doc

=cut

sub cgiapp_init
{
    binmode STDIN,  ":encoding(utf8)";
    binmode STDOUT, ":encoding(utf8)";
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

    $self->error_mode('my_error_rm');
    $self->run_modes(

        # debug
        'debug' => 'debug',

        # General comment-feed
        'comment_feed' => 'comment_feed',

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

        # Recently reported comments.
        'recent_reported' => 'recent_reported',

        # Reported weblog posts
        'reported_weblogs' => 'reported_weblogs',

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
sub debug
{
    return( "OK" );
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


    my $form = $self->query();
    my $count = $form->param('count') || 10;
    if ( $count =~ /([0-9]+)/ )
    {
        $count = $1;
    }

    my $c = Yawns::Comments->new();
    my ( $teasers, $comments ) = $c->getRecent($count);

    $template->param( comments => $comments,
                      teasers  => $teasers, );

    $self->header_add( '-type' => 'application/rss+xml' );

    return ( $template->output() );
}



# ===========================================================================
#  Feed of comments by a given user.
# ===========================================================================
sub user_feed
{
    my ($self) = (@_);

    my $form = $self->query();
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
    # Get the comments.
    #
    my $c = Yawns::Comments->new();
    my ( $teasers, $comments ) = $c->getRecentByUser($user);

    $template->param( comments => $comments,
                      teasers  => $teasers,
                      username => $user,
                      byuser   => 1,
                    );


    $self->header_add( '-type' => 'application/rss+xml' );
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
    my $form = $self->query();

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


    $self->header_add( '-type' => 'application/rss+xml' );
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
    my $form = $self->query();
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
    $self->header_add( '-type' => 'application/rss+xml' );
    return ( $template->output() );
}




# ===========================================================================
# Return an RSS feed of pending submissions
# ===========================================================================
sub pending_submissions
{
    my ($self) = (@_);

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

    $self->header_add( '-type' => 'application/rss+xml' );
    return ( $template->output() );
}




# ===========================================================================
#  View recently reported comments
# ===========================================================================
sub recent_reported
{
    my ($self) = (@_);

    my $form = $self->query();
    my $count = $form->param('count') || 10;
    if ( $count =~ /([0-9]+)/ )
    {
        $count = $1;
    }

    #
    # Load the XML template
    #
    my $template =
      HTML::Template->new( filename => "../templates/xml/comments.template" );

    #
    #  Setup reported type.
    #
    $template->param( site_slogan     => get_conf('site_slogan') );
    $template->param( home_url        => get_conf('home_url') );
    $template->param( recent_reported => 1 );


    my $c = Yawns::Comments->new();
    my ( $teasers, $comments ) = $c->getReported($count);

    $template->param( comments => $comments,
                      teasers  => $teasers, );

    $self->header_add( '-type' => 'application/rss+xml' );
    return ( $template->output() );
}



# ===========================================================================
#  Find and return an XML feed of recently reported weblog entries.
# ===========================================================================
sub reported_weblogs
{
    my ($self) = (@_);

    #
    #  Get a feed of the weblog entries.
    #
    my $weblog  = Yawns::Weblogs->new();
    my $entries = $weblog->getReportedWeblogs();

    # open the html template
    my $template =
      HTML::Template->new(
                          filename => "../templates/xml/weblog_feed.template" );

    $template->param( entries  => $entries,
                      reported => 1, );

    my $output = $template->output();

    $self->header_add( '-type' => 'application/rss+xml' );
    return ( $template->output() );
}


# ===========================================================================
#  View comment feeds
# ===========================================================================
sub comment_feed
{
    my ($self) = (@_);

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
    my $form = $self->query();

    #
    # Types
    #
    my $article = $form->param("article_id");
    my $poll    = $form->param("poll_id");
    my $weblog  = $form->param("weblog_id");


    my $c = Yawns::Comments->new();
    my ( $teasers, $comments ) =
      $c->getCommentFeed( article => $article,
                          poll    => $poll,
                          weblog  => $weblog,
                        );

    $template->param( comments => $comments,
                      teasers  => $teasers, );

    #
    #  Titles
    #
    if ($article)
    {
        my $a = Yawns::Article->new( id => $article );
        my $title = $a->getTitle();

        $template->param( title     => "Comments on $title",
                          onarticle => 1 );
    }
    if ($poll)
    {
        my $p = Yawns::Poll->new( id => $poll );
        my $title = $p->getTitle();

        $template->param( title  => "Comments on $title",
                          onpoll => 1 );
    }
    if ($weblog)
    {
        my $w = Yawns::Weblog->new( gid => $weblog );
        my $title = $w->getTitle();

        $template->param( title    => "Comments on $title",
                          onweblog => 1 );
    }

    $self->header_add( '-type' => 'application/rss+xml' );
    return ( $template->output() );
}


sub my_error_rm
{
    my( $self , $error ) = ( @_ );

    return Dumper( \$error );
}


1;
