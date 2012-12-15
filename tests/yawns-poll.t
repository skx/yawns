#!/usr/bin/perl -w -I..
#
#  Test that we may create and access a poll.
#
# $Id: yawns-poll.t,v 1.4 2005-11-28 13:31:00 steve Exp $
#

use strict;
use warnings;


use Test::More qw( no_plan );

#
#  Load the modules we use.
#
BEGIN { use_ok( 'Yawns::Poll'); }
require_ok( 'Yawns::Poll' );
BEGIN { use_ok( 'Yawns::Polls'); }
require_ok( 'Yawns::Polls' );


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
		      author   => "Steve",
		      answers  => \@answers,
		      id       => 0,
	     );

ok( $id == 0, "Newly added poll is poll zero" );


my $pol = Yawns::Poll->new( id => 0 );
isa_ok( $pol, "Yawns::Poll" );
ok( $pol->getTitle() eq "Test?", " The Yawns::Poll object has the correct title" );

#
#  Make sure the new poll has no votes.
#
my $voteCount = $pol->getVoteCount();
ok( $voteCount == 0, "The new poll has zero votes upon it." );

#
#  Now vote.
#
$pol->vote( ip_address => "127.0.0.1",
	    choice     => 1 );

$voteCount = $pol->getVoteCount();
ok( $voteCount == 1, "After voting the poll has a vote upon it" );


#
#  Vote again from a different IP address.
#
$pol->vote( ip_address => "127.0.0.2",
	    choice     => 1 );

$voteCount = $pol->getVoteCount();
ok( $voteCount == 2, "After voting again poll has two votes upon it" );



#
#  Now change both our votes to different choices.
#
$pol->vote( ip_address => "127.0.0.2",
	    choice     => 2 );
$pol->vote( ip_address => "127.0.0.1",
	    choice     => 2 );

$voteCount = $pol->getVoteCount();
ok( $voteCount == 2, "After changing our votes the poll still has only two votes upon it" );


#
# Delete the poll
#
$polls->delete( id => 0 );


#
# Ensure there are no votes left.
#
$voteCount = $pol->getVoteCount();
ok( $voteCount == 0, "The deleted poll has zero votes upon it." );

#
# And the title is gone now it is deleted.
#
ok( !defined($pol->getTitle() ), "The deleted poll has no title." );
