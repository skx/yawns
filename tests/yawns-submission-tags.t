#!/usr/bin/perl -w -I..
#
#  Test that we can tag submissions correctly.
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
BEGIN { use_ok( 'Yawns::Tags'); }
require_ok( 'Yawns::Tags' );



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
#  Count the articles which are currently pending.
#
my $articleCount = $queue->articleCount();
ok( defined( $articleCount),
    "Fetching the pending article count worked" );

#
#  Add a new article.
#
my $added = $queue->addArticle( title    => "Article title",
				bodytext => "Does this work?",
				ip       => "127.0.0.1",
				author   => $username,
			        quiet => 1  # Make sure we don't send mail.
			      );

#
#  See that it was addded properly.
#
my $newCount = $queue->articleCount();
is( $newCount, $articleCount+1, " After adding an article the count increases" );


#
#  Get a tag holder object.
#
my $tagHolder = Yawns::Tags->new();
isa_ok( $tagHolder, "Yawns::Tags" );


#
#  Make sure there are no tags on the new submission.
#
my $tags = $tagHolder->getTags( submission => $added );
ok( ! defined( $tags ), "The newly created submission has no tags" );


#
#  There might be a tag of the correct type already, but the count
# should be saved.
#
my $subTags     = $tagHolder->getAllTagsByType( 's' );
my $subTagCount = 0;
$subTagCount    = scalar(@$subTags) if defined( $subTags );


#
#  Add a tag and ensure it was created properly.
#
my $tagValue = join ( '', map {('a'..'z')[rand 26]} 0..17 );
$tagHolder->addTag( submission => $added, tag  => $tagValue );
$tags = $tagHolder->getTags( submission => $added );
ok( $tags, "After adding a tag there is now tag content" );


#
#  Reget all tags of type "submission".
#
#  The count should be one bigger.
#
$subTags           = $tagHolder->getAllTagsByType( 's' );
my $newSubTagCount = scalar(@$subTags);
is( $subTagCount +1 , $newSubTagCount , "After adding the count of submission tags is incremented" );



#
#  Reject the article
#
$queue->rejectArticle( $added );

#
#  Ensure the tag is gone.
#
$tags = $tagHolder->getTags( submission => $added );
ok( !defined($tags), "After deleting the submission the tag is gone too" );

#
#  Reget all tags of type "weblog".
#
$subTags        = $tagHolder->getAllTagsByType( 's' );
$newSubTagCount = 0;
$newSubTagCount = scalar(@$subTags) if ( defined( $subTags ) );
is( $subTagCount, $newSubTagCount, "And the count of submission tags is back to normal" );


is( $queue->articleCount(), $articleCount, " After deleting the submission the queue size is OK." );


#
#  Delete the random new user.
#
deleteUser( $user, $username );
