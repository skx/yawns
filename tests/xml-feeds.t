#!/usr/bin/perl -w -Ilib/
#
#  Test that our XML output feeds are syntactically valid XML.
#
# $Id: xml-feeds.t,v 1.4 2007-06-16 12:12:07 steve Exp $
#

use Test::More;

#
#  Conditionally decide whether to run or not.
#
if ( ( -x "/usr/bin/xmllint" ) && ( -x "/usr/bin/wget" ) )
{
    plan no_plan;
}
else
{
    plan skip_all => "/usr/bin/xmllint or /usr/bin/wget not found" ;
}


#
#  Load the modules we use
#
BEGIN { use_ok( 'File::Temp'); }
require_ok( 'File::Temp' );






#
#  Look for any static files we might have.
#
foreach my $file (  glob( "*.xml" ) , glob( "*.rdf" ) )
{
    is( validXML( $file ), 1 , "File is valid XML : $file." );
}


#
#  As a control make sure that non-XML files are detected as such.
#
foreach my $file ( qw! /etc/passwd /etc/motd /etc/group ! )
{
    if ( -e $file )
    {
        is( validXML( $file ), 0, "Control file is not XML : $file" );
    }
}


#
#  Now download some files from our site and make sure they are valid XML
#
foreach my $url ( qw!
                       /recent/comments
                       /recent/reported
                       /recent/reported/weblogs
                       /News/feed/
                       /submission/feed/
                       /comment/feed/onweblog/0
                       /comment/feed/onarticle/0
                       /comment/feed/onpoll/0
                       /weblog/feeds/Steve
                       /tag/feeds/fluffy
                  ! )
{
    downloadAndTest( $url );
}




=head2 validXML

  Test the file specified for validity using xmllint.

=cut

sub validXML
{
    my( $filename ) = (@_ );

    #
    #  Run the command
    #
    ok( -e $filename, "File exists for XML check: $filename" );
    my $retval = system( "xmllint --noout $filename 2>/dev/null >/dev/null" );

    return 1 if ( $retval == 0 );
    return 0;
}



=head2 downloadAndTest

  Download an URI to a temporary file, and test it.

=cut

sub downloadAndTest
{
    my( $uri ) = (@_);

    #
    #  Create temporary directory
    #
    my $dir = File::Temp::tempdir( CLEANUP => 1 );
    ok( -d $dir, "Temporary directory created" );

    #
    #  Convert the URI into a filename - make sure it doesn't exist.
    #
    my $file = $uri;
    $file    =~ s/\//-/g;
    ok( ! -e $dir . "/" . $file, "Temporary file not found prior to download" );

    #
    #  Download
    #
    system( "wget", "-o", "/dev/null", "-O", "$dir/$file", "http://localhost" . $uri );

    ok( -e $dir . "/" . $file, "Temporary file was downloaded successfully" );


    #
    #  Now run the test..
    #
    is(validXML( $dir . "/" . $file ), 1, "URI is valid XML: $uri" );
}
