
=head1 NAME

Singleton::Session - A singleton wrapper around the CGI::Session object.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Singleton::Session;
    use strict;

    # Gain access to the session.
    my $session = Singleton::Session->instance();

    # Fetch a parameter from it.
    $session->param( "bob" );

=for example end


=head1 DESCRIPTION


  This module implements a Singleton wrapper around the CGI::Session
 module.

  This allows different parts of the codebase to access the session
 of the current client.

=cut


package Singleton::Session;


#
# Database connection details.
#
use conf::SiteConfig;

#
#  CGI form we use.
#
use Singleton::CGI;


# Session information is stored in the database.
use CGI::Session;
use Cache::Memcaced;

#
#  The single, global, instance of this object
#
my $_session = undef;



=head2 instance

  Gain access to the single instance of this object.

=cut

sub instance
{
    if ($_session)
    {
        return $_session;
    }
    else
    {
        $_session = new();
        return ($_session);
    }

}



=head2 new

  Create a new instance of this object.

  Internally we manage a database connection too, because we are storing
 our session data inside a database.

=cut


sub new
{

    #
    # Gain access to the CGI instance too.
    #
    my $mem  = Cache::Memcaced->new({ servers => [ '212.110.179.77:11211' ],
                                      debug => 0 } );
    my $form = Singleton::CGI->instance();

    my $t = new CGI::Session( "driver:memcached",
                              $form,
                            { Memcached => $mem } 
                            )
      or
        die($CGI::Session::errstr);

    return ($t);
}


1;



=head1 AUTHOR

Steve Kemp

http://www.steve.org.uk/

=cut



=head1 LICENSE

Copyright (c) 2005-2011 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut
