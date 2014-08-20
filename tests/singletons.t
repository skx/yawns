#!/usr/bin/perl -w -Ilib/
#
#  Test that the various singleton objects we use work correctly.
#


use Test::More qw( no_plan );


BEGIN { use_ok( 'conf::SiteConfig' ); }
require_ok( 'conf::SiteConfig' );

BEGIN { use_ok( 'Singleton::DBI' ); }
require_ok( 'Singleton::DBI' );

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


