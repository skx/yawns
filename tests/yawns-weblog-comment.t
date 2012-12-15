#!/usr/bin/perl -w -I..
#
#  Test that we can work with comments on weblogs correctly.
#
# $Id: yawns-weblog-comment.t,v 1.7 2006-12-01 19:23:11 steve Exp $
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
# Now add a comment
#

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
# Delete the comment
#
$comment->delete( weblog => $gid,
		  id      => $id );

$c = $comments->get();
ok( (!defined($c)) , "After comment deletion the comment count is zero" );



#
#  Delete the random new user.
#
deleteUser( $user, $username );
