#!/usr/bin/perl -w -I..
#
#  Test that we can get, edit, and delete a static page.
#
# $Id: yawns-about.t,v 1.3 2006-05-09 14:32:04 steve Exp $
#

use Test::More qw( no_plan );

#
#  Load the modules we use.
#
BEGIN { use_ok( 'Yawns::About'); }
require_ok( 'Yawns::About' );


#
#  Pick a random page name
my $name = join ( '', map {('a'..'z')[rand 26]} 0..7 );


#
#  Work with the about pages.
#
my $about = Yawns::About->new();
isa_ok( $about, "Yawns::About" );


#
#  Get the text and ensure it is empty
#
my $text = $about->get( name => $name );
ok( (!defined($text) ), "The random about page is empty" );

#
#  Save some random contents
#
my $contents = join ( '', map {('a'..'z')[rand 26]} 0..20 );
$about->set( name => $name,
	    text => $contents );

#
#  Now ensure they are saved
#
ok( defined( $about->get( name => $name ) ),
	" After setting text the page is non-empty." );

ok( ( $contents eq $about->get( name => $name ) ),
	" And the text matches what we set." );

#
#  Delete the page
#
$about->delete( name => $name );

#
#  Verify the page is gone.
#
$text = $about->get( name => $name );
ok( (!defined($text) ), "The random is empty after deletion." );
