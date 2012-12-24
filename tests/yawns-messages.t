#!/usr/bin/perl -w -Ilib/
#
#  Test that we can work with user-messaging correctly.
#
# $Id: yawns-messages.t,v 1.3 2006-09-24 19:05:21 steve Exp $
#

use Test::More qw( no_plan );

#
#  Utility methods for creating a new user.
#
require 'tests/user.utils';

#
#  Load the modules we use.
#
BEGIN { use_ok( 'Yawns::User'); }
require_ok( 'Yawns::User' );

BEGIN { use_ok( 'Yawns::Messages'); }
require_ok( 'Yawns::Messages' );


#
#  Create a new user.
#
my ($user, $username ) = setupNewUser();

#
# Gain access to the users messages.
#
my $msgs = Yawns::Messages->new( username => $username );
isa_ok( $msgs, "Yawns::Messages" );

#
# Get message counts.
#
my ( $new, $total ) = $msgs->messageCounts();
ok( $new   =~ /^[0-9]*$/ &&
    $total =~ /^[0-9]*$/,
    "Message counts are numeric" );
is( $new, 0 , "New user has no new messages" );
is( $total, 0 , "New user has no new messages" );

#
#  Send a mesasge from the user to themselves
#
my $id = $msgs->send( to      => $username,
                      subject => "Test subject",
                      body    => "Test body" );

#
#  Get the new message counts.
#
( $new, $total ) = $msgs->messageCounts();
ok( $new   =~ /^[0-9]*$/ &&
    $total =~ /^[0-9]*$/,
    "Message counts are numeric" );
is( $new, 1 , "Sending a message to ourself increased the message counts" );
is( $total, 1 , "Sending a message to ourself increased the message counts" );


#
#  Fetch the messages.
#
my $data = $msgs->getMessages();
ok( defined( $data ), "We fetched the newly sent message" );

#
#  Test the data
#
is( @$data[0]->{'from'}, $username, "The new message has the correct sender" );
is( @$data[0]->{'new'}, 1, "The new message has the correct status" );

#
#  Mark the message as read
#
$msgs->markRead( $id );

$data = $msgs->getMessages();
ok( defined( $data ), "We fetched the newly read message" );

#
#  Test the data
#
is( @$data[0]->{'new'}, 0, "After reading the message is no longer new" );



#
#  Delete the message
#
$msgs->deleteMessage( $id );

#
#  Verify that the messages are gone.
#
( $new, $total ) = $msgs->messageCounts();
ok( $new   =~ /^[0-9]*$/ &&
    $total =~ /^[0-9]*$/,
    "Message counts are numeric" );
is( $new,   0, "After deletion we have no new messages" );
is( $total, 0, "After deletion we have no messages total" );



#
#  Fetch the messages.
#
$data = $msgs->getMessages();
ok( defined( $data ), "Fetching a deleted message fails" );


#
#  Test the data
#
is( @$data[0], undef, "Deleted message is no longer around" );


#
#  Delete the temporary user.
#
deleteUser( $user, $username );
