#!/usr/bin/perl -w -Ilib/

#
#  Test that the POD we use in our modules is valid.
#


use strict;
use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

#
#  Run the test(s).
#
my @poddirs = qw( Yawns );
all_pod_files_ok( all_pod_files( @poddirs ) );
