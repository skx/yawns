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
#  TODO: PreRun bind to IP.
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

        # debug
        'debug' => 'debug',

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
    my( $self ) = ( @_ );

    my $session = $self->session();
    my $username = $session->param( "logged_in" ) || "Anonymous";

    return ("OK - $username");
}


#
#  Error-mode.
#
sub my_error_rm
{
    my ( $self, $error ) = (@_);

    return Dumper( \$error );
}


1;
