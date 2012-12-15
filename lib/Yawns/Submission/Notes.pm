# -*- cperl -*- #

=head1 NAME

Yawns::Submission::Notes - A module for leaving notes upon submissions.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Submission::Notes;
    use strict;

    # Create the object.
    my $handle = Yawns::Submission::Notes->new();

    #
    # Add a note to a submissions.
    #
    $handle->addSubmissionNote( submission => 222,
                                note       => "Foo",
                                username   => "Anonymous" );

    #
    # Retrieve all notes stored upon the given submission.
    #
    my $notes = $handle->getSubmissionNotes( 222 );

    #
    # Delete all notes stored against the specified submission.
    #
    $handle->deleteSubmissionNotes( 22 );

=for example end


=head1 DESCRIPTION

This module will store an arbitary block of text as submissio notes.

This is useful for when multiple article administrators wish to
communicate over the validity or contents of an article in the
submission queue.

=cut


package Yawns::Submission::Notes;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.5 $' =~ m/Revision:\s*(\S+)/;


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
use Yawns::Submissions;



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



=head2 addSubmissionNote

  Add a note against the given article in the submission queue.

=cut

sub addSubmissionNote
{
    my ( $self, %params ) = (@_);

    # Get the data.
    my $submission = $params{ 'submission' } || $self->{ 'submission' };
    my $note       = $params{ 'note' }       || $self->{ 'note' };
    my $username   = $params{ 'username' }   || $self->{ 'username' };

    # Make sure each parameter is specified.
    die "No username"   unless ( defined $username );
    die "No note"       unless ( defined $note );
    die "No submission" unless ( defined $submission );

    #  Get the database handle.
    my $dbi = Singleton::DBI->instance();

    #  Get the user id.
    my $user    = Yawns::User->new( username => $username );
    my $data    = $user->get();
    my $user_id = $data->{ 'id' };

    #
    #  Insert
    #
    my $sql = $dbi->prepare(
        "INSERT INTO submission_notes (user_id, sub_id, note, ondate ) VALUES( ?, ?,?, NOW() )"
    );
    $sql->execute( $user_id, $submission, $note ) or
      die "Failed to insert " . $dbi->errstr();
    $sql->finish();

}



=head2 getSubmissionNotes

  Retrieve the notes recorded against the given submission.

=cut

sub getSubmissionNotes
{
    my ( $self, $submission ) = (@_);

    # Make sure we have a submission ID.
    die "No submission" unless ( defined $submission );

    #
    #  Get from the database.
    #
    my $dbi = Singleton::DBI->instance();

    #
    #  Select
    #
    my $sql = $dbi->prepare(
        "SELECT a.username,b.note,b.ondate FROM submission_notes AS b INNER JOIN users a WHERE a.id=b.user_id AND b.sub_id=? ORDER BY b.id ASC"
    );
    $sql->execute($submission) or die "Failed to execute" . $dbi->errstr();

    #
    #  Bind
    #
    my ( $username, $note, $ondate );
    $sql->bind_columns( undef, \$username, \$note, \$ondate );

    my $notes;

    #
    #  Store.
    #
    while ( $sql->fetch() )
    {

        # convert date and time to more readable format
        my @posted = Yawns::Date::convert_date_to_site($ondate);

        push( @$notes,
              {  username => $username,
                 note     => $note,
                 ondate   => $posted[0],
                 attime   => $posted[1],
              } );
    }

    # Cleanup
    $sql->finish();

    return ($notes);
}



=head2 deleteSubmissionNotes

  Delete any stored note against the specified submission.

=cut

sub deleteSubmissionNotes
{
    my ( $self, $submission ) = (@_);

    # Make sure we have a submission ID.
    die "No submission" unless ( defined $submission );

    #
    #  Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    # Delete the notes.
    #
    my $sql = $db->prepare("DELETE FROM submission_notes WHERE sub_id=?");
    $sql->execute($submission);
    $sql->finish();

}



=head2 invalidateCache

  Clean any cached content we might have.

=cut

sub invalidateCache
{
    my ( $class, $submission ) = (@_);

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
