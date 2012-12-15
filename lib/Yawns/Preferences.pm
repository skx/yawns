# -*- cperl -*- #

=head1 NAME

Yawns::Preferences - A module for working with user preferences.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Preferences;
    use strict;

    my $accessor = Yawns::Preferences->new( username => "bob" );

    # get specific preference
    my $prefs = $accessor->getAll();

    # get single preference.
    my $key   = $accessor->getPreference( "posting_format" );

    # set one
    $accessor->setPreference( "posting_format", "textile" );

=for example end


=head1 DESCRIPTION

This module deals with the contents of the preferences table.

=cut


package Yawns::Preferences;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.7 $' =~ m/Revision:\s*(\S+)/;


#
#  Standard modules which we require.
#
use strict;
use warnings;


#
#  Yawns modules which we use.
#
use Singleton::DBI;

use Yawns::User;


=head2 new

  Create a new instance of this object.

=cut

sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};

    #
    #  Allow user supplied values to override our defaults
    #
    foreach my $key ( keys %supplied )
    {
        $self->{ lc $key } = $supplied{ $key };
    }

    bless( $self, $class );
    return $self;

}



=head2 getAll

  Get all key and values from a user preferences.

=cut

sub getAll
{
    my ($class) = (@_);

    #
    #  The username we're working with.
    #
    my $username = $class->{ 'username' };
    die "No username" unless ($username);

    #
    #  The results
    #
    my %results;

    #
    #  Get the database handle.
    #
    my $db = Singleton::DBI->instance();


    my $querystr =
      "SELECT a.pref_name,a.pref_value FROM preferences AS a INNER JOIN users b WHERE a.user_id = b.id AND b.username=?";
    my $sql = $db->prepare($querystr);
    $sql->execute($username);

    #
    # Bind the columns
    #
    my ( $name, $value );
    $sql->bind_columns( undef, \$name, \$value );

    #
    #  Process the results
    #
    while ( $sql->fetch() )
    {
        $results{ $name } = $value;
    }

    $sql->finish();

    return ( \%results );
}



=head2 getPreference

  Return a single preference from the database.

=cut

sub getPreference
{
    my ( $class, $key ) = (@_);

    #
    #  The username we're working with.
    #
    my $username = $class->{ 'username' } || "Anonymous";
    die "No username" unless ($username);


    #
    #  Get them..
    #
    my $all = $class->getAll($key);
    my $val = $all->{ $key };

    return ($val);
}



=head2 setPreference

  Set a single preference for the given user.

=cut

sub setPreference
{
    my ( $class, $name, $value ) = (@_);

    #
    #  Get the username, and find the ID.
    #
    my $username = $class->{ 'username' } || "Anonymous";
    die "No username" unless ($username);

    my $user = Yawns::User->new( username => $username );
    my $data = $user->get();
    my $id   = $data->{ 'id' };

    #
    #  Now we can insert.
    #
    my $dbi = Singleton::DBI->instance();

    #
    #  delete
    #
    my $sql =
      $dbi->prepare("DELETE FROM preferences WHERE pref_name=? AND user_id=?");
    $sql->execute( $name, $id ) or die "Failed to delete " . $dbi->errstr();
    $sql->finish();


    #
    #  Insert.
    #
    if ( defined($value) )
    {
        $sql = $dbi->prepare(
            "INSERT INTO preferences (pref_name,pref_value,user_id) VALUES(?,?,?)"
        );

        $sql->execute( $name, $value, $id ) or
          die "Failed to update preference " . $dbi->errstr();
        $sql->finish();
    }

}


=head2 deleteByUser

  Delete all preferences for the given user.

=cut

sub deleteByUser
{
    my ($class) = (@_);

    #
    #  Get the username, and find the ID.
    #
    my $username = $class->{ 'username' } || "Anonymous";
    die "No username" unless ($username);

    my $user = Yawns::User->new( username => $username );
    my $data = $user->get();
    my $id   = $data->{ 'id' };

    #
    #  Now we can insert.
    #
    my $dbi = Singleton::DBI->instance();

    #
    #  delete
    #
    my $sql = $dbi->prepare("DELETE FROM preferences WHERE user_id=?");
    $sql->execute($id) or die "Failed to delete " . $dbi->errstr();
    $sql->finish();

}



=head2 invalidateCache

  Clean any cached content we might have.

=cut

sub invalidateCache
{
    my ($class) = (@_);

    my $name = $class->{ 'username' };
}



1;


=head1 AUTHOR

Steve Kemp

http://www.steve.org.uk/



=head1 LICENSE

Copyright (c) 2007 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut
