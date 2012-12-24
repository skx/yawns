#!/usr/bin/perl -w -Ilib/
#
#  Test that the feed of comments on an article works correctly.
#
# $Id: yawns-article-comment-feed.t,v 1.5 2007-02-18 22:24:47 steve Exp $
#

use strict;
use warnings;


use Test::More qw( no_plan );

#
#  Utility functions for creating a new user.
#
require 'tests/user.utils';


#
#  Load the module.
#
BEGIN { use_ok( 'Yawns::Article'); }
require_ok( 'Yawns::Article' );
BEGIN { use_ok( 'Yawns::Comment'); }
require_ok( 'Yawns::Comment' );
BEGIN { use_ok( 'Yawns::Comments'); }
require_ok( 'Yawns::Comments' );

#
#  Create a random new user.
#
my ($user, $username, $email, $password ) = setupNewUser();

#
# Get article 0 and verify it doesn't exist.
#
my $article = Yawns::Article->new( id => 0 );

#
# Is the object the correct type?
#
isa_ok( $article, "Yawns::Article" );

#
# Get the article title and verify it doesn't exist.
#
my $title = $article->getTitle();
ok( !defined( $title ), "Article 0 has no title" );

#
# Get the article data, and verify the body and topic is empty.
#
my $data = $article->get();
ok( !defined( $article->{article_body} ), "Article 0 has no body" );
ok( !defined( $article->{topic} ), "Article 0 has no topic" );


#
# Now create the new article
#
my $new_title = "This is my title";

$article->create( id    => 0,
		  title => $new_title,
		  body  => "<p>This is my lead text</p>\n<p>This is my body</p>",
		  author => $username,
		  topic  => "News" );

#
# Re-get the title and verify it is OK.
#
$title = $article->getTitle();
ok( defined( $title ), "Newly created article 0 has a title" );
ok( $title eq $new_title, "Newly created article 0 has the correct title" );


#
# Get the comments on the article - make sure there are none.
#
my $comments = Yawns::Comments->new( article => 0 );
isa_ok( $comments, "Yawns::Comments" );
my $c = $comments->get();
ok( (!defined( $c)) , "There are no comments upon article 0" );

#
# Get the comment feed.
#
my ($teaser, $feed ) = $comments->getCommentFeed( article => 0 );

my @teasers = @$teaser;
my @feeds   = @$feed;

is( $#feeds,   -1, "A commentless article has no feed entries" );
is( $#teasers, -1, "A commentless article has no feed teasers" );

#
#  Now create a comment.
#
my $comment = Yawns::Comment->new();
isa_ok( $comment, "Yawns::Comment" );

#
# Add a new comment.
#
my $id = $comment->add( article => 0,
			title   => "Comment title",
			body    => "Comment body",
			username  => $username,
			oncomment => 0,
		      );



$c = $comments->get();
ok( (defined($c)) , "There is now at least one comment upon article 0" );


#
#  Get the updated feed and make sure it contains our comment.
#
#
($teaser, $feed ) = $comments->getCommentFeed( article => 0 );

@teasers = @$teaser;
@feeds   = @$feed;

is( $#feeds,   0, "A commented article has a feed entry" );
is( $#teasers, 0, "A commented article has a feed teaser" );


my $most_recent	= $feeds[0];
$title		= $most_recent->{'title'};
my $body	= $most_recent->{'body'};
is( $title, "Comment title", "The feed contains the correct comment title" );
is( $body,  "Comment body",  "The feed contains the correct comment body" );

$most_recent	= $teasers[0];
my $link	= $most_recent->{'link'};
ok ( $link =~ /\/articles\/0#comment_1/, "The feed contains the correct comment link" );

#  Now delete the comment.
#
$comment->delete( article => 0,
		  id      => $id );

#
#  A deleted comment should mean there is no feed.
#
#
($teaser, $feed ) = $comments->getCommentFeed( article => 0 );

@teasers = @$teaser;
@feeds   = @$feed;

is( $#feeds,   -1, "A commentless article has no feed entries" );
is( $#teasers, -1, "A commentless article has no feed teasers" );


#
# Now delete the article
#
$article->delete();

#
#  Delete the random new user.
#
deleteUser( $user, $username );
