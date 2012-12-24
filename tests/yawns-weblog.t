#!/usr/bin/perl -w -Ilib/
#
#  Test that we can work with weblogs correctly.
#
# $Id: yawns-weblog.t,v 1.17 2007-02-24 18:19:57 steve Exp $
#

use Test::More qw( no_plan );

#
#  Utility functions for creating a new user.
#
require 'tests/user.utils';


#
#  Load the modules we use.
#
BEGIN { use_ok( 'Yawns::User'); }
require_ok( 'Yawns::User' );

BEGIN { use_ok( 'Yawns::Stats'); }
require_ok( 'Yawns::Stats' );

BEGIN { use_ok( 'Yawns::Weblog'); }
require_ok( 'Yawns::Weblog' );


#
# Hall of fame handle.
#
my $hof = Yawns::Stats->new();
isa_ok( $hof, "Yawns::Stats" );

#
#  Get the current stats
#
my $stats = $hof->getStats();
ok( defined($stats ), "We got the site statistics" );
my $weblogCount = $stats->{'weblog_count'};
ok( defined($weblogCount), " Which has the current weblog count: $weblogCount" );
ok( $weblogCount =~ /^([0-9])+$/, " Which is a number." );


#
#  Create a random new user.
#
my ($user, $username, $email ) = setupNewUser();

#
#  Now verify we can get the newly created users data.
#
my $userinfo = $user->get();
ok( defined( $userinfo ), "User information is defined" );

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
#  The new user now has a single weblog entry
#
ok( $user->getWeblogCount() == 1, "First weblog entry added successfully" );

#
#  Find the GID
#
my $gid = $weblog->getGID( username=> $username, id => $id );
ok( ( $gid > 0 ), "Found GID for the first entry" );

#
#  Now we have the gid find the link
#
my $link = $weblog->getLink( gid => $gid );
ok( defined( $link ), "Found the weblog link" );
is( $link, "/users/$username/weblog/$id" , "The link is OK" );




#
#  Get that single entry.
#
my $first       = $weblog->getSingleWeblogEntry( gid => $gid, editable => 1 );
my $first_entry = @$first[0];

#
#  Make sure the first entry has the correct navigation entries.
# (ie. it has no next/previous links since it is the only existing
# weblog entry)
#
is( $first_entry->{'next'}, undef, "The first entry is last." );
is( $first_entry->{'prev'}, undef, "The first entry is first." );
is( $first_entry->{'comments_enabled'} , 1, "Comments are enabled" );
is( $first_entry->{'comment_count'}, 0, "There are no comments posted." );


#
#  Now test that the default score is OK.
#
is( 5, $weblog->getScore( gid => $gid ), "Initial entry has default score" );


#
# Decrease score.
#
my $count = 5;
while( $count > 0 )
{
    $weblog->report( gid => $gid );
    is( $count, 1 + $weblog->getScore( gid => $gid ), "Weblog score decremented" );
    $count -= 1;
}

#
# Make sure it is never negative.
#
$count = 5;
while( $count > 0 )
{
    $weblog->report( gid => $gid );
    $count -= 1;
}
is( 0, $weblog->getScore( gid => $gid ), "Weblog score never goes negative" );


#
#  Edit the entry, so that comments are disabled.
#
$weblog->edit( username => $username,
               id       => $id,
               body     => $first_entry->{'body'},
               title    => "x" . $first_entry->{'title'},
               comments_enabled => 0 );

#
#  Now get the comment count.
#
$first       = $weblog->getSingleWeblogEntry( gid => $gid, editable => 1 );
$first_entry = @$first[0];

is( $first_entry->{'comments_enabled'} , 0, "Comments are disabled after edit" );
is( $first_entry->{'comment_count'}, 0, "There are still no comments posted." );
is( $first_entry->{'title'}, "x" . $title, "The edited title has changed." );



#
#  Add another weblog entry.
#
my $id2 = $weblog->add( subject => $title,
	 	       body    => "<p>Here is my body</p><p>It is short</p>",
	               comments_allowed => 1 );

ok( $user->getWeblogCount() == 2, "Second weblog entry added successfully" );


#
#  Get the gid
#
my $gid2 = $weblog->getGID( username=> $username, id => $id2 );
ok( ( $gid > 0 ), "Found GID for the second entry" );

#
#  Get the link
#
$link = $weblog->getLink( gid => $gid2 );
ok( defined( $link ), "Found the weblog link for the second entry" );
is( $link, "/users/$username/weblog/$id2" , "The link is OK" );



#
#  Make sure the HOF is updated.
#
my $userstats = $hof->getStats();
ok( defined($userstats ), "We got the updated site statistics" );
my $userWeblogCount = $userstats->{'weblog_count'};
ok( defined($userWeblogCount), " Which has the current weblog count." );
ok( $userWeblogCount =~ /^([0-9])+$/, " Which is a number." );
is( $userWeblogCount, $weblogCount + 2, " The weblog count is incremented OK." );


#
#  Get the second entry.
#
my $second = $weblog->getSingleWeblogEntry( gid => $gid2, editable => 1 );
my $second_entry  = @$second[0];

#
#  Since this is the second, and last, weblog entry it should have a
# "previous" link back to the previous entry - but no "next" link since
# it is last.
#
is( $second_entry->{'next'}, undef, "The second entry has no following entry" );
is( $second_entry->{'prev'}, 1, "The second entry is second." );


#
#  Now make sure that the first entry has been updated so that there
# is an entry after it :)
#
$first = $weblog->getSingleWeblogEntry( gid => $gid, editable => 1 );
$first_entry  = @$first[0];

#
#  Make sure the navigation links are correct.
#
is( $first_entry->{'next'}, 2, "The first entry now has an entry after it" );
is( $first_entry->{'prev'}, undef, "The first entry is still first" );

#
#  Delete the second entry.
#
$weblog->remove( gid => $gid2, username => $username );
ok( $user->getWeblogCount() == 1, "Weblog count is back to one after removing second entry." );


#
#  Ensure the title is what we expect.
#
my $set = $weblog->getTitle( gid => $gid );
ok( $set eq "x" . $title , "OK new weblog title matches" );


#
#  Ensure the ID matches
#
my $user_id = $weblog->getID( gid => $gid );
ok( $user_id == $id , "OK ID matches" );


#
#  Ensure the ID matches
#
my $user_owner = $weblog->getOwner( gid => $gid );
ok( $user_owner eq $username , "As does the username" );

#
#  Delete the random new user.
#
deleteUser( $user, $username );


#
#  Make sure the weblog count in the HOF is now decreased.
#
$userstats = $hof->getStats();
ok( defined($userstats), "We got the updated site statistics" );
$userWeblogCount = $userstats->{'weblog_count'};
ok( defined($userWeblogCount), " Which has the current weblog count." );
ok( $userWeblogCount =~ /^([0-9])+$/, " Which is a number." );
is( $userWeblogCount, $weblogCount, " The weblog count is back to what it should be." );


