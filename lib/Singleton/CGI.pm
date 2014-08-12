
=head1 NAME

Singleton::CGI - A singleton wrapper around the CGI object.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Singleton::CGI;
    use strict;

    my $cgi = Singleton::CGI->instance();

    $cgi->param( "bob" );

=for example end


=head1 DESCRIPTION


  This module implements a Singleton wrapper around the CGI module.

  This allows all areas of the codebase to easily and consistently
 access any submitted CGI parameters.

=cut


package Singleton::CGI;


use strict;
use warnings;


$CGI::PARAM_UTF8 = 1;

use CGI ( -utf8 );
use CGI::Carp qw/ fatalsToBrowser /;


#
#  The single, global, instance of this object
#
my $oneTrueSelf;



=head2 instance

   Gain access to the single instance of our CGI object.

=cut

sub instance
{
    $oneTrueSelf ||= (shift)->new();
}



=head2 new

  Create a new instance of this object.

  This is only ever called once since this class is a Singleton.

=cut

sub new
{
    my $type = shift;

    # Return object
    my $t = new CGI();
    $t->charset("utf-8");
    return $t;
}


1;



=head1 AUTHOR

Steve Kemp

http://www.steve.org.uk/

=cut



=head1 LICENSE

Copyright (c) 2005-2009 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut
