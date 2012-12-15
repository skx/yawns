#!/usr/bin/perl -w -I..
#
#  Test that we can create, edit, and delete, an article comment.
#
# $Id: yawns-article-comment.t,v 1.7 2006-12-01 19:23:11 steve Exp $
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
# Get the new comment.
#
my $n = Yawns::Comment->new( article => 0,
			       id      => $id );
isa_ok( $n, "Yawns::Comment" );
my $stuff = $n->get();

is( $comment_title, $stuff->{'title'}, "And again the title matches" );
my $mail = $n->getEmail();
ok( defined( $mail ), "New comment has an email address defined." );
ok( length( $mail ), "New comment has non-empty email address" );
ok( $mail =~ /@/, "New comment has a valid looking email address" );


#
#  Now delete the comment.
#
$comment->delete( article => 0,
		  id      => $id );




$c = $comments->get();
ok( (!defined($c)) , "After the comment deletion the article comments are empty - as expected" );


# Now delete the article
#
$article->delete();

#
#  Delete the random new user.
#
deleteUser( $user, $username );
