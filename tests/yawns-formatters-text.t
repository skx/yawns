#!/usr/bin/perl -w -Ilib/
#
#  Test that we can format text comments.
#
# $Id: yawns-formatters-text.t,v 1.1 2007-01-30 21:14:49 steve Exp $
#

use Test::More qw( no_plan );

#
#  Load the modules we use.
#
BEGIN { use_ok( 'Yawns::Formatters::Text'); }
require_ok( 'Yawns::Formatters::Text' );


#
#  Input text for the test
#
my $text =<<EOF;
This is some text

So is this

http://foo.com/
EOF
#
#  Create the object
#
my $creator = Yawns::Formatters::Text->new( text => $text );
isa_ok( $creator, "Yawns::Formatters::Text" );

#
#  Make sure we can get the original text
#
my $orig = $creator->getOriginal();
my $modified = $creator->getPreview();

ok( $orig,     "Original text is found" );
ok( $modified, "Modified text is found" );

#
#  Test the content
#
is( $text, $orig, "Original text unchanged" );

#
#  The modified version should have newlines replaced
#
ok( $modified =~ m/<br \/>/i, "Modified text has newlines replaced: 1/2" );
ok( $modified !~ m/\n/i, "Modified text has newlines replaced: 2/2" );
