#!/usr/bin/perl -w -I..
#
#  Test the HTML::BreakupText module works correctly.
#
# $Id: breakup-text.t,v 1.5 2005-11-28 13:37:54 steve Exp $
#

use Test::More qw( no_plan );

# Can we load the module?
BEGIN { use_ok( 'HTML::BreakupText' ); }
require_ok( 'HTML::BreakupText' );

# Create object?
my $formatter = HTML::BreakupText->new( width => 10 );
isa_ok( $formatter, "HTML::BreakupText" );

#
# Now try to breakup some text.
#
my $text1 = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
my $text2 = '<a href="http://www.fffffffffffffffffff.com/">test</a>';
my $text3 = '<a href="http://www.fffffffffffffffffff.com/">xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx</a>';


my $output1 = $formatter->BreakupText( $text1 );
my $output2 = $formatter->BreakupText( $text2 );
my $output3 = $formatter->BreakupText( $text3 );

ok( $output1 =~ / /, "Long text is broken in some way." );
ok( $output2 eq $text2 , "HTML text is left alone." );
ok( $output3 =~ /x x/, "HTML link title is broken up nicely." );



