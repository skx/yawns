#
# This is a CGI::Application class which is designed to handle
# our main site.
#
#


use strict;
use warnings;


#
# Hierarchy.
#
package Application::Yawns;
use base 'CGI::Application';


#
# Standard module(s)
#
use Cache::Memcached;
use HTML::Template;

#
# Our code
#
use Yawns::About;
use Yawns::Event;
use Yawns::Sidebar;
use Yawns::User;
use conf::SiteConfig;


=begin doc

Setup - Instantiate the session and handle cookies.

=end doc

=cut

sub cgiapp_init
{
    my $self  = shift;
    my $query = $self->query();

    my $cookie_name   = 'CGISESSID';
    my $cookie_expiry = '+7d';
    my $sid           = $query->cookie($cookie_name) || undef;

    #
    # The memcached host is the same as the DBI host.
    #
    my $dbserv = conf::SiteConfig::get_conf('dbserv');
    $dbserv .= ":11211";

    #
    # Get the memcached handle.
    #
    my $mem = Cache::Memcached->new( { servers => [$dbserv],
                                       debug   => 0
                                     } );

    # session setup
    my $session =
      new CGI::Session( "driver:memcached", $query, { Memcached => $mem } ) or
      die($CGI::Session::errstr);



    # assign the session object to a param
    $self->param( session => $session );

    # send a cookie if needed
    if ( !defined $sid or $sid ne $session->id )
    {
        my $cookie = $query->cookie( -name     => $cookie_name,
                                     -value    => $session->id,
                                     -expires  => $cookie_expiry,
                                     -httponly => 1,
                                   );
        $self->header_props( -cookie => $cookie );
    }


    binmode STDIN,  ":encoding(utf8)";
    binmode STDOUT, ":encoding(utf8)";
}


#
#  Flush the sesions
#
sub teardown
{
    my ($self) = shift;

    my $session = $self->param('session');
    $session->flush() if ( defined($session) );
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



#
#  TODO: PreRun IP check.
#



=begin doc

Setup our run-mode mappings, and the defaults for the application.

=end doc

=cut

sub setup
{
    my $self = shift;

    $self->error_mode('my_error_rm');
    $self->run_modes(

        # via a static page
        'about' => 'about_page',

        # debug
        'debug' => 'debug',

        # Login/Logout
        'login'  => 'application_login',
        'logout' => 'application_logout',

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
#  Error-mode.
#
sub my_error_rm
{
    my ( $self, $error ) = (@_);

    use Data::Dumper;
    return Dumper( \$error );
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

  A filter to allow dynamic page inclusions.

=end doc

=cut

sub mk_include_filter
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

sub load_layout
{
    my ( $self, $page, %options ) = (@_);

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
    my $session = $self->param("session");
    if ( $options{ 'session' } )
    {
        delete $options{ 'session' };
        $l->param( session => md5_hex( $session->id() ) );
    }

    #
    # Make sure the sidebar text is setup.
    #
    my $sidebar = Yawns::Sidebar->new();
    $l->param(
            sidebar_text => $sidebar->getMenu( $session->param("logged_in") ) );
    $l->param(
         login_box_text => $sidebar->getLoginBox( $session->param("logged_in") )
    );
    $l->param( site_title => get_conf('site_title') );
    $l->param( metadata   => get_conf('metadata') );

    my $logged_in = 1;

    my $session  = $self->param("session");
    my $username = $session->param("logged_in");
    if ( $username =~ /^anonymous$/i )
    {
        $logged_in = 0;
    }
    $l->param( logged_in => $logged_in );

    return ($l);
}




#
#  Real handlers
#


#
#  Handlers
#
sub debug
{
    my ($self) = (@_);

    my $session = $self->param('session');
    my $username = $session->param("logged_in") || "Anonymous";

    return ("OK - $username");
}



#
#  Login
#
sub application_login
{
    my ($self) = (@_);

    my $q       = $self->query();
    my $session = $self->param('session');

    # if already logged in redirect
    my $username = $session->param("username") || undef;
    if ( $username && ( $username ne "Anonymous" ) )
    {
        return $self->redirectURL("/");
    }

    #
    # If the user isn't submitting a form then show it
    #
    if ( ! $q->param("submit") )
    {


        # open the html template
        my $template = $self->load_layout("login_form.inc");

        if ( !defined( $ENV{ 'HTTPS' } ) or ( $ENV{ 'HTTPS' } !~ /on/i ) )
        {

            # Link to the HTTPS version of this form
            $template->param( http => 1 );

            # Secure link
            $template->param( secure => "https://" . $ENV{ 'SERVER_NAME' } .
                              $ENV{ 'REQUEST_URI' },
                              title => "Advanced Login Options"
                            );
        }

        return( $template->output() );
    }


    my $lname  = $q->param('lname');
    my $lpass  = $q->param('lpass');
    my $secure = $q->param('secure');
    my $ssl    = $q->param('ssl');


    my $protocol = "http://";

    if ( defined( $ENV{ 'HTTPS' } ) && ( $ENV{ 'HTTPS' } =~ /on/i ) )
    {
        $protocol = "https://";
    }

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
        my $target = $q->param("target");
        if ( defined($target) && ( $target =~ /^\// ) )
        {
            return ( $self->redirectURL($target) );
        }
        else
        {

            #
            #  No explicit target - show the homepage.
            #
            return ( $self->redirectURL("/") );
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
        return ( $self->redirectURL("/login/") );
    }

}


#
# Logout the user.
#
sub application_logout
{
    my ($self) = (@_);

    my $q       = $self->query();
    my $session = $self->param('session');

    #
    #  Clear the session
    #
    $session->param( 'logged_in', undef );
    $session->clear('logged_in');
    $self->param( 'session', undef );
    $session->close();

    #
    #  Return to the homepage.
    #
    return ( $self->redirectURL("/") );
}


# ===========================================================================
# about section
# ===========================================================================
sub about_page
{
    my ($self) = (@_);

    my $q        = $self->query();
    my $session  = $self->param('session');
    my $username = $session->param("logged_in") || "Anonymous";

    #
    # Is the viewer allowed to edit the page?
    #
    my $may_edit = 0;
    if ( $username !~ /^anonymous$/ )
    {

        #
        #  Check the permissions
        #
        my $perms = Yawns::Permissions->new( username => $username );
        $may_edit = 1 if $perms->check( priv => "edit_about" );
    }


    #
    # Get the page from the about section.
    #
    my $key   = $q->param('about');
    my $pages = Yawns::About->new();
    my $about = $pages->get( name => $key );


    # set up the HTML template
    my $template = $self->load_layout("about.inc");

    # fill in the template parameters
    $template->param( title        => $key,
                      article_body => $about,
                      may_edit     => $may_edit,
                    );

    # generate the output
    return ( $template->output() );
}


1;
