# -*- cperl -*- #

=head1 NAME

Yawns::Poll - A module for working with a specific poll.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Poll;
    use strict;

    my $poll = Yawns::Poll->new( id => 2 );

    my $commentCount = $poll->commentCount();

=for example end


=head1 DESCRIPTION

This module contains code for dealing with a single poll upon the
site.

=cut


package Yawns::Poll;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);


require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.9 $' =~ m/Revision:\s*(\S+)/;



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



=head2 commentCount

  Return the number of comments upon the given poll.

=cut

sub commentCount
{
    my ($class) = (@_);

    #
    # Get the ID of the poll we're working with.
    #
    my $id = $class->{ 'id' };
    die "No poll ID " if !defined($id);

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    # Run the query.
    #
    my $query = $db->prepare(
           'SELECT COUNT(*) FROM comments WHERE score>0 AND root=? AND type=?');
    $query->execute( $id, 'p' );
    my $count = $query->fetchrow_array();

    return ($count);

}



=head2 get

  Get the questions and current answers from the given poll.

  Note: you should use getTitle if you only care about the title.

=cut

sub get
{
    my ($class) = (@_);

    #
    # Get the poll ID
    #
    my $id = $class->{ id };
    die "No poll ID" if !defined($id);

    #
    # Get from the database.
    #
    my $db = Singleton::DBI->instance();


    #
    # get the question and total votes
    #
    my $query = $db->prepare(
        'SELECT question,total_votes,author,ondate FROM poll_questions WHERE id=?'
    );
    $query->execute($id);

    my ( $question, $total, $author, $date ) = $query->fetchrow_array();

    # get answers and their respective votes
    my $query2 = $db->prepare(
        'SELECT answer,votes,id FROM poll_answers WHERE poll_id=? ORDER BY id');
    $query2->execute($id);
    my $answers = $query2->fetchall_arrayref();

    return ( $question, $total, $answers, $author, $date );
}



=head2 vote

  Allow the user to vote upon a poll.

=cut

sub vote
{
    my ( $class, %params ) = (@_);

    #
    # Get the poll ID
    #
    my $id = $class->{ id };
    die "No poll ID" if !defined($id);

    #
    #  Get the IP address and voting choice.
    #
    my $ip_address = $params{ 'ip_address' };
    my $choice     = $params{ 'choice' };
    my $username   = $params{ 'username' } || "Anonymous";

    die "No IP address"  unless defined($ip_address);
    die "No vote choice" unless defined($choice);

    $ip_address =~ s/^::ffff://g;


    my $db = Singleton::DBI->instance();


    if ( $username =~ /^anonymous$/i )
    {
        my $q10 = $db->prepare(
            'SELECT ip_address FROM poll_anon_voters WHERE ip_address=? AND poll_id=?'
        );
        $q10->execute( $ip_address, $id );
        my ($ip_voted) = $q10->fetchrow_array();

        if ($ip_voted)
        {

            # anon already voted - explain, suggest they create a user account
            return ( $ip_address, 0, 0 );
        }
        else
        {
            my $q11 =
              $db->prepare('INSERT INTO poll_anon_voters VALUES ( ?, ? )');
            $q11->execute( $ip_address, $id );
            my $q12 = $db->prepare(
                'UPDATE poll_answers SET votes=votes+1 WHERE id=? AND poll_id=?'
            );
            $q12->execute( $choice, $id );
            my $q13 = $db->prepare(
                'update poll_questions set total_votes=total_votes+1 WHERE id=?'
            );
            $q13->execute($id);
        }
    }
    else
    {
        my $q20 = $db->prepare(
            'SELECT answer_id FROM poll_voters WHERE username=? AND poll_id=?');
        $q20->execute( $username, $id );
        my ($prev_vote) = $q20->fetchrow_array();

        my $q21 = $db->prepare('REPLACE INTO poll_voters VALUES ( ?, ?, ? )');
        $q21->execute( $username, $id, $choice );

        my $q22 = $db->prepare(
              'UPDATE poll_answers SET votes=votes+1 WHERE id=? AND poll_id=?');
        $q22->execute( $choice, $id );

        if ($prev_vote)
        {
            my $q23 = $db->prepare(
                'UPDATE poll_answers SET votes=votes-1 WHERE id=? AND poll_id=?'
            );
            $q23->execute( $prev_vote, $id );

            return ( 0, $prev_vote, $choice );
        }
        else
        {
            my $q25 = $db->prepare(
                'UPDATE poll_questions SET total_votes=total_votes+1 WHERE id=?'
            );
            $q25->execute($id);
        }
    }

    return ( 0, 0, 0 );
}



=head2 getTitle

  Find and return the title of the current poll.

=cut

sub getTitle
{
    my ($class) = (@_);

    #
    # Get the poll ID
    #
    my $id = $class->{ id };
    die "No poll ID" if !defined($id);

    #
    #  Attempt to fetch from database.
    #
    my $db    = Singleton::DBI->instance();
    my $query = "SELECT question FROM poll_questions WHERE id=?";
    my $sql   = $db->prepare($query);
    $sql->execute($id);
    my @ret   = $sql->fetchrow_array();
    my $title = $ret[0];
    $sql->finish();

    return ($title);
}



=head2 getVoteCount

  Find and return the number of votes made upon this poll.

=cut

sub getVoteCount
{
    my ($class) = (@_);

    #
    # Get the poll ID
    #
    my $id = $class->{ id };
    die "No poll ID" if !defined($id);

    #
    #  Attempt to fetch from database.
    #
    my $db    = Singleton::DBI->instance();
    my $query = "SELECT total_votes FROM poll_questions WHERE id=?";
    my $sql   = $db->prepare($query);
    $sql->execute($id);
    my @ret = $sql->fetchrow_array();
    my $count = $ret[0] || 0;
    $sql->finish();

    return ($count);
}



=head2 invalidateCache

  Clean any cached content we might have.

=cut

sub invalidateCache
{
    my ($class) = (@_);

    my $id = $class->{ 'id' };
    die "No poll ID " if !defined($id);

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
