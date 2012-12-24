#!/usr/bin/perl -w -Ilib/
#
#  Test that we can get a modifier successfully, and that it changes
# as weblogs and scratchpads are added.
#
# $Id: modifier.t,v 1.8 2007-01-18 18:32:21 steve Exp $
#

use Test::More qw( no_plan );

#
#  Utility code for creating a temporary new user.
#
require 'tests/user.utils';


#
#  Load the modules we use.
#
BEGIN { use_ok( 'Yawns::User'); }
require_ok( 'Yawns::User' );

BEGIN { use_ok( 'Yawns::Weblog'); }
require_ok( 'Yawns::Weblog' );

BEGIN { use_ok( 'Yawns::Scratchpad'); }
require_ok( 'Yawns::Scratchpad' );


#
#  Create a random new user.
#
my ($user, $username ) = setupNewUser();


#
#  Now verify we can get the emtpy modifier.
#
my $modifier = $user->getModifier();
ok( defined( $modifier ), "Modifier for new user is found" );
is( $modifier,
    "[ <a href=\"/create/message/$username\">Send Message</a> ]",
    "Modifier matches what we'd expect a new user to have" );

#
#  Get the scratchpad object.
#
my $scratchpad = Yawns::Scratchpad->new( username => $username );
isa_ok( $scratchpad, "Yawns::Scratchpad" );

my $text = $scratchpad->get();
ok( (length( $text ) == 0 ), "Scratchpad for new user is empty" );

#
#  Set some scratchpad text
#
my $data = "Foo";
$scratchpad->set($data, "public");
$text = $scratchpad->get();
ok( (length( $text ) == length( $data ) ), "Scratchpad set properly" );

#
#  Make sure the modifier is updated.
#
$modifier = $user->getModifier();
ok( defined( $modifier ), "There is a modifier" );
ok( $modifier =~ /scratchpad/i, "Modifier now contains link to scratchpad." );
ok( ! ( $modifier =~ /weblog/i ), "Modifier but not to weblogs." );


#
#  Add a weblog entry.
#
#  Pick a random title.
my $title = join ( '', map {('a'..'z')[rand 26]} 0..27 );

my $weblog = Yawns::Weblog->new( username => $username );
my $id = $weblog->add( subject => $title,
	 	       body    => "<p>Here is my body</p><p>It is short</p>",
	               comments_allowed => 1 );

isa_ok( $weblog, "Yawns::Weblog" );
ok( $id, "Weblog entry added" );


#
#  Make sure the modifier is updated.
#
$modifier = $user->getModifier();
ok( $modifier =~ /scratchpad/i, "Modifier still contains link to scratchpad." );
ok( $modifier =~ /weblog/i, "Modifier now contains link to weblogs." );


#
#  Delete the scratchpad.
#
$scratchpad->set( "", "public" );
$modifier = $user->getModifier();
ok( !($modifier =~ /scratchpad/i), "Modifier now doesn't contain link to scratchpad." );
ok( $modifier =~ /weblog/i, "Modifier but still has a link to weblogs." );


#
#  Delete the temporary user.
#
deleteUser( $user, $username );

#
#  Make sure the modifier for a deleted user is gone.
#
$modifier = $user->getModifier();
ok( !( length( $modifier ) ), "Modifier for deleted user is empty: '$modifier'" );
