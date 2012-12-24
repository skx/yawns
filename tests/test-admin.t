#!/usr/bin/perl -w -Ilib/
#
#  Test that all the administration scripts are executable.
#
# $Id: test-admin.t,v 1.4 2005-11-28 13:33:44 steve Exp $
#


use Test::More qw( no_plan );

#
#  We use "Test::File" if available.
#
BEGIN { use_ok( 'Test::File' ); }
require_ok( 'Test::File' );


#
#  Test each file in the admin/ directory.
#
foreach my $i (glob( "../admin/*" ) )
{
    #
    #  Ignoring "README", and the CVS directory.
    #
    next if $i =~ /CVS/;
    next if $i =~ /README/;

    #
    #  File is executable?
    #
    file_executable_ok( $i, "$i is executable" );
}
