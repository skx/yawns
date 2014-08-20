#!/usr/bin/perl -w -Ilib/
#
#  Test that we can interface with the submissions queues correctly.
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
#  Test we have no articles for the user.
#
is( 0, $queue->articleCountByUsername(), " After creation the new user has no pending submissions.");


#
#  Count the articles which are currently pending.
#
my $articleCount = $queue->articleCount();
ok( defined( $articleCount), "Fetching the pending article count worked" );

#
#  Add a new article.
#
my $added = $queue->addArticle( title    => " Article title",
				bodytext => "Does this work?",
				ip       => "127.0.0.1",
				author   => $username,
			        quiet => 1  # Make sure we don't send mail.
			      );

ok( $added, "Addition returned something" );
ok( $added =~ /([0-9]+)/, "Which is a number: $added" );

#
#  See that it was addded properly.
#
my $newCount = $queue->articleCount();
is( $newCount, $articleCount+1, " After adding an article the count increases" );

#
#  After the addition the user should have an article under their username.
#
is( $queue->articleCountByUsername(), 1, "After submission the user has an article pending" );


#
#  Get the article.
#
my %new = $queue->getSubmission( $added );
is( $new{'author'}, $username, "The new article submission has the correct author" );
is( $new{'title'}, "Article title", "The new article submission has the correct title" );



#
#  Edit the title
#
$queue->updateSubmission( title    => " Updated article title",
			  bodytext => "Does this work?",
			  id       => $added,
			  author   => $username,
			  tags     => "",
			  );


#
#  Make sure the edit worked.
#
#
%new = $queue->getSubmission( $added );
is( $new{'author'}, $username, "The edited submision still has the correct author" );
is( $new{'title'}, "Updated article title", "The edited submission has the updated title" );



#
#  Now create a second user.
#
my ($user2, $username2 ) = setupNewUser();


#
#  The second user has no articles.
#
my $queue2 = Yawns::Submissions->new( username => $username2 );
is( $queue2->articleCountByUsername(), 0, "The second user has no articles." );

#
#  Assign the submission to the new user.
#
$queue->updateSubmission( title    => "Updated article title again",
			  bodytext => "This will work?",
			  id       => $added,
			  author   => $username2,
			  tags     => "",
			  );

#
#  So now the new user has a single submission, and the old
# user should have none.
#
is( $queue2->articleCountByUsername(), 1, "And the new recipient owns it." );
is( $queue->articleCountByUsername(), 0, "After giving it away the original user has no submission: XXX." );


#
#  Get the article to make sure it has been assigned.
#
%new = $queue->getSubmission( $added );
is( $new{'author'}, $username2, "The given submission show the new owner correctly." );


#
#  Give the article back
#
$queue->updateSubmission( title    => "Updated article title",
			  bodytext => "Does this work?",
			  id       => $added,
			  author   => $username,
			  tags     => "",
			  );

%new = $queue->getSubmission( $added );
is( $new{'author'}, $username, "The restored submission show the original owner correctly." );


#
#  Now the counts should be reversed.
#
is( $queue->articleCountByUsername(), 1, "After restoring it the original user has a submission" );
is( $queue2->articleCountByUsername(), 0, "After restoring it the new user has no submissions again" );

#
#  delete the second user.
#
deleteUser( $user2, $username2 );


#
#  Reject the article
#
$queue->rejectArticle( $added );

#
#  Make sure the user has no pending articles
#
is( 0, $queue->articleCountByUsername(), " After deletion the user has no pending articles" );

is( $queue->articleCount(), $articleCount, " After deleting the article submission the count is back to the starting value." );



#
#  Delete the random new user.
#
deleteUser( $user, $username );
