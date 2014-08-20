#!/usr/bin/perl -w -Ilib/
#
#  Test that we can work with the comment notification object.
#
# $Id: yawns-comment-notifier.t,v 1.2 2006-12-13 00:34:59 steve Exp $
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
BEGIN { use_ok( 'Yawns::Comment::Notifier'); }
require_ok( 'Yawns::Comment::Notifier' );


#
#  Create a random new user.
#
my ($user, $username ) = setupNewUser();


#
# Get article 0 and verify it doesn't exist.
#
my $article = Yawns::Article->new( id => 0 );
isa_ok( $article, "Yawns::Article" );
my $title = $article->getTitle();
ok( !defined( $title ), "Article 0 has no title" );

my $new_title = "This is my title";

#
#  Create the first article.
#
$article->create( id    => 0,
		  title => $new_title,
		  body  => "<p>This is my lead text</p>\n<p>This is my body</p>",
		  author => $username,
		  topic  => "News" );



#
#  Create a notifications object.
#
my $notifications = Yawns::Comment::Notifier->new( username  => $username,
                                                   onarticle => 0,
                                                   onweblog  => undef,
                                                   onpoll    => undef,
                                                 );
isa_ok( $notifications, "Yawns::Comment::Notifier" );



#
#  Test that the new user has sane defaults.
#
foreach my $key ( qw/ article comment weblog / )
{
    is( $notifications->getNotificationMethod( $username, $key ),
        "email",  "Sane default for notification of type: '$key'" );
}


#
#  Change each option to "none".
#
$notifications->save(  article => "none",
                       comment => "none",
                       weblog  => "none"  );


#
#  Verify it worked.
#
foreach my $key ( qw/ article comment weblog / )
{
    is( $notifications->getNotificationMethod( $username, $key ),
        "none",  "Updated notification of type: '$key' - to none" );
}


#
#  Delete the random new user.
#
deleteUser( $user, $username );


#
# Now delete the article
#
$article->delete();

#
#  Ensure the notification options are removed too.
#
foreach my $key ( qw/ article comment weblog / )
{
    is( $notifications->getNotificationMethod( $username, $key ),
        undef,  "Deleted user has empty notification type: '$key'" );
}
