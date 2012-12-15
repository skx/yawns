
=head1 NAME

Singleton::DBI - A singleton wrapper around the DBI object.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Singleton::DBI;
    use strict;

    my $db = Singleton::DBI->instance();

    $db->do( "UPDATE users SET cool=1 WHERE username='steve'" );

=for example end


=head1 DESCRIPTION


  This object is a Singleton wrapper around the DBI database  module.

  This allows all areas of the code to perform queries against the
 database without having to explicitly connect and disconnect themselves.

=cut


package Singleton::DBI;


use strict;
use warnings;


#
#  Get access to the database connection code.
#
use conf::SiteConfig;

#
#  The DBI modules for accessing the database.
#
use DBI qw/ :sql_types /;



#
#  The single, global, instance of this object
#
my $_dbh = undef;



=head2 instance

  Gain access to the single instance of our database connection.

=cut

sub instance
{
    $_dbh ||= (shift)->new();

    return ($_dbh);
}


=head2 new

  Create a new instance of this object.  This is only ever called once
 since this object is used as a Singleton.

=cut

sub new
{

    #
    # get necessary config info
    #
    my $dbuser = conf::SiteConfig::get_conf('dbuser');
    my $dbpass = conf::SiteConfig::get_conf('dbpass');
    my $dbname = conf::SiteConfig::get_conf('dbname');
    my $dbserv = conf::SiteConfig::get_conf('dbserv');

    # Build up DBI connection string.
    my $datasource = 'dbi:mysql:' . $dbname;
    $datasource .= "\;host=$dbserv" if ($dbserv);

    my $t = DBI->connect_cached( $datasource, $dbuser, $dbpass ) or
      die DBI->errstr();

    #
    #  UTF
    #
    $t->{ mysql_enable_utf8 } = 1;
    $t->do('SET NAMES utf8');
    return ($t);
}



1;



=head1 AUTHOR

Steve Kemp

http://www.steve.org.uk/

=cut



=head1 LICENSE

Copyright (c) 2005-2009 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut
