#!/usr/bin/perl -w -I..
#
#  Test that we can access and edit the user preferences.
#
# $Id: yawns-user-prefs.t,v 1.7 2007-02-02 03:05:58 steve Exp $
#

use Test::More qw( no_plan );

#
#  Utility functions for creating a new user.
#
require 'tests/user.utils';


#
#  Load the modules we use.
#
BEGIN { use_ok( 'Yawns::User'); }
require_ok( 'Yawns::User' );

BEGIN { use_ok( 'Yawns::Users'); }
require_ok( 'Yawns::Users' );



#
#  Create a random new user.
#
my ($user, $username ) = setupNewUser();

#
#  Now verify we can get the newly created users data.
#
my $userinfo = $user->get();
ok( defined( $userinfo ), "User information is defined" );


#
#  Poll viewing.
#
is( $userinfo->{'polls'}, 1, " User sees polls by default" );
$user->savePreferences( view_polls => 0 );
$userinfo = $user->get();
is( $userinfo->{'polls'}, 0, " User is no longer viewing polls" );
$user->savePreferences( view_polls => 0 );
$userinfo = $user->get();
is( $userinfo->{'polls'}, 0, " User now has no more polls" );



#
#  Adverts.
#
is( $userinfo->{'viewadverts'}, 1, " User gets adverts by default" );
$user->savePreferences( view_adverts => 0 );
$userinfo = $user->get();
is( $userinfo->{'viewadverts'}, 0, " User is no longer viewing adverts" );
$user->savePreferences( view_adverts => 1 );
$userinfo = $user->get();
is( $userinfo->{'viewadverts'}, 1, " User now has adverts again" );


#
#  Blog reading.
#
is( $userinfo->{'blogs'}, 1, " User sees blogs by default" );
$user->savePreferences( view_blogs => 0 );
$userinfo = $user->get();
is( $userinfo->{'blogs'}, 0, " User is no longer viewing blogs" );
$user->savePreferences( view_blogs => 0 );
$userinfo = $user->get();
is( $userinfo->{'blogs'}, 0, " User now has no more blogs" );


#
#  Delete the random new user.
#
deleteUser( $user, $username );

