#!/usr/bin/perl -w -I..
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
BEGIN { use_ok( 'Yawns::Messages'); }
require_ok( 'Yawns::Messages' );


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
#  Create a messages object.
#
my $msg = Yawns::Messages->new( username => $username );
isa_ok( $msg, "Yawns::Messages" );


#
#  A new user should have no messages
#
my $result = $msg->getMessages();
my @msgs = @$result;
is( $#msgs, -1 , "The new user has no site messages" );


#
#  Test that the new user has sane defaults.
#
foreach my $key ( qw/ article comment weblog / )
{
    is( $notifications->getNotificationMethod( $username, $key ),
        "email",  "Sane default for notification of type: '$key'" );
}


#
#  Change each option to "site message"
#
$notifications->save(  article => "message",
                       comment => "message",
                       weblog  => "message"  );


#
#  Verify it worked.
#
foreach my $key ( qw/ article comment weblog / )
{
    is( $notifications->getNotificationMethod( $username, $key ),
        "message",  "Updated notification of type: '$key' - to message" );
}


#
#  Send a notification message, on a ficticious comment.
#
$notifications->sendNotification( 1 );

#
#  Make sure the user now has a single message.
#
$result = $msg->getMessages();
@msgs = @$result;
is( $#msgs, 0 , "After sending a notification the user has a message." );


#
#  Get the message ID of that message.
#
my $id = undef;
foreach my $m ( @msgs )
{
    my %f = %$m;
    $id = $f{'id'};
}
ok( $id, "There is a message ID for the new message" );
ok( $id =~ /^([0-9]+)$/, " Which is a number" );


#
#  Get the message body.
#
if ( $id )
{
    my $alert  = $msg->getMessage( $id );
    my @alerts = @$alert;

    foreach my $a ( @alerts )
    {
        my %aa = %$a;
        ok( $aa{'text'} =~ /\/articles\/0#comment_1/,
            "Notification message has the correct link" );
    }
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
#  Ensure the message is deleted.
#
$result = $msg->getMessages();
@msgs = @$result;
is( $#msgs, -1 , "The new user has no site messages" );


#
#  Ensure the notification options are removed too.
#
foreach my $key ( qw/ article comment weblog / )
{
    is( $notifications->getNotificationMethod( $username, $key ),
        undef,  "Deleted user has empty notification type: '$key'" );
}
