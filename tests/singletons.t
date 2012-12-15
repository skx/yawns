#!/usr/bin/perl -w -I..
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

BEGIN { use_ok( 'Singleton::Memcache' ); }
require_ok( 'Singleton::Memcache' );

BEGIN { use_ok( 'Singleton::Session' ); }
require_ok( 'Singleton::Session' );

BEGIN { use_ok( 'Singleton::Redis' ); }
require_ok( 'Singleton::Redis' );


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
#  Connect to Memcached
#
my $cache = Singleton::Memcache->instance();

#
# Is this the right object type?
#
isa_ok( $cache, "Singleton::Memcache" );

#
#  Can we set a value?
#
ok( $cache->set( "foo", "bar" ), "Stored value in Memcache",  );

#
#  May we retrieve it?
#
ok( $cache->get( "foo" ) eq "bar", "Retrieved from Memcached" );

#
#  Delete it?
#
ok( $cache->delete("foo" ), "Removed OK" );

#
#  Now is it gone?
#
ok( ! defined $cache->get( "foo" ), "Key removed from Memcached" );

$cache->disconnect();


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



#
#  Redis
#
#
#  Connect to Memcached
#
my $r = Singleton::Redis->instance();

#
# Is this the right object type?
#
isa_ok( $r, "Singleton::Redis" );

#
#  Can we set a value?
#
ok( $r->set( "foo", "bar" ), "Stored value in Redis",  );

#
#  May we retrieve it?
#
ok( $r->get( "foo" ) eq "bar", "Retrieved from Redis" );

#
#  Delete it?
#
ok( $r->delete("foo" ), "Removed OK" );

#
#  Now is it gone?
#
ok( ! defined $r->get( "foo" ), "Key removed from Redis" );

$r->disconnect();
