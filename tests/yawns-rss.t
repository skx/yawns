#!/usr/bin/perl -w -Ilib/
#
#  Test that we can create the RSS feeds correctly.
#
# $Id: yawns-rss.t,v 1.2 2005-11-28 13:33:44 steve Exp $
#

use Test::More qw( no_plan );

#
#  Load the modules we use
#
BEGIN { use_ok( 'Yawns::RSS'); }
require_ok( 'Yawns::RSS' );

BEGIN { use_ok( 'File::Temp'); }
require_ok( 'File::Temp' );


#
# Create a temporary directory.
#
my $dir = File::Temp::tempdir( CLEANUP => 1 );

ok( -d $dir, "Temporary directory created : $dir" );


#
#
# Get the RSS object.
#
my $feed = Yawns::RSS->new( headlines => $dir . "/headlines.rdf",
			    articles  => $dir . "/articles.rdf",
			    atom      => $dir . "/atom.xml" );
ok( defined( $feed ), "Created Feed object" );


#
# Is the object the correct type?
#
isa_ok( $feed, "Yawns::RSS" );


#
# Now create the output files.
#
$feed->output();


#
#  Now test that we got something out of the process.
#

ok( -f $dir . "/articles.rdf", "Articles file created" );
ok( -s $dir . "/articles.rdf", " Has non-zero size" );

ok( -f $dir . "/atom.xml", "Atom file created" );
ok( -s $dir . "/atom.xml", " Has non-zero size" );

ok( -f $dir . "/headlines.rdf", "Headlines file created" );
ok( -s $dir . "/headlines.rdf", " Has non-zero size" );
