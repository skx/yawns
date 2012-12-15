#!/usr/bin/perl -w -I..
#
# Test that HTML is "balanced" as expected.
#
# $Id: html-balance.t,v 1.1 2006-03-07 11:18:30 steve Exp $
#

use Test::More qw( no_plan );

# Can we load the module?
BEGIN { use_ok( 'HTML::Balance' ); }
require_ok( 'HTML::Balance' );


#
#  Test the filter.
#
testHTML( "This is a test", "This is a test", "Plain text" );
testHTML( "<p>This is a test.</p>", "<p>This is a test.", "Paragraph" );
testHTML( "<p><i>This <b>is a test</i>.</p>", "<p><i>This <b>is a test</b></i>.", "Nested tags" );




#
#  A simple routing to act as a test of input vs. output for our
# santizer.
#
sub testHTML
{
    my ( $input, $output, $text ) = ( @_ );

    #
    # Do the cleaning.
    #
    $input = HTML::Balance::balance( $input );

    #
    # See if we got what we expected.
    #
    is( $input, $output, "Balanced as expected: $text" );
}
