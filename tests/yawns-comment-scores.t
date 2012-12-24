#!/usr/bin/perl -w -Ilib/
#
#  Test that we can modify the score of a comment.
#
# $Id: yawns-comment-scores.t,v 1.5 2006-12-01 19:23:11 steve Exp $
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
#  Get the initial score.
#
my $score = $comment->getScore( 0, $id, 'a');
is( $score, 5, "The new comment has a score of five" );


#
#  Decrease the score.
#
$comment->report( article => 0,
		  id => $id );

#
#  Make sure it worked.
#
my $dscore = $comment->getScore( 0, $id, 'a');
is( $dscore, 4, "The reported comment has a score of four." );

#
#  Decrease the score to zero by faking a report by the site
# administrator.
#
my $session = Singleton::Session->instance();
$comment->report( article => 0,
		  id => $id );

my $ascore = $comment->getScore( 0, $id, 'a');
ok( $ascore < $dscore, "The reported comment has a lower score." );

#
#  Now delete the comment.
#
$comment->delete( article => 0,
		  id      => $id );

#
#  A deleted comment has no score!
#
$score = $comment->getScore( 0, $id, 'a' );
is( $score, undef, "The deleted comment has no score." );


# Now delete the article
#
$article->delete();

#
#  Delete the random new user.
#
deleteUser( $user, $username );
