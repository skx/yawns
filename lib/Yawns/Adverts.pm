# -*- cperl -*- #

=head1 NAME

Yawns::Adverts - A module for working with user-submitted adverts.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Adverts;
    use strict;

    my $add = Yawns::Adverts->new();

    $add->addAdvert( title => "Title",
                     link  => "http://foo.com/",
                     show  => 1000 );

=for example end


=head1 DESCRIPTION

This module will deal with fetching, adding, and deleting user-submitted
adverts to your Yawns website.


=cut


package Yawns::Adverts;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.25 $' =~ m/Revision:\s*(\S+)/;


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



=head2 countActive

Return the number of adverts which are active.

=cut

sub countActive
{
    my ($class) = (@_);

    #
    #  Get the database handle.
    #
    my $db = Singleton::DBI->instance();


    #
    #  The query.
    #
    my $querystr =
      "SELECT COUNT(id) FROM adverts WHERE active='y' AND (shown < display) ";
    my $query = $db->prepare($querystr);


    #
    # Execute
    #
    $query->execute();

    #
    # Get the result
    #
    my $count = $query->fetchrow_array();

    #
    # Cleanup.
    #
    $query->finish();

    return ($count);

}



=head2 countPending

Return the number of adverts which are pending approval.

=cut

sub countPending
{
    my ($class) = (@_);

    #
    #  Get the database handle.
    #
    my $db = Singleton::DBI->instance();


    #
    #  The query.
    #
    my $querystr = "SELECT COUNT(id) FROM adverts WHERE active='n'";
    my $query    = $db->prepare($querystr);


    #
    # Execute
    #
    $query->execute();

    #
    # Get the result
    #
    my $count = $query->fetchrow_array();

    #
    # Cleanup.
    #
    $query->finish();

    return ($count);

}


=head2 addClick

Record an advert click to the given ID.

=cut

sub addClick
{
    my ( $class, $id ) = (@_);

    my $db = Singleton::DBI->instance();

    my $sql =
      $db->prepare("UPDATE adverts SET clicked = clicked + 1 WHERE id=?");
    $sql->execute($id);
    $sql->finish();

}



=head2 addAdvert

Add a new advert to the site.

=cut

