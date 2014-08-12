#!/usr/bin/perl -I../lib -I../../lib

use Application::Feeds;

my $f = Application::Feeds->new();
$f->run();
