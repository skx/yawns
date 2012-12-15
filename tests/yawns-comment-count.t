#!/usr/bin/perl -w -I..
#
#  Test that we can keep track of comment counts.
#
# $Id: yawns-comment-count.t,v 1.5 2006-05-09 14:32:04 steve Exp $
#

use Test::More qw( no_plan );

#
#  Utility functions for creating a new user.
#
require 'tests/user.utils';


#
#  Load the module.
#
BEGIN { use_ok( 'Yawns::User'); }
require_ok( 'Yawns::User' );
BEGIN { use_ok( 'Yawns::Users'); }
require_ok( 'Yawns::Users' );
BEGIN { use_ok( 'Yawns::Comment'); }
require_ok( 'Yawns::Comment' );
BEGIN { use_ok( 'Yawns::Comments'); }
require_ok( 'Yawns::Comments' );
BEGIN { use_ok( 'Yawns::Stats'); }
require_ok( 'Yawns::Stats' );


#
# Hall of fame handle.
#
my $hof = Yawns::Stats->new();
isa_ok( $hof, "Yawns::Stats" );


#
#  Create a random new user.
#
my ($user, $username ) = setupNewUser();


#
#  Get the current stats.
#
my $stats = $hof->getStats();
my $commentCount = $stats->{'comment_count'};
ok( defined( $commentCount ), " Found the comment count in the HOF" );
ok( $commentCount =~ /^([0-9]+)$/, " Which is a number" );


#
#  Find out how many comments the user has posted.
#
my $count = $user->getCommentCount();
ok( $count == 0, "The new user hasn't posted any comments" );

#
#  Now post a comment.
#
my $comment = Yawns::Comment->new();

#
# Add a new comment.
#
my $id = $comment->add( article => 2,
			title   => "Comment title",
			body    => "Comment body",
			username  => $username,
			oncomment => 0,
		      );

#
#  Now that the user has posted a comment make sure we reflect that.
#
$count = $user->getCommentCount();
ok( $count == 1, "The new user has now posted a comment: $count." );


#
#  Get the current stats.
#
my $newStats = $hof->getStats();
my $newCommentCount = $newStats->{'comment_count'};
ok( defined( $newCommentCount ), " Found the updated comment count in the HOF" );
ok( $newCommentCount =~ /^([0-9]+)$/, " Which is a number" );
is( $newCommentCount, $commentCount + 1, " Is one more than before" );


#
#  Now delete the comment.
#
$comment->delete( article => 2,
		  id      => $id );



#
#  Now that the user has posted a comment make sure we reflect that.
#
$count = $user->getCommentCount();
ok( $count == 0, "The new user has no comments after it has been deleted: $count" );



#
#  Get the current stats.
#
$newStats = $hof->getStats();
$newCommentCount = $newStats->{'comment_count'};
ok( defined( $newCommentCount ), " Found the updated comment count in the HOF" );
ok( $newCommentCount =~ /^([0-9]+)$/, " Which is a number" );
is( $newCommentCount, $commentCount, " Is back to what it was before" );


#
#  Delete the random new user.
#
deleteUser( $user, $username );

