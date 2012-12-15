#!/usr/bin/perl -w -I..
#
#  Test that the hall of fame works as expected.
#

use strict;
use warnings;

use Test::More qw( no_plan );

#
#  Utility functions for creating a new user.
#
require 'tests/user.utils';

#
#  Load the modules.
#
BEGIN { use_ok( 'Yawns::Stats'); }
require_ok( 'Yawns::Stats' );
BEGIN { use_ok( 'Yawns::User'); }
require_ok( 'Yawns::User' );



#
#  Get the hall of fame.
#
my $hof = Yawns::Stats->new();
my $stats = $hof->getStats();

#
#  Get the user count.
#
my $userCount =  $stats->{"user_count"};

#
# Now we have the number of users.
#
ok( defined( $userCount ), "There is a user count" );
ok( $userCount . "" =~ /^[0-9]$/, " Which is a number" );

#
#  Create a random new user.
#
my ($user, $username ) = setupNewUser();

#
# We've created a new user - so see that the user count is updated.
#
$stats	     = $hof->getStats();
my $newCount = $stats->{"user_count"};

ok( defined( $newCount ), "After creating a new user there is still a user count" );
ok( $newCount . "" =~ /^[0-9]$/, " Which is a number" );
ok( $newCount == ( $userCount + 1 ), " Which is one more than before. [$newCount - $userCount]" );



#
#  Delete the random new user.
#
deleteUser( $user, $username );


#
#  Get the user count.
#
$stats	       = $hof->getStats();
my $postdelete = $stats->{"user_count"};

#
# Now we have the number of users.
#
ok( defined( $postdelete ), "After deleting the user there is still a user count" );
ok( $postdelete . "" =~ /^[0-9]$/, " Which is a number" );
ok( $postdelete = $userCount, " And matches what we started with" );
