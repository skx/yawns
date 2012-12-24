#!/usr/bin/perl -w -Ilib/
#
#  Test that we can work with bookmarks correctly.
#
# $Id: yawns-bookmarks.t,v 1.5 2006-11-21 10:27:44 steve Exp $
#

use Test::More qw( no_plan );

#
#  Utility methods for creating a new user.
#
require 'tests/user.utils';

#
#  Load the modules we use.
#
BEGIN { use_ok( 'Yawns::User'); }
require_ok( 'Yawns::User' );

BEGIN { use_ok( 'Yawns::Bookmarks'); }
require_ok( 'Yawns::Bookmarks' );


#
#  Create a new user.
#
my ($user, $username ) = setupNewUser();

#
#  Gain access to the bookmarks.
#
my $bookmarks = Yawns::Bookmarks->new( username => $username );
isa_ok( $bookmarks, "Yawns::Bookmarks" );


#
#  A new user has no bookmarks.
#
is( $bookmarks->count(), 0, " The new user has no bookmarks" );

#
#  Add a bookmark on article 40.
#
my $id1 = $bookmarks->add( article => 40 );
ok( $id1 >= 0 , " The new article bookmark has an ID : $id1" );

#
#  After adding the bookmark should be increased.
#
is( $bookmarks->count(), 1, " After adding a bookmark the count is increased" );


#
#  Add a bookmark on poll 1
#
my $id2 = $bookmarks->add( poll => 1 );
ok( $id2 >= 0 , " The new poll bookmark has an ID : $id2" );

#
#  After adding the new bookmark should be increased.
#
is( $bookmarks->count(), 2, " After adding a second bookmark the count is increased" );


#
#  We cannot test that ( $id2 == $id1 + 1) because a user might be adding
# a bookmark as we run this test.
#
ok( $id2 > $id1, " The second bookmark has a higher ID than the first" );

#
#  Now add a weblog bookmark.
#
my $id3 = $bookmarks->add( weblog => 1 );
ok( $id3 >= 0 , " The new weblog bookmark has an ID : $id3" );

#
#  After adding the new bookmark should now be three.
#
is( $bookmarks->count(), 3, " After adding a third bookmark the count is increased" );


#
#  Remove all the bookmarks we added.
#
#
$bookmarks->remove( id => $id1 );
$bookmarks->remove( id => $id2 );
$bookmarks->remove( id => $id3 );


#
#  Now remove the bookmarks.
#
is( $bookmarks->count(), 0, " After removing the bookmarks the count is zero" );



#
#  Add some random bookmarks
#
my $max	  = int(rand(20));
my $count = $max;
while( $count )
{
    $bookmarks->add( article => $count );
    $count -= 1;
}

#
#  Make sure the count is there.
#
is( $max, $bookmarks->count(), "Adding the random bookmarks increased the count" );


#
#  Delete the temporary user.
#
deleteUser( $user, $username );


#
#  When the user is deleted their bookmarks should be removed.
#
is( $bookmarks->count(), 0, " A deleted user has no bookmarks" );
