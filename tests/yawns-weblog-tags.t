#!/usr/bin/perl -w -Ilib/
#
#  Test that we can work with tags on weblogs correctly.
#
# $Id: yawns-weblog-tags.t,v 1.3 2007-02-09 13:54:54 steve Exp $
#

use Test::More qw( no_plan );

#
#  Utility functions for creating a new user.
#
require 'tests/user.utils';

#
#  Load the modules we use.
#
BEGIN { use_ok( 'Yawns::Tags'); }
require_ok( 'Yawns::Tags' );
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
#  Get a tag holder object.
#
my $tagHolder = Yawns::Tags->new();
isa_ok( $tagHolder, "Yawns::Tags" );


#
#  Make sure there are no tags on the new weblog.
#
my $tags = $tagHolder->getTags( weblog => $gid );
ok( ! defined( $tags ), "The newly created weblog entry has no tags" );


#
#  There might be a tag of the correct type already, but the count
# should be saved.
#
my $weblogTags     = $tagHolder->getAllTagsByType( 'w' );
my $weblogTagCount = 0;
$weblogTagCount    = scalar(@$weblogTags) if defined( $weblogTags );

#
#  Add a tag and ensure it was created properly.
#
my $tagValue = join ( '', map {('a'..'z')[rand 26]} 0..17 );
$tagHolder->addTag( weblog => $gid,
                    tag  => $tagValue );
$tags = $tagHolder->getTags( weblog => $gid );
ok( $tags, "After adding a tag there is now tag content" );

#
#  Reget all tags of type "weblog".
#
#  The count should be one bigger.
#
$weblogTags           = $tagHolder->getAllTagsByType( 'w' );
my $newWeblogTagCount = scalar(@$weblogTags);
is( ($weblogTagCount +1 ), $newWeblogTagCount, "After adding the count of weblog tags is incremented" );


#
#  Delete the weblog entry.
#
$weblog->remove( gid => $gid, 
                 username => $username );


#
#  Ensure the tag is gone.
#
$tags = $tagHolder->getTags( weblog => $gid );
ok( !defined($tags), "After deleting the entry the tag is gone too" );

#
#  Reget all tags of type "weblog".
#
$weblogTags        = $tagHolder->getAllTagsByType( 'w' );
$newWeblogTagCount = 0;
$newWeblogTagCount = scalar(@$weblogTags) if defined( $weblogTags );

is( $weblogTagCount, $newWeblogTagCount, "And the count of weblog tags is back to normal" );


#
#  Delete the random new user.
#
deleteUser( $user, $username );
