#!/usr/bin/perl -w -Ilib/
#
#  Test that the various singleton objects we use work correctly.
#
# $Id: singletons.t,v 1.10 2005-11-28 13:33:44 steve Exp $
#


use Test::More qw( no_plan );


BEGIN { use_ok( 'conf::SiteConfig' ); }
require_ok( 'conf::SiteConfig' );

BEGIN { use_ok( 'Singleton::CGI' ); }
require_ok( 'Singleton::CGI' );

BEGIN { use_ok( 'Singleton::DBI' ); }
require_ok( 'Singleton::DBI' );

BEGIN { use_ok( 'Singleton::Session' ); }
require_ok( 'Singleton::Session' );


#
#  Connect to Database
#
my $dbh = Singleton::DBI->instance();

#
# Is this the right object type?
#
isa_ok( $dbh, "DBI::db" );

#
# Did we really connect to the database?
#
ok( $dbh->ping(), "Database connection made" );

#
# Can we prepare?
#
my $sql;
ok( ( $sql = $dbh->prepare( "SELECT COUNT(username) FROM users" ) ), "Selected" );

#
# And execute?
#
ok( ($sql->execute())[0], "Retrieved value" );
ok( $sql->finish(), "Finished OK" );


#
# Can we disconnect?
#
ok( $dbh->disconnect(), "Database disconnection worked OK" );



#
# Get CGI Form
#
my $form = Singleton::CGI->instance();


#
# Is this the right object type?
#
isa_ok( $form, "CGI" );


#
# Can we set a parameter?
#
my $key   = "Steve";
my $value = "Kemp";

#
# Can we set it and retrieve the right value?
#
ok( $form->param( $key, $value ), "Parameter set" );
ok( $form->param( $key ) eq $value, "Parameter retrieved OK" );


#
# Get Session object.
#
my $session = Singleton::Session->instance();


#
# Is this the right object type?
#
isa_ok( $session, "CGI::Session" );

#
# Can we set it and retrieve the right value?
#
ok( $session->param( $key, $value ), "Session parameter set" );
ok( $session->param( $key ) eq $value, "Session parameter retrieved OK" );



