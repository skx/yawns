#!/usr/bin/perl -w -Ilib/
#
#  Test that the feed of comments on an weblog entry works correctly.
#
# $Id: yawns-weblog-comment-feed.t,v 1.5 2007-02-18 22:24:47 steve Exp $
#

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
BEGIN { use_ok( 'Yawns::User'); }
require_ok( 'Yawns::User' );
BEGIN { use_ok( 'Yawns::Weblog'); }
require_ok( 'Yawns::Weblog' );



#
#  Create a random new user.
#
my ($user, $username ) = setupNewUser();

#
#  A new user clearly has 0 weblog entries.
#
ok( $user->getWeblogCount() == 0, "New user has no weblogs" );

#
#  Create a weblog object
#
my $weblog = Yawns::Weblog->new( username => $username );

#
# Is the object the correct type?
#
isa_ok( $weblog, "Yawns::Weblog" );


#
#  Generate a random title for the new weblog entry.
#
my $title = join ( '', map {('a'..'z')[rand 26]} 0..17 );


#
#  Add a weblog entry.
#
my $id = $weblog->add( subject => $title,
	 	       body    => "<p>Here is my body</p><p>It is short</p>",
	               comments_allowed => 1 );



#
#  A new user clearly has 0 weblog entries.
#
ok( $user->getWeblogCount() == 1, "Weblog entry added successfully" );


#
#  Find the GID
#
my $gid = $weblog->getGID( username=> $username, id => $id );

ok( ( $gid > 0 ), "Found GID for new entry" );

#
#  Verify there are no comments on the weblog.
#
my $comments = Yawns::Comments->new( weblog => $gid, enabled => 1 );
isa_ok( $comments, "Yawns::Comments" );
my $c = $comments->get();
ok( (!defined( $c)) , "There are no comments upon the new weblog entry." );

#
#
# Get the comment feed.
#
my ($teaser, $feed ) = $comments->getCommentFeed( weblog => $gid  );

my @teasers = @$teaser;
my @feeds   = @$feed;

is( $#feeds,   -1, "A commentless weblog has no feed entries" );
is( $#teasers, -1, "A commentless weblog has no feed teasers" );

#
#  Now create a comment.
#
my $comment = Yawns::Comment->new();
isa_ok( $comment, "Yawns::Comment" );

#
# Add a new comment.
#
$id = $comment->add( weblog => $gid,
			title   => "Comment title",
			body    => "Comment body",
			username  => $username,
			oncomment => 0,
		      );

$c = $comments->get();
ok( defined($c) , "There is now a comment upon the new weblog entry." );

#
#  Get the feed again to make sure it is added.
#
($teaser, $feed ) = $comments->getCommentFeed( weblog => $gid );

@teasers = @$teaser;
@feeds   = @$feed;

is( $#feeds,   0, "A commented weblog has a feed entry" );
is( $#teasers, 0, "A commented weblog has a feed teaser" );


my $most_recent	= $feeds[0];
$title          = $most_recent->{'title'};
my $body	= $most_recent->{'body'};
is( $title, "Comment title", "The feed contains the correct comment title" );
is( $body,  "Comment body",  "The feed contains the correct comment body" );

$most_recent	= $teasers[0];
my $link	= $most_recent->{'link'};
ok ( $link =~ /users\/$username\/weblog\/1#comment_1/, "The feed contains the correct comment link" );

#
# Delete the comment
#
$comment->delete( weblog => $gid,
		  id      => $id );

$c = $comments->get();
ok( (!defined($c)) , "After comment deletion the comment count is zero" );


#
#  A deleted comment should mean there is no feed.
#
#
($teaser, $feed ) = $comments->getCommentFeed( weblog => $gid );

@teasers = @$teaser;
@feeds   = @$feed;

is( $#feeds,   -1, "A commentless weblog has no feed entries" );
is( $#teasers, -1, "A commentless weblog  has no feed teasers" );


#
#  Delete the random new user.
#
deleteUser( $user, $username );
