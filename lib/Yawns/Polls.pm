# -*- cperl -*- #

=head1 NAME

Yawns::Polls - A module for working with polls.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Polls;
    use strict;

    my $polls = Yawns::Polls->new();

    $polls->add( question => "Does this work?",
                 author   => "Steve",
                 answers  => [ "one", "two", "three"] );

    my $current = $polls->getCurrentPoll();

=for example end


=head1 DESCRIPTION

This module contains code for working with polls, finding the
current one and adding a new one.

See Yawns::Poll for working with a particular poll.


=cut


package Yawns::Polls;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);


require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.13 $' =~ m/Revision:\s*(\S+)/;



#
#  Standard modules which we require.
#
use strict;
use warnings;


#
#  Yawns modules which we use.
#
use Singleton::DBI;
use Yawns::Tags;


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

  Add a new poll, which will go live immediately.

=cut

sub add
{
    my ( $class, %parameters ) = (@_);

    my $question = $parameters{ 'question' };
    my $author   = $parameters{ 'author' };
    my $id       = $parameters{ 'id' };
    my $answers  = $parameters{ 'answers' };

    my @answers = @$answers;

    if ( !defined($id) )
    {
        $id = $class->getCurrentPoll();
        $id += 1;
    }

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();


    #
    #  Insert the question
    #
    my $ins = $db->prepare(
        "INSERT INTO poll_questions (id,survey_id,question,total_votes,author, ondate) VALUES( ?, ?, ?, ?, ?, NOW() )"
    );
    $ins->execute( $id, '0', $question, '0', $author ) or die $db->errstr();
    $ins->finish();

    #
    # Now insert each of the answers.
    #
    my $count = 1;
    foreach my $choice (@answers)
    {
        my $tmp = $db->prepare(
             "INSERT INTO poll_answers (id, poll_id, answer) VALUES ( ?, ?, ? )"
        );
        $tmp->execute( $count, $id, $choice );
        $tmp->finish();
        $count += 1;
    }

    #
    # Return the current poll.
    return ($id);
}



=head2 getCurrentPoll

  Return the ID of the current poll.

=cut

sub getCurrentPoll
{
    my ($class) = (@_);

    my $db = Singleton::DBI->instance();

    # get the id of the most recent poll.
    my $query = $db->prepare('SELECT MAX(id) FROM poll_questions');
    $query->execute();
    my $poll = $query->fetchrow_array();

    return ($poll);

}



=head2 delete

 Delete an existing poll.

=cut

sub delete
{
    my ( $class, %parameters ) = (@_);

    my $id = $parameters{ 'id' };
    if ( !defined($id) )
    {
        $id = $class->{ 'id' };
    }

    die "No ID" if ( !defined($id) );

    #
    #  Get database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    # Delete the question
    #
    my $query = $db->prepare("DELETE FROM poll_questions WHERE id=?");
    $query->execute($id);
    $query->finish();

    #
    # Delete the anonymous votes
    #
    $query = $db->prepare("DELETE FROM poll_anon_voters WHERE poll_id=?");
    $query->execute($id);
    $query->finish();

    #
    # Delete the registered votes
    #
    $query = $db->prepare("DELETE FROM poll_voters WHERE poll_id=?");
    $query->execute($id);
    $query->finish();


    #
    # Delete the answers
    #
    $query = $db->prepare("DELETE FROM poll_answers WHERE poll_id=?");
    $query->execute($id);
    $query->finish();


    #
    # Delete any comments
    #
    $query = $db->prepare("DELETE FROM comments WHERE root=? AND type='p'");

    $query->execute($id);
    $query->finish();

    #
    # Delete the tags on this poll
    #
    my $tags = Yawns::Tags->new();
    $tags->deleteTags( poll => $id );
}



=head2 getPollArchive

  Return all the old polls in use.

=cut

sub getPollArchive
{
    my ($class) = (@_);


    #
    # Not in cache, so fetch from the database.
    #
    my $db = Singleton::DBI->instance();

    #
    # Prepare the query.
    #
    my $query = $db->prepare(
          'SELECT id,question FROM poll_questions WHERE id>0 ORDER BY id DESC');
    $query->execute() or die $db->errstr();


    #
    #  Bind the results.
    #
    #
    my ( $id, $question );
    $query->bind_columns( undef, \$id, \$question );


    my $polls;

    #
    #  Fetch
    #
    while ( $query->fetch() )
    {
        push( @$polls,
              {  id       => $id,
                 question => $question,
              } );

    }

    #
    # Update the cache.
    #
    return ($polls);
}



=head2 invalidateCache

  Clean any cached content we might have.

=cut

sub invalidateCache
{
    my ($class) = (@_);
}



1;
