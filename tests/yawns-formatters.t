#!/usr/bin/perl -w -Ilib/
#
#  Test that we can work with our formatters list.
#
# $Id: yawns-formatters.t,v 1.2 2007-02-04 01:10:47 steve Exp $
#

use Test::More qw( no_plan );

#
#  Load the modules we use.
#
BEGIN { use_ok( 'Yawns::Formatters'); }
require_ok( 'Yawns::Formatters' );


#
#  Create the object
#
my $creator = Yawns::Formatters->new();
isa_ok( $creator, "Yawns::Formatters" );


#
#  Get the available options and the expected ones.
#
my %avail    = $creator->getAvailable();
my @expected = qw/ bbcode html text textile /;

#
#  Test they are the same length.
#
is( scalar( keys( %avail ) ), $#expected + 1, "We have the number of formatters we expect" );

#
#  Make sure each one is what we expected.
#
foreach my $k ( @expected )
{
    ok( defined( $avail{$k}), "Found expected key : $avail{$k}" );
}


#
#  Make sure we can create each type.
#
foreach my $k ( @expected )
{
    ok( $creator->create( $k, "Some text" ), "Created formatter" );
}
