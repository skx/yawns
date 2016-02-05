#!/usr/bin/perl -w -Ilib/
#
#  Test that we can create, edit, and delete, an article.
#
# $Id: yawns-article.t,v 1.7 2006-06-06 21:48:57 steve Exp $
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
BEGIN { use_ok( 'Yawns::Article'); }
require_ok( 'Yawns::Article' );
BEGIN { use_ok( 'Yawns::User'); }
require_ok( 'Yawns::User' );


#
#  Create a random new user.
#
my ($user, $username ) = setupNewUser();


#
#  Test that the user hasn't authored any articles.
#
is( $user->getArticleCount(), 0, "New user hasn't created any articles" );


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
#  Test that the user has now authored a single article.
#
is( $user->getArticleCount(), 1, "New user has now authored an article" );

#
# Re-get the title and verify it is OK.
#
$title = $article->getTitle();
ok( defined( $title ), "Newly created article 0 has a title" );
ok( $title eq $new_title, "Newly created article 0 has the correct title" );


#
# Edit the title.
#
$article->edit( id => 0,
		title => "Editted Title",
		body  => "<p>This is my lead text</p>\n<p>This is my body</p>",
		author => $username,
		topic  => "News" );


#
# Get the article title and verify it doesn't exist.
#
$title = $article->getTitle();
ok( defined( $title ), "Editted article has a title." );
ok( $title eq "Editted Title", "Editted article has the title we expect '$title'." );


#
# Now delete the article
#
$article->delete();

#
#  Test that the user has no longer authored an article.
#
is( $user->getArticleCount(), 0, "New user has got no authored articles" );


#
# Get the article title and verify it doesn't exist.
#
$title = $article->getTitle();
ok( !defined( $title ), "Deleted article 0 has no title again." );

#
# Get the article data, and verify the body and topic is empty.
#
$data = $article->get();
ok( !defined( $article->{article_body} ), "Deleted article 0 has no body again." );
ok( !defined( $article->{topic} ), "Deleted article 0 has no topic again." );




#
#  Delete the random new user.
#
deleteUser( $user, $username );
