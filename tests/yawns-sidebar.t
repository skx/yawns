#!/usr/bin/perl -w -I..
#
#  Test that we can create the sidebar appropriately, that it is
# free of HTML errors and that it is modified appropriately by
# user-preferences.
#

use Test::More qw( no_plan );

#
#  Utility functions to create a new user.
#
require 'tests/user.utils';

#
#  Load the modules we use.
#
BEGIN { use_ok( 'Yawns::Articles'); }
require_ok( 'Yawns::Articles' );
BEGIN { use_ok( 'Yawns::Polls'); }
require_ok( 'Yawns::Polls' );
BEGIN { use_ok( 'Yawns::Sidebar'); }
require_ok( 'Yawns::Sidebar' );
BEGIN { use_ok( 'Yawns::User'); }
require_ok( 'Yawns::User' );
BEGIN { use_ok( 'Yawns::Users'); }
require_ok( 'Yawns::Users' );
BEGIN { use_ok( 'Singleton::Session'); }
require_ok( 'Singleton::Session' );



my $sidebar = Yawns::Sidebar->new();

isa_ok( $sidebar, "Yawns::Sidebar" );


my $menu = $sidebar->getMenu();
ok( defined( $menu ), "The menu is defined" );


my $login = $sidebar->getLoginBox();
ok( defined( $login ), "The login boxis defined" );


#
#  We're only going to validate the HTML if we have the HTML::Lint
# package installed.  (Debian package libhtml-lint-perl).
#
my $test = "use HTML::Lint;";
my $lint = 1;
eval( $test );
if ( $@ )
{
    $lint = 0;
}

SKIP: {
    # If the module isn't enabled we skip 5 tests.
    skip "HTML::Lint not available", 5, if ( ! $lint );

    # 1
    use_ok( 'HTML::Lint');

    # 2
    require_ok( 'HTML::Lint' );

    # 3
    my $lint = HTML::Lint->new;
    isa_ok( $lint, "HTML::Lint" );

    #
    #  Parse the sidebar.
    #
    $lint->parse( $menu );
    my $error_count = $lint->errors;

    # 4
    ok( $error_count == 0, " Menu has no HTML errors." );

    #
    # Now the same for the login box.
    #
    $lint = HTML::Lint->new;
    $lint->parse( $login );

    $error_count = $lint->errors;

    # 5
    ok( $error_count == 0, "Login box has no HTML errors" );
}



#
#  OK now we've validated our HTML, and done basic testing we'll
# create a user and verify that their preferences make the sidebar
# behave appropriately.
#

#
#  Create a new user.
#
my ($user, $username ) = setupNewUser();


#
#  Fake a login via our session object.
#
my $session = Singleton::Session->instance();
ok( defined( $session ) , "We have a session object" );
isa_ok( $session, "CGI::Session" );

#
# Set the session up, and make sure it works.
#
$session->param( "logged_in", $username );
is( $session->param( "logged_in" ), $username, "Login OK" );


#
#  Now get the sidebar menu with and without polls
#
$user->savePreferences( view_polls => 0 );
$menu = $sidebar->getMenu();
ok( defined( $menu ), "The menu is defined" );

ok( $menu !~ /\/polls\/[0-9]+/, "The menu doesn't have polls once the user has disabled them" );

$user->savePreferences( view_polls => 1 );
$menu = $sidebar->getMenu();
ok( defined( $menu ), "The menu is defined" );

#
#  test for polls if there are any.
#
my $polls = Yawns::Polls->new();
if ( $polls->getCurrentPoll() )
{
    ok( $menu =~ /\/polls\/[0-9]+/, "The menu has polls once the user has enabled them" );
}
else
{
    ok( 1 , "Skipped looking for polls in the sidebar - there are no polls" );
}


#
#  Now get the sidebar menu with and without weblogs
#
$user->savePreferences( view_blogs => 0 );
$menu = $sidebar->getMenu();
ok( defined( $menu ), "The menu is defined" );
ok( $menu !~ /\/users\/([A-Za-z0-9_\-]+)\/weblog/, "The menu doesn't have weblogs once the user has disabled them" );


$user->savePreferences( view_blogs => 1 );
$menu = $sidebar->getMenu();
ok( defined( $menu ), "The menu is defined" );
ok( $menu =~ /\/users\/([A-Za-z0-9_\-]+)\/weblog/, "The menu has blogs once the user has enabled them" );


#
#  Finally get the sidebar menu with and without previous headlines
#
$user->savePreferences( view_headlines => 0 );
$menu = $sidebar->getMenu();
ok( defined( $menu ), "The menu is defined" );
ok( $menu !~ /\/articles\/[0-9]+/, "The menu doesn't have previous headlines once the user has disabled them" );


$user->savePreferences( view_headlines => 1 );
$menu = $sidebar->getMenu();
ok( defined( $menu ), "The menu is defined" );

#
#  Only test for previous articles if there are any
#
my $arts = Yawns::Articles->new();
if ( $arts->count() )
{
    ok( $menu =~ /\/article\//, "The menu has previous headlines once the user has enabled them" );
}
else
{
    ok( 1 , "Previous headline testing skipped: No previous articles present" );
}


#
#  Delete the random new user.
#
deleteUser( $user, $username );
