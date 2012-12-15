#!/usr/bin/perl -w -I..
#
#  Test that we can work with user preferences correctly.
#
# $Id: yawns-preferences.t,v 1.3 2007-02-02 00:01:01 steve Exp $
#

use Test::More qw( no_plan );

#
#  Utility methods for creating a new user.
#
require 'tests/user.utils';

#
#  Load the modules we use.
#
BEGIN { use_ok( 'Yawns::Preferences'); }
require_ok( 'Yawns::Preferences' );
BEGIN { use_ok( 'Yawns::User'); }
require_ok( 'Yawns::User' );


#
#  Create a new user.
#
my ($user, $username ) = setupNewUser();

#
# Gain access to the users preferences
#
my $prefs = Yawns::Preferences->new( username => $username );
isa_ok( $prefs, "Yawns::Preferences" );

#
#  Find all preferences
#
my $all   = $prefs->getAll();
my $count = scalar keys %$all;
is( $count, 0 , "There are no keys set" );


#
#  Generate a key and value to set
#
my $key = join ( '', map {('a'..'z')[rand 26]} 0..17 );
my $val = join ( '', map {('a'..'z')[rand 26]} 0..17 );

#
#  Now set a key
#
$prefs->setPreference( $key, $val );

#
#  Make sure we can get it
#
is( $val, $prefs->getPreference( $key ), "Found random key we setup" );


#
#  Now set the key to something different to make sure caching works.
#
$prefs->setPreference( $key, $val . "skx" );

#
#  Make sure we can get it
#
is( $val . "skx", $prefs->getPreference( $key ), "Found random key we setup after updating" );

#
#  So the count of keys should have increased.
#
$all   = $prefs->getAll();
$count = scalar keys %$all;
is( $count, 1 , "There are is one key set" );


#
#  Delete the temporary user.
#
deleteUser( $user, $username );


#
#  Now make sure there are no keys present
#
$all   = $prefs->getAll();
$count = scalar keys %$all;
is( $count, 0 , "There are no keys set" );
