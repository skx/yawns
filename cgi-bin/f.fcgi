#!/usr/bin/perl -I../lib -I../../lib -I../../../lib/
#
#  Wrapper for our Feed application - FastCGI version.
#

use strict;
use warnings;


use CGI::Carp qw/ fatalsToBrowser /;
use CGI::Fast();
use Application::Feeds;


#
#  Load and run - catching any errors.
#
eval {
    while ( my $q = CGI::Fast->new() )
    {
        my $a = Application::Feeds->new( QUERY => $q );
        $a->run();
    }
};
if ($@)
{
    print "Content-type: text/plain\n\n";
    print "ERROR: $@";
}
