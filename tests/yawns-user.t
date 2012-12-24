#!/usr/bin/perl -w -Ilib/
#
#  Test that we can create, and delete, a user.
#
# $Id: yawns-user.t,v 1.12 2006-11-20 16:21:17 steve Exp $
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
my ($user, $username, $email, $password ) = setupNewUser();

#
#  Now verify we can get the newly created users data.
#
my $userinfo = $user->get();
ok( defined( $userinfo ), "User information is defined" );


#
#  Does the username match?
#
ok( $userinfo->{'username'}, "User information has a username" );
ok( $userinfo->{'username'} eq $username, "Which matches what we expect" );

#
#  And the email address?
#
ok( $userinfo->{'realemail'}, "User information has an email address" );
ok( $userinfo->{'realemail'} eq $email, "Which matches what we set" );

#
#  Test that the user can login.
#
my ($success, $suspended ) = undef;
($success, $suspended ) = $user->login( username => $username,
					password => "test" );
ok( $success == 0, " Login with incorrect password fails. As expected" );


($success, $suspended ) = $user->login( password => "test" );
ok( $success == 0, " Login with an empty username fails. As expected" );

($success, $suspended ) = $user->login( username => "test" );
ok( $success == 0, " Login with an empty password fails. As expected" );



($success, $suspended ) = $user->login( username => $username,
					password => $password );
ok( $success eq $username, "Login with correct password works OK." );
ok( $suspended eq 0, " And the user isn't suspended" );


#
#  Change the user's password to repeat the tests.
#
$user->setPassword( $password . $password );
($success, $suspended ) = $user->login( username => $username,
					password => $password );
ok( $success == 0, " Login after changing password fails." );


($success, $suspended ) = $user->login( password => "test" );
ok( $success == 0, " Login with an empty username fails. As expected" );

($success, $suspended ) = $user->login( username => "test" );
ok( $success == 0, " Login with an empty password fails. As expected" );


($success, $suspended ) = $user->login( username => $username,
					password => $password . $password );
ok( $success eq $username, "Login with correct password works OK." );
ok( $suspended eq 0, " And the user isn't suspended" );





$user->suspend( reason => "Test" );
($success, $suspended ) = $user->login( username => $username,
					password => $password . $password );
ok( $success eq $username, " After the suspension things work OK" );
ok( $suspended eq 1, " After the suspension things work OK" );

#
#  Delete the random new user.
#
deleteUser( $user, $username );
