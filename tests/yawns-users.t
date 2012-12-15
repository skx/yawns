#!/usr/bin/perl -w -I..
#
#  Test that the user counting works.
#
# $Id: yawns-users.t,v 1.9 2006-11-20 16:21:17 steve Exp $
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

BEGIN { use_ok( 'Yawns::Stats'); }
require_ok( 'Yawns::Stats' );


#
#  Get the count of users.
#
my $users = Yawns::Users->new();
isa_ok( $users, "Yawns::Users" );

my $count = $users->count();
ok( $count, "Found user count $count" );


#
#  Get the hall of fame.
#
my $hof = Yawns::Stats->new();
isa_ok( $hof, "Yawns::Stats" );

#
#  Get the user count from the HOF
#
my $stats     = $hof->getStats();
my $userCount = $stats->{"user_count"};
ok( defined( $userCount ), "HOF has a user count" );
is( $userCount, $count, "HOF agrees with user count" );

#
#  Create a random new user.
#
my ($user, $username, $email ) = setupNewUser();

#
#  Now verify we can get the newly created users data.
#
my $userinfo = $user->get();
ok( defined( $userinfo->{'username'} ), "Username is defined" );


#
#  Now count the users again.
#
my $newCount = $users->count();

ok( $newCount, "Found new user count : $newCount" );

ok( ( ($count+1) == $newCount), "And it matches what we expect - ($newCount) = ($count+1)" );



#
#  Get the user count from the HOF
#
$stats     = $hof->getStats();
my $newUserCount = $stats->{"user_count"};
ok( defined( $newUserCount ), "HOF still has a user count" );
is( $newUserCount, $userCount+1, "HOF agrees with user count" );


#
#  Ensure the user is in the most recent users data
#
my $data	= $users->getRecent(0);
ok( defined( $data ), "The recent user data is non-empty" );

my @usersRecentlyJoined  = @$data;
ok( ( $#usersRecentlyJoined+ 1) > 0, " The recently joined user count is non-zero" );

my $most_recent	= @$data[$#usersRecentlyJoined]->{"username"};

ok( $most_recent eq $username, " The most recent user is the one we added!" );


#
#  Attempt to find the user, both by name and email.
#
my ( $realusername, $realemail ) = $users->findUser( username => $username );
is( $realusername, $username, " Found username by username search" );
is( $realemail, $email, " Found email by username search" );

#
#  Again searching by email address.
#
( $realusername, $realemail ) = $users->findUser( email => $email );
is( $realusername, $username, " Found username by email search" );
is( $realemail, $email, " Found email by email search" );


#
#  Delete the random new user.
#
deleteUser( $user, $username );

#
#  Find the user by email address now it is deleted - should fail.
#
( $realusername, $realemail ) = $users->findUser( email => $email );
is( $realusername, undef, " Once deleted finding username by email search fails" );
is( $realemail, undef, " Once deleted finding username by email search fails" );

#
#  Find the user by username search - now it is deleted it should fail.
#
( $realusername, $realemail ) = $users->findUser( username => $username  );
is( $realusername, undef, " Once deleted finding username by username search fails" );
is( $realemail, undef, " Once deleted finding username by username search fails" );



my $lastCount = $users->count();

ok( $lastCount, "After deleting there is still a usercount" );
ok( $lastCount == $count, " Which is what we started with" );
ok( $lastCount == ( $newCount - 1 ), " One less than what we had when we added a user." );


#
#  Get the user count from the HOF
#
$stats     = $hof->getStats();
$newUserCount = $stats->{"user_count"};
ok( defined( $newUserCount ), "HOF still has a user count" );
is( $newUserCount, $userCount, "HOF count is now back to what we started with." );
