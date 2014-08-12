#
# This is a CGI::Application class which is designed to handle
# our feed-needs
#
# It is a proof of concept at the moment, because the code isn't
# complete.
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

1;
