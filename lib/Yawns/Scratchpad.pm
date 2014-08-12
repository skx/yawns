# -*- cperl -*- #

=head1 NAME

Yawns::Scratchpad - A module for interfacing with a users's scratchpad text

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Scratchpad;
    use strict;

    my $pad = Yawns::Scratchpad->new( username => "username" );

    my $current = $pad->get();
    $pad->set( "This is my new text" );

=for example end


=head1 DESCRIPTION

This module will store an arbitary block of text inside a users
"scratchpad" area

The scratchpad notion is inspired by that used upon the PerlMonks
website.

=cut


package Yawns::Scratchpad;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.17 $' =~ m/Revision:\s*(\S+)/;


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


=head2 isPrivate

  Is the users scratchpad data private?

=cut

sub isPrivate
{
    my ($class) = (@_);

    #
    # Get the username
    #
    my $username = $class->{ 'username' };

    my $private = "";

    #
    #  Not found in memory, so fetch from the database.
    #
    my $db = Singleton::DBI->instance();
    my $query = $db->prepare(
        'SELECT a.security FROM scratchpads AS a INNER JOIN users AS b WHERE a.user_id=b.id AND b.username=?'
    );
    $query->execute($username) or die $db->errstr();
    $private = $query->fetchrow_array();

    # there is no scratchpad - so it is public.
    return 0 if ( !defined($private) );

    if ( $private =~ /^private$/i )
    {
        return 1;
    }
    else
    {
        return 0;
    }
}



=head2 get

  Find and return the user's scratchpad text.

=cut

sub get
{
    my ($class) = (@_);

    #
    # Get the username
    #
    my $username = $class->{ 'username' };

    #
    #  Attempt to fetch from the Memcache first.
    #
    my $text = "";


    #
    #  Not found in memory, so fetch from the database.
    #
    my $db = Singleton::DBI->instance();
    my $query = $db->prepare(
        'SELECT a.content FROM scratchpads AS a INNER JOIN users AS b WHERE a.user_id=b.id AND b.username=?'
    );
    $query->execute($username) or die $db->errstr();
    $text = $query->fetchrow_array();

    if ( !defined($text) ) {$text = "";}

    return ($text);
}

=head2 set

  Update the users scratchpad text

=cut

sub set
{
    my ( $class, $text, $private ) = (@_);

    #
    # Get the username
    #
    my $username = $class->{ 'username' };

    #
    # Make sure we have a privacy flag
    #
    die "No privacy setting" unless ( defined($private) );

    #
    #  Get the userid.
    #
    my $user    = Yawns::User->new( username => $username );
    my $data    = $user->get();
    my $user_id = $data->{ 'id' };

    #
    #  Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    #  Delete any current text.
    #
    my $query = $db->prepare("DELETE FROM scratchpads WHERE user_id=?");
    $query->execute($user_id);
    $query->finish();

    #
    #  Insert the new entry.
    #
    if ( defined($text) && length($text) )
    {
        $query = $db->prepare(
            'INSERT INTO scratchpads( user_id, content, security ) VALUES(?,?,?)'
        );
        $query->execute( $user_id, $text, $private ) or
          die "Failed to update scratchpad for '$username' -> " . $db->errstr();
        $query->finish();
    }

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

Copyright (c) 2005-2006 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut
