#!/usr/bin/perl -w -I..
#
#  Test that we can interface with the poll submissions queue correctly.
#

use Test::More qw( no_plan );


#
#  Utility functions for creating a new user.
#
require 'tests/user.utils';

#
#  Load the modules we use.
#
BEGIN { use_ok( 'Yawns::Submissions'); }
require_ok( 'Yawns::Submissions' );



#
#  Create a random new user.
#
my ($user, $username ) = setupNewUser();

#
#  Gain access to the submissions queue.
#
my $queue = Yawns::Submissions->new( username => $username );
isa_ok( $queue, "Yawns::Submissions" );


#
#  Count the pending polls.
#
my $pollCount = $queue->pollCount();
ok( defined( $pollCount ), "Fetching the pending poll count worked" );
ok( $pollCount =~ /([0-9]+)/ , "The pending poll count is a number" );


#
#  Add a new poll
#
my @options = ( "Yes", "No", "Maybe" );
my $newPoll = $queue->addPoll( \@options,
			       author   => $username,
			       question => "Will this work?",
			       ip       => "127.0.0.1" ) ;

#
#  Count the number of pending polls and make sure they have increased by one.
#
my $newPollCount = $queue->pollCount();
is( $pollCount + 1, $newPollCount, "After adding a poll the pending count is correct" );

#
#  Now delete the poll submission.
#
$queue->rejectPoll( $newPoll );

#
#  Test that our pending poll count returned to what it was.
#
$newPollCount = $queue->pollCount();
is( $pollCount, $newPollCount, "After rejecting the poll the pending count is correct" );


#
#  Delete the random new user.
#
deleteUser( $user, $username );
