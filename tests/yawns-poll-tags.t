#!/usr/bin/perl -w -I..
#
#  Test that we can add tags to a poll, and retrieve them.
#
# $Id: yawns-poll-tags.t,v 1.3 2007-02-09 13:54:54 steve Exp $
#

use strict;
use warnings;


use Test::More qw( no_plan );

#
#  Utility functions for creating a new user.
#
require 'tests/user.utils';

#
#  Load the modules we use.
#
BEGIN { use_ok( 'Yawns::Poll'); }
require_ok( 'Yawns::Poll' );
BEGIN { use_ok( 'Yawns::Polls'); }
require_ok( 'Yawns::Polls' );
BEGIN { use_ok( 'Yawns::Tags'); }
require_ok( 'Yawns::Tags' );


#
#  Create a random new user.
#
my ($user, $username, $email, $password ) = setupNewUser();

#
# Ensure poll 0 doesn't exist.
#
my $polls = Yawns::Polls->new();
$polls->delete( id => 0 );

#
# Is the object the correct type?
#
isa_ok( $polls, "Yawns::Polls" );

#
#  Now add a new poll
#
my @answers = ( "Foo", "Bar", "Baz" );
my $id = $polls->add( question => "Test?",
		      author   => $username,
		      answers  => \@answers,
		      id       => 0,
	     );

ok( $id == 0, "Newly added poll is poll zero" );


#
#  Now create a tag accessor
#
my $tagHolder = Yawns::Tags->new();
isa_ok( $tagHolder, "Yawns::Tags" );


#
#  Ensure there are no tags on the poll
#
my $tags = $tagHolder->getTags( poll => 0 );
ok( ! defined( $tags ), "The newly created poll has no tags" );

#
#  There might be a tag of the correct type already, but the count
# should be saved.
#
my $pollTags     = $tagHolder->getAllTagsByType( 'p' );
my $pollTagCount = 0;
$pollTagCount    = scalar(@$pollTags) if defined( $pollTags );


#
#  Add a random tag
#
my $tagValue = join ( '', map {('a'..'z')[rand 26]} 0..17 );
$tagHolder->addTag( poll => 0,
                    tag  => $tagValue );

#
#  Now there should be new tags.
#
$tags = $tagHolder->getTags( poll => 0 );
ok( $tags, "After adding a tag there is now tag content" );

#
#  Reget all tags of type "poll".
#
#  The count should be one bigger.
#
$pollTags           = $tagHolder->getAllTagsByType( 'p' );
my $newPollTagCount = scalar(@$pollTags);
is( ($pollTagCount +1 ), $newPollTagCount, "After adding the count of poll tags is incremented" );


#
#  Delete the poll
#
$polls->delete( id => 0 );


#
#  Now the tags should be empty.
#
$tags = $tagHolder->getTags( poll => 0 );
ok( !defined $tags, "After deleting the poll there are no tags remaining" );

#
#  Reget all tags of type "poll".
#
$pollTags        = $tagHolder->getAllTagsByType( 'p' );
$newPollTagCount = 0;
$newPollTagCount = scalar(@$pollTags) if defined( $pollTags );

is( $pollTagCount, $newPollTagCount, "And the count of poll tags is back to normal" );


#
#  Delete the random new user.
#
deleteUser( $user, $username );

