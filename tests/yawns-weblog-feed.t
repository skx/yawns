#!/usr/bin/perl -w -I..
#
#  Test that our user weblog feeds work correctly.
#
# $Id: yawns-weblog-feed.t,v 1.2 2007-02-24 18:25:48 steve Exp $
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
#  Create a random new user.
#
my ($user, $username, $email ) = setupNewUser();

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
# No entries should mean that there is nothing in the feed.
#
my $feed    = $weblog->getWeblogFeed();
ok( !defined( $feed ) , "New user has an empty weblog feed" );


#
#  Generate a random title for the new weblog entry.
#
my $title1 = join ( '', map {('a'..'z')[rand 26]} 0..17 );
my $title2 = join ( '', map {('a'..'z')[rand 26]} 0..17 );


#
#  Add a weblog entry.
#
my $id = $weblog->add( subject => $title1,
	 	       body    => "<p>Here is my body</p><p>It is short</p>",
	               comments_allowed => 1 );

#
#  The new user now has a single weblog entry
#
ok( $user->getWeblogCount() == 1, "First weblog entry added successfully" );


#
#  The feed should now have entries.
#
$feed       = $weblog->getWeblogFeed();
my @entries = @$feed;
use Data::Dumper;
is( scalar( @entries ), 1 , "After adding an entry there is something in the feed" );

#
#  Make sure we have entity encoded entries.
#
foreach my $w ( @entries )
{
    my %entry = %$w;

    my $w_title = $entry{'title'};
    my $w_body  = $entry{'bodytext'};

    is( $w_title , $title1, "The title matches what we expect" );
    ok( $w_body !~ /[<>]/, "The body is HTML encoded" );
}



#
#  Add another weblog entry.
#
$id = $weblog->add( subject => $title2,
                    body    => "<p>Here is my body</p><p>It is short</p>",
                    comments_allowed => 1 );

$feed    = $weblog->getWeblogFeed();
@entries = @$feed;
is( scalar( @entries ), 2 , "After adding another entry there is something in the feed" );


#
#  Now we should have two entries
#
foreach my $w ( @entries )
{
    my %entry = %$w;

    my $w_title = $entry{'title'};
    my $w_body  = $entry{'bodytext'};

    my $t = 0;
    $t    = 1 if ( ( $w_title eq $title1 ) || ( $w_title eq $title2 ) );

    ok( $t, "The entry title matches what we expect" );
    ok( $w_body !~ /[<>]/, "The body is HTML encoded" );
}


#
#  Get the GID so we can get the title easiy.
#
my $gid = $weblog->getGID( username=> $username, id => $id );
ok( defined( $gid ), "Got GID for edited entry." );

#
#  Get the title to make sure it worked.
#
is( $weblog->getTitle( gid => $gid ), $title2, "Prior to edit the title is OK.");

#
#  Edit the second weblog entry, so that it has a different title.
#
$weblog->edit( username => $username,
               id       => $id,
               body     => "<p>Here is my body</p><p>It is short</p>",
               title    => "xx" . $title2,
               comments_enabled => 0 );


#
#  Get the title to make sure it worked.
#
is( $weblog->getTitle( gid => $gid ), "xx" . $title2, "Edited title changed." );

#
#  Get the feed again.
#
$feed    = $weblog->getWeblogFeed();
@entries = @$feed;
is( scalar( @entries ), 2 , "After editing there are still only two entries." );

#
#  Are the titles OK?
#
foreach my $w ( @entries )
{
    my %entry = %$w;

    my $w_title = $entry{'title'};
    my $w_body  = $entry{'bodytext'};

    my $t = 0;
    $t    = 1 if ( ( $w_title eq $title1 ) || ( $w_title eq "xx" . $title2 ) );

    ok( $t, "The entry title matches what we expect" );
    ok( $w_body !~ /[<>]/, "The body is HTML encoded" );
}



#
#
#  Delete the random new user.
#
deleteUser( $user, $username );


#
#  Make sure the weblog count is back to zero.
#
ok( $user->getWeblogCount() == 0, "New user has no weblogs" );


#
#  And the feed should be empty.
#
$feed     = $weblog->getWeblogFeed();
ok( ! defined( $feed ), "A deleted user has an empty weblog feed" );