sub addAdvert
{
    my ( $class, %options ) = (@_);

    #
    # Get the details we should add.
    #
    my $link     = $options{ 'link' };
    my $linktext = $options{ 'linktext' };
    my $text     = $options{ 'text' };
    my $owner    = $options{ 'owner' };
    my $display  = $options{ 'display' };

    my $db = Singleton::DBI->instance();
    my $sql = $db->prepare(
        "INSERT INTO adverts( owner, display, link, linktext, text ) VALUES( ?, ?, ?, ?, ? ) "
    );
    $sql->execute( $owner, $display, $link, $linktext, $text ) or
      die "Failed to insert advert " . $db->errstr();
    $sql->finish();

    #
    #  Return the ID of the new advert.
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



=head2 getAdvert

 Retrieve all known information about the given advert.

=cut

sub getAdvert
{
    my ( $class, $id ) = (@_);

    my $db = Singleton::DBI->instance();
    my $sql = $db->prepare(
        "SELECT  id,owner,active,link,linktext,text,clicked,shown,display FROM adverts WHERE id=?"
    );

    #
    # Get the details.
    #
    $sql->execute($id) or die $db->errstr();
    my @details = $sql->fetchrow_array();
    $sql->finish();

    #
    #  Store the results
    #
    my %advert = ( id       => $details[0],
                   owner    => $details[1],
                   active   => $details[2],
                   link     => $details[3],
                   linktext => $details[4],
                   text     => $details[5],
                   clicked  => $details[6],
                   shown    => $details[7],
                   display  => $details[8] );

    #
    # Return
    #
    return ( \%advert );
}



=head2 deleteByUser

  Delete all adverts by the given user.

=cut

sub deleteByUser
{
    my ($class) = (@_);

    my $username = $class->{ 'username' };
    die "No username!" unless defined($username);

    #
    #  Delete the adverts
    #
    my $db    = Singleton::DBI->instance();
    my $query = $db->prepare("DELETE FROM adverts WHERE owner=?");
    $query->execute($username);
    $query->finish();

}



=head2 advertsByUser

  Return a hash-ref of all the adverts that the given user has posted.

=cut

sub advertsByUser
{
    my ( $class, $username ) = (@_);

    my $db = Singleton::DBI->instance();
    my $sql = $db->prepare(
        "SELECT  id,link,linktext,text,owner FROM adverts WHERE owner=? ORDER by id ASC"
    );

    #
    # Get the details.
    #
    $sql->execute($username) or die $db->errstr();

    #
    # Bind the columns
    #
    my ( $id, $link, $linktext, $text, $owner );
    $sql->bind_columns( undef, \$id, \$link, \$linktext, \$text, \$owner );

    #
    #  The results we return
    #
    my $adverts = ();

    #
    #  Process the results
    #
    while ( $sql->fetch() )
    {
        push( @$adverts,
              {  id       => $id,
                 text     => $text,
                 link     => $link,
                 linktext => $linktext,
                 owner    => $owner,
              } );
    }

    # Finished with the query.
    $sql->finish();

    # return the requested values
    return ($adverts);
}



=head2 removeAdvert

 Remove an advert from the site.

=cut

sub removeAdvert
{
    my ( $class, $id ) = (@_);

    my $db  = Singleton::DBI->instance();
    my $sql = $db->prepare("DELETE FROM adverts WHERE id=?");
    $sql->execute($id);
    $sql->finish();
}



=head2 disableAdvert

 Disable an advert from the rotation

=cut

sub disableAdvert
{
    my ( $class, $id ) = (@_);

    my $db  = Singleton::DBI->instance();
    my $sql = $db->prepare("UPDATE adverts SET active='n' WHERE id=?");
    $sql->execute($id);
    $sql->finish();

}


=head2 enableAdvert

 Enable an advert in the rotation.

=cut

sub enableAdvert
{
    my ( $class, $id ) = (@_);

    my $db = Singleton::DBI->instance();
    my $sql = $db->prepare("UPDATE adverts SET active='y' WHERE id=?");
    $sql->execute($id);
    $sql->finish();

}



=head2 deleteAdvert

  Delete an advert

=cut

sub deleteAdvert
{
    my ( $class, $id ) = (@_);

    my $db = Singleton::DBI->instance();
    my $sql = $db->prepare("DELETE FROM adverts WHERE id=?");
    $sql->execute($id);
    $sql->finish();

}


=head2 fetchRandomAdvert

Fetch a random advert from the pool of available ones.

Choose only "enabled" adverts where the number of times that the
advert has been shown is less than the number of times it has been
paid to be displayed.

This will increase the "displayed" count - so it shouldn't be
called unless the advert is intended to be displayed.

=cut

sub fetchRandomAdvert
{
    my ($class) = (@_);

    my $db = Singleton::DBI->instance();
    my $sql = $db->prepare(
        "SELECT  id,link,linktext,text FROM adverts WHERE active='y' AND (shown < display) ORDER BY RAND() LIMIT 0,1"
    );

    #
    # Get the details.
    #
    $sql->execute() or die $db->errstr();
    my @details = $sql->fetchrow_array();
    $sql->finish();

    #
    #  Store the results
    #
    my %advert = ( id       => $details[0],
                   link     => $details[1],
                   linktext => $details[2],
                   text     => $details[3] );


    #
    #  Increase "shown" count but only if we did find an advert
    #
    my $id = $details[0];
    if ( defined($id) &&
         ( $id =~ /^([0-9]+)$/ ) )
    {
        $db->do("UPDATE adverts SET shown = shown + 1 WHERE id=$id");
        $class->{ 'id' } = $id;
        $class->invalidateCache();
    }
    return ( \%advert );
}



=head2 fetchAllActiveAdverts

Fetch all the adverts from the pool of active ones.

=cut

sub fetchAllActiveAdverts
{
    my ($class) = (@_);

    #
    # Attempt to fetch from the cache.
    #
    my $db = Singleton::DBI->instance();
    my $sql = $db->prepare(
        "SELECT  id,link,linktext,text,owner FROM adverts WHERE active='y' AND (shown < display) ORDER by id ASC"
    );

    #
    # Get the details.
    #
    $sql->execute() or die $db->errstr();

    #
    # Bind the columns
    #
    my ( $id, $link, $linktext, $text, $owner );
    $sql->bind_columns( undef, \$id, \$link, \$linktext, \$text, \$owner );

    #
    #  The results we return
    #
    my $adverts = ();

    #
    #  Process the results
    #
    while ( $sql->fetch() )
    {
        push( @$adverts,
              {  id       => $id,
                 text     => $text,
                 link     => $link,
                 linktext => $linktext,
                 owner    => $owner,
              } );
    }

    # Finished with the query.
    $sql->finish();

    return ($adverts);
}



=head2 fetchAllAdverts

Fetch all the adverts, that is both active and inactive ones.

=cut

sub fetchAllAdverts
{
    my ($class) = (@_);


    my $db = Singleton::DBI->instance();
    my $sql = $db->prepare(
        "SELECT  id,link,linktext,text,owner,active,shown,display FROM adverts ORDER by id ASC"
    );

    #
    # Get the details.
    #
    $sql->execute() or die $db->errstr();

    #
    # Bind the columns
    #
    my ( $id, $link, $linktext, $text, $owner, $active, $shown, $display );
    $sql->bind_columns( undef,  \$id,    \$link,   \$linktext,
                        \$text, \$owner, \$active, \$shown,
                        \$display
                      );

    #
    #  The results we return
    #
    my $adverts = ();

    #
    #  Process the results
    #
    while ( $sql->fetch() )
    {
        my $status = "Pending";

        if ( $active eq 'y' )
        {
            $status = "Active";
        }
        if ( $shown >= $display )
        {
            $status = "Finished";
        }

        push( @$adverts,
              {  id       => $id,
                 text     => $text,
                 link     => $link,
                 linktext => $linktext,
                 owner    => $owner,
                 state    => $status,
              } );
    }

    # Finished with the query.
    $sql->finish();

    return ($adverts);
}


=head2 invalidateCache

  Clean any cached content we might have.

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
