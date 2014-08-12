#!/usr/bin/perl -I../lib -I../../lib
#
#  Wrapper for our Ajax application - CGI version.
#

use strict;
use warnings;

use Application::Ajax;

my $f = Application::Ajax->new();
$f->run();
