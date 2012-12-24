#!/usr/bin/perl -w -Ilib/
#
#  Test that we can format HTML comments.
#
# $Id: yawns-formatters-html.t,v 1.1 2007-01-30 21:14:49 steve Exp $
#

use Test::More qw( no_plan );

#
#  Load the modules we use.
#
BEGIN { use_ok( 'Yawns::Formatters::HTML'); }
require_ok( 'Yawns::Formatters::HTML' );


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
my $creator = Yawns::Formatters::HTML->new( text => $text );
isa_ok( $creator, "Yawns::Formatters::HTML" );

#
#  Make sure we can get the original text
#
my $orig = $creator->getOriginal();
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

