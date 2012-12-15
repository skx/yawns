#!/usr/bin/perl -w -I..
#
#  Test that we can manipulate adverts correctly.
#

use Test::More qw( no_plan );


BEGIN { use_ok( 'Yawns::Adverts'); }
require_ok( 'Yawns::Adverts' );


#
#  Utility functions for creating a new user.
#
require 'tests/user.utils';


#
#  Create a random new user.
#
my ($user, $username ) = setupNewUser();


#
# Work with the adverts
#
my $adverts = Yawns::Adverts->new();
ok( $adverts, "Advert object created" );
isa_ok( $adverts, "Yawns::Adverts" );


#
# Count each type of advert.
#
my $cEnabled = $adverts->countActive();
my $cPending = $adverts->countPending();
ok( $cEnabled =~ /^([0-9]*)$/, "Count of enabled adverts is a number" );
ok( $cPending =~ /^([0-9]*)$/, "Count of pending adverts is a number" );


#
# Submit a new advert
#
my $newID = $adverts->addAdvert( link => "http://www.steve.org.uk",
                                 linktext => "My website",
                                 text     => "Visit steve's website!",
                                 owner    => $username,
                                 display  => 100 );

ok( $newID =~ /^([0-9]*)$/, "New advert ID is a number" );


#
# Test that the pending advert is now present
#
my $nPending = $adverts->countPending();
ok( $nPending =~ /^([0-9]*)$/, "New count of pending adverts is a number" );
is( $nPending, $cPending + 1, "The new advert has been counted" );


#
# Fetch the advert details and make sure they work.
#
my $details = $adverts->getAdvert( $newID );
is( $details->{'link'}, "http://www.steve.org.uk", "Advert link set properly" );
is( $details->{'linktext'}, "My website", "Advert link title set properly" );

#
# Count click-throughts.
#
my $clicked = $details->{'clicked'};
is( $clicked, 0 , "New advert hasn't been clicked" );

#
# Add a couple of clicks
#
$adverts->addClick( $newID );
$adverts->addClick( $newID );

#
# Make sure the count is OK.
#
$details = $adverts->getAdvert( $newID );
$clicked = $details->{'clicked'};
is( $clicked, 2 , "Two clicks recorded" );



#
# Delete the user.
#
deleteUser( $user, $username );


#
#  Count the pending adverts again, and make sure the advert has
# been removed.
#
my $fPending = $adverts->countPending();
ok( $fPending =~ /^([0-9]*)$/, "Final count of pending adverts is a number" );
is( $fPending, $cPending, "The new advert was deleted along with the user." );


#
#  Make sure that the advert details are lost.
#
$details = $adverts->getAdvert( $newID );
is( $details->{'link'}, undef, "Advert link is gone after it was deleted." );
is( $details->{'linktext'}, undef, "Advert link title is gone after it was deleted." );
is( $details->{'clicked'}, undef, "Advert click count is gone after it was deleted." );
