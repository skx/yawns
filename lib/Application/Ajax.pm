#
# This is a CGI::Application class which is designed to handle
# our Ajax requests.
#
#


use strict;
use warnings;


#
# Hierarchy.
#
package Application::Ajax;
use base 'CGI::Application';

#
# Standard module(s)
#
use CGI::Session;
use Cache::Memcached;


#
# Our code
#
use conf::SiteConfig;




=begin doc

Called on-error

=end doc

=cut

sub my_error_rm
{
    my ( $self, $error ) = (@_);

    return Dumper( \$error );
}




=begin doc

Setup - Just setup UTF.

=end doc

=cut

sub cgiapp_init
{
    my $self  = shift;
    my $query = $self->query();

    #
    #  Get the cookie if we have one.
    #
    my $cookie_name   = 'CGISESSID';
    my $cookie_expiry = '+7d';
    my $sid           = $query->cookie($cookie_name) || undef;

    #
    #  Create the object
    #
    if ($sid)
    {
        my $dbserv = conf::SiteConfig::get_conf('dbserv');
        $dbserv .= ":11211";

        my $mem = Cache::Memcached->new( { servers => [$dbserv],
                                           debug   => 0
                                         } );

        my $session = CGI::Session->new( "driver:memcached", $query,
                                         { Memcached => $mem } );


        #
        # assign the session object to a param
        #
        $self->param( session => $session );
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

    return ("mode not found: $requested");
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
    my ($self) = (@_);

    my $username = "Anonymous";

    my $session = $self->param('session');
    if ($session)
    {
        $username = $session->param("logged_in") || "Anonymous";
    }
    return ("OK - $username");
}



1;
