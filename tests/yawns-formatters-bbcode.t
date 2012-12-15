#!/usr/bin/perl -w -I..
#
#  Test that we can format BBCode comments.
#
# $Id: yawns-formatters-bbcode.t,v 1.1 2007-01-30 21:14:49 steve Exp $
#

use Test::More qw( no_plan );

#
#  Load the modules we use.
#
BEGIN { use_ok( 'Yawns::Formatters::BBCode'); }
require_ok( 'Yawns::Formatters::BBCode' );


#
#  Input text for the test
#
my $text =<<EOF;

[b]This is a header[/b]

I [i]like[/i] italic text at times..

http://foo.com/
EOF
#
#  Create the object
#
my $creator = Yawns::Formatters::BBCode->new( text => $text );
isa_ok( $creator, "Yawns::Formatters::BBCode" );

#
#  Make sure we can get the original text
#
my $orig     = $creator->getOriginal();
my $modified = $creator->getPreview();

#
#  Make sure we got something.
#
ok( $orig,     "Original text is found" );
ok( $modified, "Modified text is found" );

#
#  Test the content
#
is( $text, $orig, "Original text unchanged" );

#
#  The modified version should have bold tags in it.
#
ok( $modified =~ m/<b>/i, "Modified text has bold tag in it: 1/2" );
ok( $modified =~ m/<\/b>/i, "Modified text has bold tag in it: 2/2" );

#
#  The modified version should have italic tags in it.
#
ok( $modified =~ m/<i>/i, "Modified text has italic tag in it: 1/2" );
ok( $modified =~ m/<\/i>/i, "Modified text has italic tag in it: 2/2" );

