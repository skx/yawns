#!/usr/bin/perl -w -I..
#
#  Test that we can create, and delete, a poll comment.
#
# $Id: yawns-poll-comment.t,v 1.8 2006-12-01 19:23:11 steve Exp $
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
BEGIN { use_ok( 'Yawns::Comment'); }
require_ok( 'Yawns::Comment' );
BEGIN { use_ok( 'Yawns::Comments'); }
require_ok( 'Yawns::Comments' );
BEGIN { use_ok( 'Yawns::Poll'); }
require_ok( 'Yawns::Poll' );
BEGIN { use_ok( 'Yawns::Polls'); }
require_ok( 'Yawns::Polls' );



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
# Get the comments on poll zero.
#
my $comments = Yawns::Comments->new( poll => 0, enabled => 1 );
isa_ok( $comments, "Yawns::Comments" );
my $c = $comments->get();
ok( (!defined( $c)) , "There are no comments upon poll 0" );

#
# The poll object should be able to verify this.
#
my $pol = Yawns::Poll->new( id => 0 );
isa_ok( $pol, "Yawns::Poll" );
ok( $pol->commentCount() == 0, " The Yawns::Poll object has no comments" );


ok( $pol->getTitle() eq "Test?", " The Yawns::Poll object has the correct title" );

#
#  Now create a comment.
#
my $comment = Yawns::Comment->new();
isa_ok( $comment, "Yawns::Comment" );

#
# Add a new comment.
#
my $comment_id = $comment->add( poll	  => 0,
				title	  => "Comment title",
				body	  => "Comment body",
				username  => $username,
				oncomment => 0,
				force     => 1,
			      );
ok( $comment_id == 1, "First comment on poll zero has ID 1" );

#
# Get the comments on poll zero, make sure it was added.
#
$c = $comments->get();
ok( (defined( $c)) , "There is now at least one comment upon poll 0" );


#
# Cross-check with yawns::Poll
#
ok( $pol->commentCount() eq 1, "The Yawns::Poll object has a comment now, too." );


#
# Get the title of the only comment
#
my $comment_title =  @$c[0]->{"title"};

#
# Make sure it is OK.
#
ok( (defined( $comment_title )), "Comment title is defined" );

#
# And matches what we expect
#
ok( $comment_title eq "Comment title", "Comment matches what we expect" );



#
#  Now delete the comment.
#
$comment->delete( poll => 0,
		  id      => $comment_id );


#
# Cross-check with yawns::Poll
#
ok( $pol->commentCount() eq 0, "The Yawns::Poll says no comments after the poll has been deleted" );


#
#  Delete the random new user.
#
deleteUser( $user, $username );
