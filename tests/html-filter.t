#!/usr/bin/perl -w -Ilib/
#
# Test that input HTML is filtered as expected.
#
# $Id: html-filter.t,v 1.3 2007-02-02 00:56:04 steve Exp $
#

use Test::More qw( no_plan );

# Can we load the module?
BEGIN { use_ok( 'HTML::AddNoFollow' ); }
require_ok( 'HTML::AddNoFollow' );
BEGIN { use_ok( 'CGI' ); }
require_ok( 'CGI' );




#
# Create CGI object.
#
my $cgi = new CGI;
ok( defined( $cgi ), "Created OK" );
isa_ok( $cgi, "CGI" );


#
#  Test the filter.
#
testHTML( "This is a test",
	  "This is a test",
	  "Plain text" );

testHTML( "<p>This is a test</p>",
	  "<p>This is a test</p>",
	  "Paragraph" );

testHTML( "<p color=\"red\">This is a test</p>",
	  "<p>This is a test</p>",
	  "Removed colour" );

testHTML( "<p style=\"gothic\">This is a test</p>",
	  "<p>This is a test</p>",
	  "Removed style" );

testHTML( "<p class=\"gothic\">This is a test</p>",
	  "<p>This is a test</p>",
	  "Removed class" );

testHTML( '<a href="http://blah.com/" onClick="alert(1);">Link</a>',
	  '<a href="http://blah.com/" rel="nofollow">Link</a>',
	  'Removed onClick');

testHTML( '<a href="http://blah.com/" id="foo">Link</a>',
	  '<a href="http://blah.com/" id="foo" rel="nofollow">Link</a>',
	  'Ignored hyperlink ID');

testHTML( '<a href="http://blah.com/" name="foo">Link</a>',
	  '<a href="http://blah.com/" name="foo" rel="nofollow">Link</a>',
	  'Ignored hyperlink NAME');

testHTML( "<div>test</div>",
	  "test",
	  "Removed div" );

testHTML( "<table><tr><td>test</td></tr></table>",
          "<table><tr><td>test</td></tr></table>",
	  "Left table" );

testHTML( "<img src=\"http://foo.com/img.jpg\">",
	  "<img src=\"http://foo.com/img.jpg\">",
	  "Ignored image" );

testHTML( "<img src=\"ftp://foo.com/img.jpg\">",
	  "<img>",
	  "Removed FTP image" );

testHTML( "<img src=\"http://foo.com/img.jpg\" alt=\"test\">",
	  "<img src=\"http://foo.com/img.jpg\" alt=\"test\">",
	  "Ignored image ALT" );

testHTML( "<img src=\"http://foo.com/img.jpg\" id=\"test\">",
	  "<img src=\"http://foo.com/img.jpg\">",
	  "Removed image ID" );



#
#  A simple routing to act as a test of input vs. output for our
# santizer.
#
sub testHTML
{
    my ( $input, $output, $text ) = ( @_ );

    #
    # Set the parameter value
    #
    $cgi->param( "text", $input );

    #
    # Do the cleaning.
    #
    $cgi = HTML::AddNoFollow::sanitize( $cgi );

    #
    # See if we got what we expected.
    #
    is( $cgi->param( "text" ), $output, "Filtered as expected: $text" );
}
