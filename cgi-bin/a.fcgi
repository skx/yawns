#!/usr/bin/perl -I../lib -I../../lib -I../../../lib/

=head1 NAME

a.fcgi - FastCGI Handler for AJAX requests

=head1 DESCRIPTION

This wrapper script loads our L<Application::Ajax> module, which is
designed to handle incoming AJAX requests.

=cut

=head1 AUTHOR

 Steve
 --
 http://www.steve.org.uk/

=cut

=head1 LICENSE

Copyright (c) 2014 by Steve Kemp.  All rights reserved.

This script is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

The LICENSE file contains the full text of the license.

=cut



use strict;
use warnings;


use CGI::Fast();
use Application::Ajax;


#
#  Load and run - catching any errors.
#
eval {
    while ( my $q = CGI::Fast->new() )
    {
        my $a = Application::Ajax->new( QUERY => $q );
        $a->run();
    }
};
if ($@)
{
    print "Content-type: text/plain\n\n";
    print "ERROR: $@";
}
