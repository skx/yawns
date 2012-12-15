# -*- cperl -*- #

=head1 NAME

Yawns::Bookmarks - A module for working with user bookmarks.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Bookmarks;
    use strict;

    my $bookmarks  = Yawns::Bookmarks->new( username => "Steve" );

    my $id = $bookmarks->add( article => 123 );

    $bookmarks->remove( id => $id );

=for example end


=head1 DESCRIPTION

This module contains code for adding, removing, and fetching bookmarks
from the database.

=cut


package Yawns::Bookmarks;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;


@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.11 $' =~ m/Revision:\s*(\S+)/;


#
#  Standard modules which we require.
#
use strict;
use warnings;


#
#  Yawns modules which we use.
#
use Singleton::DBI;



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


=head2 add

  Add a new bookmark, be it a poll, a weblog entry, or an article.

=cut

sub add
{
    my ( $class, %options ) = (@_);

    my $username = $class->{ 'username' };
    die "No username " if ( !defined($username) );


    my $type = undef;
    my $id   = undef;

    if ( ( $options{ 'weblog' } ) and
         ( $options{ 'weblog' } =~ /([0-9]+)/ ) )
    {
        $type = 'w';
        $id   = $options{ 'weblog' };
    }
    if ( ( $options{ 'article' } ) and
         ( $options{ 'article' } =~ /([0-9]+)/ ) )
    {
        $type = 'a';
        $id   = $options{ 'article' };
    }
    if ( ( $options{ 'poll' } ) and
         ( $options{ 'poll' } =~ /([0-9]+)/ ) )
    {
        $type = 'p';
        $id   = $options{ 'poll' };
    }

    die "No type" unless defined($type);
    die "No ID"   unless defined($id);

    #
    #  Get the user ID for the user.
    #
    my $user    = Yawns::User->new( username => $username );
    my $data    = $user->get();
    my $user_id = $data->{ 'id' };

    #
    # Insert the entry.
    #
    my $db = Singleton::DBI->instance();
    my $sql = $db->prepare(
                  "INSERT INTO bookmarks( user_id, id, type ) VALUES( ?,?,? )");
    $sql->execute( $user_id, $id, $type ) or
      die "FAILED TO execute: " . $db->errstr();
    $sql->finish();

    #
    # Invalidate cache
    #
    $class->invalidateCache();

    #
    # Return the number of the new bookmark
    #
    my $num = 0;
    if ( $db->can("mysql_insert_id") )
    {
        $num = $db->mysql_insert_id();
    }
    else
    {
        $num = $db->{ mysql_insertid };
    }

    return ($num);
}



=head2 get

  Get the bookmarks for the given user.

=cut

sub get
{
    my ($class) = (@_);

    my $username = $class->{ 'username' };
    die "No username " if ( !defined($username) );

    #
    #  Fetch from the database.
    #
    my $db = Singleton::DBI->instance();
    my $sql = $db->prepare(
        'SELECT a.gid,a.id,a.type FROM bookmarks AS a INNER JOIN users AS b WHERE a.user_id=b.id AND b.username=? ORDER BY gid DESC'
    );
    $sql->execute($username) or
      die "Failed to fetch bookmarks : " . $db->errstr();
    my $bookmarks = $sql->fetchall_arrayref();
    $sql->finish();

    #
    # Return.
    #
    return ($bookmarks);

}



=head2 count

  Count the number of bookmarks the given user owns.

=cut

sub count
{
    my ($class) = (@_);

    #
    #  The username we're working with.
    #
    my $username = $class->{ 'username' };
    die "No username " if ( !defined($username) );

    #
    # Otherwise fetch from the database
    #
    my $db = Singleton::DBI->instance();
    my $query = $db->prepare(
        'SELECT COUNT(a.id) FROM bookmarks AS a INNER JOIN users AS b WHERE a.user_id=b.id AND b.username=?'
    );
    $query->execute($username);
    my $count = $query->fetchrow_array();

    return ($count);
}



=head2 remove

  Remove the given bookmark.

=cut

sub remove
{
    my ( $class, %params ) = (@_);

    #
    # Get the ID
    #
    my $id = $params{ 'id' };
    die "No id" unless defined($id);

    #
    # Get the owner.
    #
    my $username = $class->{ 'username' };
    die "No username" unless defined($username);

    #
    # Delete
    #
    my $db = Singleton::DBI->instance();
    my $sql = $db->prepare(
        "DELETE b FROM bookmarks AS b INNER JOIN users a WHERE b.user_id=a.id AND a.username=? AND b.gid=?"
    );
    $sql->execute( $username, $id ) or
      die "Failed to delete bookmark " . $db->errstr();

    $sql->finish();

    #
    # Invalidate cache.
    #
    $class->invalidateCache();

}



=head2 deleteByUser

  Delete every bookmark the given user has.

=cut

sub deleteByUser
{
    my ($class) = (@_);

    #
    # Get the owner.
    #
    my $username = $class->{ 'username' };
    die "No username" unless defined($username);

    #
    # Delete
    #
    my $db = Singleton::DBI->instance();
    my $sql = $db->prepare(
        "DELETE a FROM bookmarks AS a INNER JOIN users AS b WHERE a.user_id=b.id AND b.username=?"
    );
    $sql->execute($username) or
      die "Failed to delete bookmark " . $db->errstr();
    $sql->finish();

    #
    # Invalidate cache.
    #
    $class->invalidateCache();

}

=head2 invalidateCache

  Invalidate the cache of this object.

=cut

sub invalidateCache
{
    my ($class) = (@_);
}



1;


=head1 AUTHOR

Steve Kemp

http://www.steve.org.uk/



=head1 LICENSE

Copyright (c) 2005,2006 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut
