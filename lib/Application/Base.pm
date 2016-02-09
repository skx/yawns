package Application::Base;
use base 'CGI::Application';

use CGI::Session;
use Cache::Memcached;
use Singleton::Redis;


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

    my $session;

    #
    #  Are we using memcached?
    #
    my $cache = conf::SiteConfig::get_conf("session");

    if ( $cache =~ /^memcache:\/\/(.*)\/$/i )
    {
        #
        # The host is specified after the port.
        #
        my $host = $1;

        #
        # Get the memcached handle.
        #
        my $mem = Cache::Memcached->new(
                                         { servers => [$host],
                                           debug   => 0
                                         } );

        # session setup
        $session =
          new CGI::Session( "driver:memcached", $query, { Memcached => $mem } )
          or
          die($CGI::Session::errstr);
    }
    else
    {
        my $redis   = Singleton::Redis->new();
        $session = CGI::Session->new( "driver:redis", $sid,
                                    { Redis => $redis,
                                      Expire => 60*60*24 } );
    }

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



1;
