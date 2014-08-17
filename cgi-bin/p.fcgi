#!/usr/bin/perl -I../lib -I../../lib -I../../../lib/
#
#  Wrapper for our Poll application - FastCGI version.
#

use strict;
use warnings;


use CGI::Fast();
use Application::Poll;


#
#  Load and run - catching any errors.
#
eval {
    while ( my $q = CGI::Fast->new() )
    {
        my $a = Application::Poll->new( QUERY => $q );
        $a->run();
    }
};
if ($@)
{
    print "Content-type: text/plain\n\n";
    print "ERROR: $@";
}
