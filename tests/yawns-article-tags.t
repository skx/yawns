#!/usr/bin/perl -w -Ilib/
#
#  Test that we can add tags to an article, and retrieve them.
#
# $Id: yawns-article-tags.t,v 1.8 2007-02-09 13:54:54 steve Exp $
#

use strict;
use warnings;


use Test::More qw( no_plan );

#
#  Load the modules we use.
#
BEGIN { use_ok( 'Yawns::Article'); }
require_ok( 'Yawns::Article' );
BEGIN { use_ok( 'Yawns::Tags'); }
require_ok( 'Yawns::Tags' );


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
		  author => "Steve",
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
my $tags = Yawns::Tags->new();
isa_ok( $tags, "Yawns::Tags" );

#
# Get article tags.
#
my $set = $tags->getTags( article => 0 );
is( $set, undef, " The new article has no tags" );

#
#  Pick a random tag
#
my $new_tag = join ( '', map {('a'..'z')[rand 26]} 0..7 );

#
#  There might be a tag of the correct type already, but the count
# should be saved.
#
my $articleTags     = $tags->getAllTagsByType( 'a' );
my $articleTagCount = 0;
$articleTagCount    = scalar(@$articleTags) if defined( $articleTags );

#
#  Now add a tag.
#
$tags->addTag( article => 0,
               tag     => $new_tag );
$set = $tags->getTags( article => 0 );
ok( defined( $set ), "The article now has at least one tag" );


#
#  Reget all tags of type "article".
#
#  The count should be one bigger.
#
$articleTags           = $tags->getAllTagsByType( 'a' );
my $newArticleTagCount = scalar(@$articleTags);
is( ($articleTagCount +1 ), $newArticleTagCount, "After adding the count of article tags is incremented" );


#
# Get the title of the only comment
#
my $tag_name =  @$set[0]->{"tag"};
is( $tag_name, $new_tag, "The new tag is correct" );

#
# Now delete the article
#
$article->delete();

#
# Make sure the tags are gone now the article is deleted.
#
$set = $tags->getTags( article => 0 );
ok(!defined( $set ), "The deleted article has no tags." );

#
#  Reget all tags of type "weblog".
#
$articleTags        = $tags->getAllTagsByType( 'a' );
$newArticleTagCount = 0;
$newArticleTagCount = scalar(@$articleTags) if defined( $articleTags );

is( $articleTagCount, $newArticleTagCount, "And the count of article tags is back to normal" );
