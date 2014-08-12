#!/usr/bin/perl -I../lib -I../../lib
#
#  Wrapper for our Feed application - CGI version.
#

use strict;
use warnings;

use Application::Feeds;

my $f = Application::Feeds->new();
$f->run();
