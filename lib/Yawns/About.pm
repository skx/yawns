# -*- cperl -*- #

=head1 NAME

Yawns::About - A module for working with the static "about" pages.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::About;
    use strict;

    my $about = Yawns::About->new();

    my @all   = $about->get();

    foreach my $page ( @all )
    {
       my $text = $about->get( name => $page );
    }

=for example end


=head1 DESCRIPTION

This module deals with the static "about" pages we contain.

=cut


package Yawns::About;

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
use Singleton::Memcache;



=head2 new

  Create a new instance of this object.

=cut

sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};

    bless( $self, $class );
    return $self;

}


=head2 get

  Find and return the given static page text.

=cut

sub get
{
    my ( $class, %parameters ) = (@_);

    #
    # Get the page name
    #
    my $name = $parameters{ 'name' };

    #
    # If we have no name then return all page names in a hash.
    #
    if ( !defined($name) )
    {
        return ( _get_page_names() );
    }


    #
    #  Attempt to fetch from the cache
    #
    my $cache = Singleton::Memcache->instance();
    my $text  = "";
    $text = $cache->get("about_$name");
    if ($text)
    {
        return ($text);
    }

    #
    #  Objects we use.
    #
    my $db = Singleton::DBI->instance();

    # fetch the required data
    my $sql = $db->prepare("SELECT bodytext FROM about_pages WHERE id = ?");
    $sql->execute($name);
    $text = $sql->fetchrow_array();
    $sql->finish();

    if ( defined($text) )
    {
        $cache->set( "about_$name", $text );
    }

    # return
    return ($text);
}



=head2 set

  Set the text for a given about page.

=cut

sub set
{
    my ( $class, %parameters ) = (@_);

    #
    # Get the page name and new text
    #
    my $name = $parameters{ 'name' };
    my $text = $parameters{ 'text' };

    #
    # Make sure we have a name, and text.
    die "No page name" if ( !defined($name) );
    die "No page text" if ( !defined($text) );


    #
    # Get database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    #  Delete the page text.
    #
    my $sql = $db->prepare("delete from about_pages where id = ?");
    $sql->execute($name);
    $sql->finish();

    #
    #  Now insert the new text.
    #
    $sql = $db->prepare("insert into about_pages values (?, ?)");
    $sql->execute( $name, $text );
    $sql->finish();

    #
    # Remove the old cached text.
    #
    $class->invalidateCache( name => $name );
}



=head2 delete

  Delete the given about page.

=cut

sub delete
{
    my ( $class, %parameters ) = (@_);

    #
    # Get the page name and new text
    #
    my $name = $parameters{ 'name' };

    #
    # Make sure we have a name, and text.
    die "No page name" if ( !defined($name) );

    #
    # Get database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    #  Delete the page text.
    #
    my $sql = $db->prepare("delete from about_pages where id = ?");
    $sql->execute($name);
    $sql->finish();

    #
    # Remove the old cached text.
    #
    $class->invalidateCache( name => $name );
}



=head2 _get_page_names

  Return an array of all the about pages we contain.

=cut

sub _get_page_names
{

    #
    #  Objects we use.
    #
    my $db = Singleton::DBI->instance();

    # fetch the required data
    my $sql = $db->prepare("SELECT id FROM about_pages");
    $sql->execute;

    #
    # Bind columns for fetching.
    #
    my ($id);
    $sql->bind_columns( undef, \$id );

    #
    # Results we'll return.
    #
    my @page_list;

    #
    # Add each ID to the array.
    #
    while ( $sql->fetch() )
    {
        push( @page_list, { id => $id } );
    }
    $sql->finish();

    return ( \@page_list );
}



=head2 invalidateCache

  Clean any cached content we might have.

=cut

sub invalidateCache
{
    my ( $class, %parameters ) = (@_);

    my $name = $parameters{ 'name' };

    #
    #  Flush the cached data
    #
    my $cache = Singleton::Memcache->instance();
    $cache->delete("about_pages");
    $cache->delete("about_$name");
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
