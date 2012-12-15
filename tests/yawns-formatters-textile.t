#!/usr/bin/perl -w -I..
#
#  Test that we can format Textile comments.
#
# $Id: yawns-formatters-textile.t,v 1.1 2007-01-30 21:14:49 steve Exp $
#

use Test::More qw( no_plan );

#
#  Load the modules we use.
#
BEGIN { use_ok( 'Yawns::Formatters::Textile'); }
require_ok( 'Yawns::Formatters::Textile' );


#
#  Input text for the test
#
my $text =<<EOF;

.h1 This is a header.

*This* is _italic_

http://foo.com/
EOF


#
#  Create the object
#
my $creator = Yawns::Formatters::Textile->new( text => $text );
isa_ok( $creator, "Yawns::Formatters::Textile" );

#
#  Make sure we can get the original text
#
my $orig     = $creator->getOriginal();
my $modified = $creator->getPreview();

#
#  Make sure we found something.
#
ok( $orig,     "Original text is found" );
ok( $modified, "Modified text is found" );

#
#  Test the content
#
is( $text, $orig, "Original text unchanged" );

#
#  The modified version should have bold tags in it
#
ok( $modified =~ m/<strong>/i, "Modified text has bold tag in it: 1/2" );
ok( $modified =~ m/<\/strong>/i, "Modified text has bold tag in it: 2/2" );

#
#  The modified version should have italic tags in it
#
ok( $modified =~ m/<em>/i, "Modified text has italic tag in it: 1/2" );
ok( $modified =~ m/<\/em>/i, "Modified text has italic tag in it: 2/2" );
