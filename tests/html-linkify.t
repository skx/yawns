#!/usr/bin/perl -w -I.
#
# Test that the HTML link generation process works as expected.
#
# $Id: html-linkify.t,v 1.1 2005-12-06 18:05:09 steve Exp $
#

use Test::More qw( no_plan );

# Can we load the module?
BEGIN { use_ok( 'HTML::Linkize' ); }
require_ok( 'HTML::Linkize' );

# Create object?
my $linker = HTML::Linkize->new();

# Is it created OK?
ok( defined( $linker ), "Created OK" );

# Is it the correct type?
isa_ok( $linker, "HTML::Linkize" );


#
# Test using the code.
#
my $html1 = q[ <a href="http://www.foo.com/">foo.com</a> ];
my $html2 = q[ <p>This is some test text</p> ];
my $html3 = q[ http://foo.com/ ];
my $html4 = q[];


my $out1 = $linker->linkize( $html1 );
is( $out1, $html1, "HTML hyperlink left alone" );

my $out2 = $linker->linkize( $html2 );
is( $out2, $html2, "Non-link text left alone" );

my $out3 = $linker->linkize( $html3 );
is( $out3, ' <a href="http://foo.com/" rel="nofollow">http://foo.com/</a> ', "Plain text link is transformed into a hyperlink." );

my $out4 = $linker->linkize( $html4 );
is( $out4, $html4, "Empty text is left alone" );
