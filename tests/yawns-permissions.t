#!/usr/bin/perl -w -Ilib/
#
#  Test that we can work with permissions.
#
# $Id: yawns-permissions.t,v 1.4 2006-11-14 00:59:24 steve Exp $
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
BEGIN { use_ok( 'Yawns::Permissions'); }
require_ok( 'Yawns::Permissions' );


#
#  Create a random new user.
#
my ($user, $username ) = setupNewUser();


#
#  Get a permission object.
#
my $perms = Yawns::Permissions->new();


#
#  Get all currently known permission keys.
#
my @known = $perms->getKnownAttributes();
ok( @known, "We got the permission keys" );
ok( $#known > 0, "There are several of them" );


#
#  Test that the new user doesn't have any additional permissions.
#
foreach my $key ( @known )
{
    is( 0, $perms->check( username => $username,
                          priv => $key ),
         "New user doesn't have the permission: $key"  );
}


#
#  Make the user a complete site-administrator
#
$perms->makeAdmin( $username );
is( 1, 1, "User $username made site-administrator." );


#
#  Now the user should be able to do everything!
#
foreach my $key ( @known )
{
    is( 1, $perms->check( username => $username,
                          priv => $key ),
         "Newly promoted admin has the permission: $key"  );
}


#
#  Remove all administration permissions.
#
$perms->removeAllPermissions( $username );
is( 1, 1, "User has no privileges anymore." );



#
#  Test that the user doesn't have permissions after demotion
#
foreach my $key ( @known )
{
    is( 0, $perms->check( username => $username,
                          priv => $key ),
         "After permission-strip the permission key has gone: $key" );
}


#
#  Make admin one last time.
#
$perms->makeAdmin( $username );
is( 1, 1, "User made admin" );



#  Delete the random new user.
#
deleteUser( $user, $username );


#
#  A deleted usr has no special permissions.
#
foreach my $key ( @known )
{
    is( 0, $perms->check( username => $username,
                          priv => $key ),
         "After deletion the the permission key has gone: $key" );
}

