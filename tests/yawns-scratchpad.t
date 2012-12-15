#!/usr/bin/perl -w -I..
#
#  Test that we can get, and set a scratchpad's contents.
#

use Test::More qw( no_plan );

#
#  Utility functions for creating a new user.
#
require 'tests/user.utils';


BEGIN { use_ok( 'Yawns::Scratchpad'); }
require_ok( 'Yawns::Scratchpad' );


#
#  Create a random new user.
#
my ($user, $username ) = setupNewUser();

#
# Now we can work with the scratchpad.
#
my $scratchpad = Yawns::Scratchpad->new( username => $username );
isa_ok( $scratchpad, "Yawns::Scratchpad" );

#
# New user, so scratchpad should be empty.
#
ok( !(length( $scratchpad->get() ) ), "Newly created user has an empty scratchpad." );


#
#  Set a public scratchpad.
#
my $text = "boo";
$scratchpad->set( $text, "public" );

ok( defined( $scratchpad->get() ), "After setting the scratchpad it is defined." );

ok( $scratchpad->get() eq $text, "And has the content we care about." );
is( $scratchpad->isPrivate(), 0 , "And is public as we expect." );



#
#  Now set a private scratchpad.
#
$scratchpad->set( $username, "private" );

ok( defined( $scratchpad->get() ), "After update the scratchpad it is still defined." );

ok( $scratchpad->get() eq $username, "And has the updated content we expect." );
is( $scratchpad->isPrivate(), 1 , "And is private as we expect." );




#
#  Delete the random new user.
#
deleteUser( $user, $username );


ok( !(length $scratchpad->get()), "Deleted user has no scratchpad" );
