# -*- cperl -*- #

=head1 NAME

Yawns::Submission - A module for interfacing with queued polls/articles

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Submissions;
    use strict;

    my $queue = Yawns::Submissions->new();

    #
    # Get counts of pending things.
    #
    my $articles = $queue->articleCount();
    my $polls    = $queue->pollCount();


=for example end


=head1 DESCRIPTION

This module will interface with the submissions queue, allowing the
number of polls and articles in the queues to be determined and
worked with.

=cut


package Yawns::Submissions;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.58 $' =~ m/Revision:\s*(\S+)/;


#
#  Standard modules which we require.
#
use strict;
use warnings;

use HTML::Entities;


#
#  Yawns modules which we use.
#
use conf::SiteConfig;
use Singleton::DBI;

use Yawns::Article;
use Yawns::Date;
use Yawns::RSS;
use Yawns::Submission::Notes;
use Yawns::Polls;
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



=head2 maxID

  Return the maximum ID of the submissions.

=cut

sub maxID
{
    my ($class) = (@_);

    #
    # Get the maximum submission ID.
    #
    my $db    = Singleton::DBI->instance();
    my $query = "SELECT MAX(id) FROM submissions";
    my $sql   = $db->prepare($query);
    $sql->execute();
    my @ret = $sql->fetchrow_array();
    my $num = $ret[0] || 0;
    $sql->finish();

    return ($num);
}


=head2 articleCount

  Find and return the number of pending articles in the queue.

=cut

sub articleCount
{
    my ($class) = (@_);

    #
    # Get the count of pending items from the database.
    #
    my $db    = Singleton::DBI->instance();
    my $query = $db->prepare('SELECT COUNT(id) FROM submissions');
    $query->execute();
    my $count = $query->fetchrow_array();

    return ($count);
}



=head2 articleCountByUsername

  Find and return the number of pending articles in the queue by the given
 user.

=cut

sub articleCountByUsername
{
    my ($class) = (@_);

    #
    #  Get the username.
    #
    my $username = $class->{ username };
    die "No username" unless defined($username);


    #
    #  Since this code is only used in the sidebar we can
    # only care for non-anonymous users.
    #
    return 0 if ( $username =~ /^anonymous$/i );


    #
    # Get the count of pending items from the database.
    #
    my $db = Singleton::DBI->instance();
    my $query = $db->prepare(
        'SELECT COUNT(a.id) FROM submissions AS a INNER JOIN users AS b WHERE a.user_id=b.id AND b.username=?'
    );
    $query->execute($username) or die "Failed to execute: " . $db->errstr();
    my $count = $query->fetchrow_array();

    return ($count);
}



=head2 articlesByUser

  Return a hash-ref of all the articles that the given user
 has posted.

=cut

sub articlesByUser
{
    my ($class) = (@_);

    #
    #  Find the username
    #
    my $username = $class->{ username };
    my $details;


    #
    # Gain access to the database handle
    #
    my $db = Singleton::DBI->instance();

    # get required data
    my $sql = $db->prepare(
        'SELECT a.id,a.title FROM submissions AS a INNER JOIN users AS b WHERE a.user_id=b.id AND b.username=? ORDER BY id ASC'
    );
    $sql->execute($username) or die "Failed: " . $db->errstr();

    #
    # Bind the columns
    #
    my ( $id, $title );
    $sql->bind_columns( undef, \$id, \$title );

    #
    #  The results we return
    #
    my $submissions = ();

    #
    #  Process the results
    #
    while ( $sql->fetch() )
    {
        push( @$submissions,
              {  id    => $id,
                 title => $title,
              } );
    }

    # Finished with the query.
    $sql->finish();

    # return the requested values
    return ($submissions);
}



=head2 getArticleAuthor

  Return the author of the submitted article with the given ID, this is
 used to see if a logged in user may edit the given submission.

=cut

sub getArticleAuthor
{
    my ( $class, $id ) = (@_);

    #
    # Fetch the author.
    #
    my $db = Singleton::DBI->instance();
    my $query = $db->prepare(
        'SELECT a.username FROM users AS a INNER JOIN submissions AS b WHERE a.id=b.user_id AND b.id=?'
    );
    $query->execute($id) or die $db->errstr();
    my $author = $query->fetchrow_array();

    return ($author);
}



=head2 pollCount

  Find and return the number of pending polls in the submission queue.

=cut

sub pollCount
{
    my ($class) = (@_);


    #
    # Get the count of pending items from the database.
    #
    my $db    = Singleton::DBI->instance();
    my $query = $db->prepare('SELECT COUNT(id) FROM poll_submissions');
    $query->execute();
    my $count = $query->fetchrow_array();

    return ($count);
}


=head2 getPolls

  Return all the polls in the submission queue.

=cut

sub getPolls
{
    my ($class) = (@_);

    #
    # Gain access to the database handle
    #
    my $db = Singleton::DBI->instance();

    # get required data
    my $sql = $db->prepare('SELECT * FROM poll_submissions ORDER BY id ASC');
    $sql->execute();

    my $sub_ref = $sql->fetchall_arrayref;
    my @sublist = @$sub_ref;
    my $sub_len = @sublist;

    $sql->finish();

    my $submissions = ();
    foreach (@sublist)
    {
        my @subdata = @$_;


        my $answers;

        # Now find the relevant answers.
        my $sql2 = $db->prepare(
            'SELECT answer,id FROM poll_submissions_answers WHERE poll_id = ? ORDER BY id ASC'
        );
        $sql2->execute( $subdata[0] );
        my ( $ans, $id );
        $sql2->bind_columns( undef, \$ans, \$id );
        my $width = 0;
        while ( $sql2->fetch() )
        {
            $width += 20;
            push( @$answers,
                  {  width  => $width,
                     answer => $ans,
                     id     => $id,
                  } );
        }
        $sql2->finish();


        #
        # Strip faux IPv6 prefix, introduced by nginx
        #
        my $ip = $subdata[2];
        $ip =~ s/^::ffff://g;

        push( @$submissions,
              {  id           => $subdata[0],
                 author       => $subdata[1],
                 ip           => $ip,
                 question     => $subdata[3],
                 ondate       => $subdata[4],
                 poll_answers => $answers,
              } );
    }
    $sql->finish();

    # return the requested values
    return ($submissions);

}



=head2 getArticleOverview

  Return the name, title, author and lead text off a pending article.

  This is used for the submissions list.

=cut

sub getArticleOverview
{
    my ($class) = (@_);

    #
    # Gain access to the database handle
    #
    my $db = Singleton::DBI->instance();

    #
    #  Prepare the query.
    #
    my $sql = $db->prepare(
        'SELECT a.id,a.title,b.username,a.bodytext,a.ip FROM submissions AS a INNER JOIN users AS b WHERE a.user_id=b.id ORDER BY id ASC'
    );
    $sql->execute() or die $db->errstr();

    my ( $id, $title, $author, $bodytext, $ip );
    $sql->bind_columns( undef, \$id, \$title, \$author, \$bodytext, \$ip );


    #
    #  The results we return.
    #
    my $resultsloop = [];

    #
    #  Process each result.
    #
    while ( $sql->fetch() )
    {

        #
        #  Cut the bodytext into the lead in the same way as the article
        # submission would.
        #
        my $leadtext = $bodytext;
        if ( $leadtext =~ m/^(.+?)\n+.*/ ) {$leadtext = $1;}
        $leadtext = "<p>" . $leadtext  unless $leadtext =~ m/<p>/;
        $leadtext = $leadtext . "</p>" unless $leadtext =~ m/<\/p>/;


        #
        # Strip faux IPv6 prefix, introduced by nginx
        #
        $ip =~ s/^::ffff://g;

        push( @$resultsloop,
              {  id        => $id,
                 title     => $title,
                 byuser    => $author,
                 lead_text => $leadtext,
                 ip        => $ip,
              } );
    }
    $sql->finish();

    #
    # Return the data.
    #
    return ($resultsloop);
}



=head2 getArticleFeed

  Return all the pending submissions in a form suitable for use in an
 RSS feed.

  This correctly escapes the HTML in the submission title and body.

=cut

sub getArticleFeed
{
    my ($class) = (@_);


    #
    # Not cached, so fetch from the database.
    #
    my $db = Singleton::DBI->instance();

    #
    #  Prepare the query.
    #
    my $sql = $db->prepare(
        'SELECT a.id,a.title,b.username,a.bodytext FROM submissions AS a INNER JOIN users AS b WHERE a.user_id=b.id ORDER BY id ASC'
    );
    $sql->execute() or die $db->errstr();

    my ( $id, $title, $author, $bodytext );
    $sql->bind_columns( undef, \$id, \$title, \$author, \$bodytext );


    my $list;

    #
    #  Process each result.
    #
    while ( $sql->fetch() )
    {
        $title    = encode_entities($title);
        $bodytext = encode_entities($bodytext);

        push( @$list,
              {  id       => $id,
                 title    => $title,
                 byuser   => $author,
                 bodytext => $bodytext,
              } );
    }
    $sql->finish();

    #
    # Return the data.
    #
    return ($list);
}


=head2 addArticle

  Add a new article to the article queue.

=cut

sub addArticle
{
    my ( $class, %params ) = (@_);

    #
    # Get the details.
    #
    my $title    = $params{ 'title' } || "";
    my $author   = $params{ 'author' };
    my $ip       = $params{ 'ip' };
    my $bodytext = $params{ 'bodytext' };

    #
    #  Trim the title.
    #
    $title =~ s/^\s+|\s+$//g;


    #
    #  Make sure the author is stored.
    #
    $class->{ username } = $author;

    #
    #  Get the user_id.
    #
    my $user    = Yawns::User->new( username => $author );
    my $data    = $user->get();
    my $user_id = $data->{ 'id' };

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    # Get the next submission ID.
    my $query = "SELECT MAX(id) FROM submissions";
    my $sql   = $db->prepare($query);
    $sql->execute();
    my @ret = $sql->fetchrow_array();
    my $num = $ret[0] || 0;
    $num += 1;
    $sql->finish();

    #
    #  Do the insertion.
    #
    $sql = $db->prepare(
        "INSERT INTO submissions (id,title,user_id,bodytext,ip,ondate) VALUES( ?, ?, ?, ?, ?, NOW() )"
    );

    $sql->execute( $num, $title, $user_id, $bodytext, $ip ) or
      die "Error - " . $db->errstr();
    $sql->finish();

    #
    # Send a mail, unless we're not supposed to.  (That'll mean we're
    # running the testing code..
    #
    if ( !$params{ 'quiet' } )
    {
        $class->sendMail( author   => $author,
                          title    => $title,
                          bodytext => $bodytext
                        );
    }


    #
    # Return the new submission ID, which is useful for testing.
    #
    return ($num);
}



=head2 getSubmission

  Return details about the specified submission.

=cut

sub getSubmission
{
    my ( $self, $id ) = (@_);

    # get submission data
    my $db = Singleton::DBI->instance();
    my $sql = $db->prepare(
        'SELECT a.title,b.username,a.bodytext,a.ip FROM submissions AS a INNER JOIN users AS b WHERE a.user_id=b.id AND a.id=?'
    );
    $sql->execute($id) or die "Failed " . $db->errstr();

    my ( $title, $author, $bodytext, $ip ) = $sql->fetchrow_array();
    $sql->finish();


    #
    # Get the tags associated with this submission too.
    #
    my $holder       = Yawns::Tags->new();
    my $current      = $holder->getTags( submission => $id );
    my $current_tags = '';


    foreach my $t (@$current)
    {
        my $tag = $t->{ 'tag' };

        # Make sure we have seperators for the tags.
        if ( defined($current_tags) && length($current_tags) )
        {
            $current_tags .= ", ";
        }

        $current_tags .= $tag;
    }


    #
    # Strip faux IPv6 prefix, introduced by nginx
    #
    $ip =~ s/^::ffff://g;

    #
    #  Now setup the data for the caller.
    #
    my %result;
    $result{ 'bodytext' }     = $bodytext;
    $result{ 'author' }       = $author;
    $result{ 'ip' }           = $ip;
    $result{ 'current_tags' } = $current_tags;
    $result{ 'title' }        = $title;

    return (%result);
}



=head2 getSubmissionNotes

  Get the notes associated with the given submission.

=cut

sub getSubmissionNotes
{
    my ( $self, $id ) = (@_);

    my $holder = Yawns::Submission::Notes->new();
    return ( $holder->getSubmissionNotes($id) );
}



=head2 addSubmissionNote

  Add a note to a submission

=cut

sub addSubmissionNote
{
    my ( $self, %params ) = (@_);

    # Get the data.
    my $submission = $params{ 'submission' } || $self->{ 'submission' };
    my $note       = $params{ 'note' }       || $self->{ 'note' };
    my $username   = $params{ 'username' }   || $self->{ 'username' };

    die "No username"   unless ( defined $username );
    die "No note"       unless ( defined $note );
    die "No submission" unless ( defined $submission );


    my $holder = Yawns::Submission::Notes->new();
    $holder->addSubmissionNote( submission => $submission,
                                note       => $note,
                                username   => $username
                              );
}



=head2 updateSubmission

  Update an article in the submissions queue.  This means that we'll
 change the text, title, etc.

=cut

sub updateSubmission
{
    my ( $self, %params ) = (@_);

    #
    #  Gain access to the database.
    #
    my $dbh = Singleton::DBI->instance();

    #
    #  Get the details.
    #
    my $title    = $params{ 'title' };
    my $id       = $params{ 'id' };
    my $bodytext = $params{ 'bodytext' };
    my $author   = $params{ 'author' };
    my $tags     = $params{ 'tags' };

    #
    #  Strip leading/trailing space
    #
    $title =~ s/^\s+|\s+$//g;

    #
    #  Get the *old* details - for the case where authorship changes.
    #
    #  Note:  caching is based upon author username..
    #
    my %old = $self->getSubmission($id);


    #
    # Get the user_id.
    #
    my $user    = Yawns::User->new( username => $author );
    my $data    = $user->get();
    my $user_id = $data->{ 'id' };

    #
    #  Update the submission.
    #
    my $sql = $dbh->prepare(
              "UPDATE submissions SET title=?,user_id=?,bodytext=? WHERE id=?");
    $sql->execute( $title, $user_id, $bodytext, $id ) or
      die "Failed to update submission " . $dbh->errstr();
    $sql->finish();

    #
    #  Update the tags, just in case they changed.
    #
    my $holder = Yawns::Tags->new();
    $holder->deleteTags( submission => $id );

    if ( defined($tags) && length($tags) )
    {

        #
        # Add the new ones.
        #
        foreach my $t ( split( /,/, $tags ) )
        {

            # Strip leading and trailing whitespace.
            $t =~ s/^\s+|\s+$//g;

            $holder->addTag( submission => $id,
                             tag        => $t );
        }
    }


}



=head2 sendMail

  Send the site administrator an email telling them of the new article
 submission.

=cut

sub sendMail
{
    my ( $class, %params ) = (@_);

    my $author = $params{ 'author' };
    my $title  = $params{ 'title' };
    my $body   = $params{ 'bodytext' };

    #
    # Find all the users with the "article_admin" privilege.
    #
    my $perms = Yawns::Permissions->new();
    my @users = $perms->findWith("article_admin");

    #
    #  Get the mailer object.
    #
    my $mailer = Yawns::Mailer->new();


    #
    #  Notify each user who wants it
    #
    foreach my $person (@users)
    {
        my @h = @$person;

        foreach my $entry (@h)
        {
            my $user = $entry->{ 'username' };
            next unless defined($user);

            #
            #  See what notification method this administrator has
            # selected for new article submissions.
            #
            my $prefs = Yawns::Comment::Notifier->new( username => $user );
            my $method = $prefs->getNotificationMethod( $user, "submissions" );

            #
            #  We either handle mail or nothing.  No site messages.
            #
            if ( $method =~ /^email$/i )
            {

                #
                #  Get the email address of that user.
                #
                my $u         = Yawns::User->new( username => $user );
                my $d         = $u->get();
                my $recipient = $d->{ 'realemail' };

                #
                # Send a mail
                #
                $mailer->newArticleSubmission( $recipient, $author, $title,
                                               $body );
            }
            else
            {

                # nop
            }
        }
    }
}



=head2 rejectArticle

  Reject an article from the submissions queue - it is silently deleted.

=cut

sub rejectArticle
{
    my ( $class, $id ) = (@_);

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    # Perform the deletion, but save the username first.
    #
    $class->{ username } = $class->getArticleAuthor($id);
    my $sql = $db->prepare('DELETE FROM submissions WHERE id=?');
    $sql->execute($id);
    $sql->finish();

    #
    # Delete any pending tags
    #
    my $holder = Yawns::Tags->new();
    $holder->deleteTags( submission => $id );

    #
    # Delete any notes
    #
    my $notes = Yawns::Submission::Notes->new();
    $notes->deleteSubmissionNotes($id);


}



=head2 postArticle

  Post an article from the submissions queue to the front page.

=cut

sub postArticle
{
    my ( $class, $id ) = (@_);

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    # get submission data
    #
    my $sql = $db->prepare(
        'SELECT a.title,b.username,a.bodytext FROM submissions AS a INNER JOIN users AS b WHERE a.user_id=b.id AND a.id=?'
    ) or die $db->errstr();
    $sql->execute($id) or die $db->errstr();

    my ( $title, $author, $bodytext ) = $sql->fetchrow_array();

    #
    # Create the new article
    #
    my $article = Yawns::Article->new();
    my $new_id = $article->create( title  => $title,
                                   author => $author,
                                   body   => $bodytext
                                 );

    #
    #  Get all the pending tags, and post them to the newly published article.
    #
    my $holder = Yawns::Tags->new();
    my $tags = $holder->promoteSubmissionTags( $id, $new_id );


    #
    # Delete the article from queue after it has been pushed out.
    #
    $class->rejectArticle($id);

    #
    #  Invalidate the articles & hall of fame count.
    #
    my $articles = Yawns::Articles->new();
    $articles->invalidateCache();

    my $hof = Yawns::Stats->new();
    $hof->invalidateCache();

}


=head2 addPoll

  Add a new poll to the submissions queue.

=cut

sub addPoll
{
    my ( $class, $c, %params ) = (@_);

    my $author   = $params{ 'author' };
    my $ip       = $params{ 'ip' };
    my $question = $params{ 'question' };

    my @choices = @{ $c };


    #
    # Get database handle
    #
    my $db = Singleton::DBI->instance();

    #
    #  Find the ID to use for the new poll question.
    #
    my $query = "SELECT MAX(id) FROM poll_submissions";
    my $sql   = $db->prepare($query);
    $sql->execute();
    my @ret = $sql->fetchrow_array();
    my $num = $ret[0] || 0;
    $num += 1;
    $sql->finish();

    #
    #  Insert the question.
    #
    $query =
      "INSERT INTO poll_submissions (id, question, ip, author, ondate) VALUES( ?, ? , ?, ?, NOW() )";
    $sql = $db->prepare($query);
    $sql->execute( $num, $question, $ip, $author );
    $sql->finish();


    #
    #  Now the answers.
    #
    $query =
      "INSERT INTO poll_submissions_answers (id, poll_id, answer) VALUES( ?, ?, ? )";
    $sql = $db->prepare($query);

    my $count = 1;
    foreach my $option (@choices)
    {
        if ( length($option) )
        {
            $sql->execute( $count, $num, $option ) or die $db->errstr();
            $count++;
        }

    }
    $sql->finish();


    #
    # Return the new submission ID, which is useful for testing.
    #
    return ($num);

}



=head2 rejectPoll

  Delete a pending poll from the queue.

=cut

sub rejectPoll
{
    my ( $class, $id ) = (@_);


    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    # Delete the poll
    #
    my $sql1 = $db->prepare("DELETE FROM poll_submissions WHERE id=?");
    $sql1->execute($id);

    #
    # Delete the options.
    #
    my $sql2 =
      $db->prepare("DELETE FROM poll_submissions_answers WHERE poll_id=?");
    $sql2->execute($id);

}



=head2 editPendingPoll

  Edit a pending poll

=cut

sub editPendingPoll
{
    my ( $self, $id, %params ) = (@_);

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    #  Update the title, if defined.
    #
    if ( defined( $params{ 'author' } ) )
    {
        my $sql =
          $db->prepare("UPDATE poll_submissions SET author=? WHERE id=?");
        $sql->execute( $params{ 'author' }, $id ) or
          die "Failed to update author " . $db->errstr();
        $sql->finish();
    }

    #
    #  Update the question if defined.
    #
    if ( defined( $params{ 'question' } ) )
    {
        my $sql =
          $db->prepare("UPDATE poll_submissions SET question=? WHERE id=?");
        $sql->execute( $params{ 'question' }, $id ) or
          die "Failed to update question " . $db->errstr();
        $sql->finish();
    }

    #
    #  Update our answers if defined.
    #
    if ( defined( $params{ 'answers' } ) )
    {

        #
        #  delete old answers
        #
        $db->do("DELETE FROM poll_submissions_answers WHERE poll_id=$id");

        #
        #  Get the new ones.
        #
        my $answers = $params{ 'answers' };
        my $count   = 1;

        foreach my $a (@$answers)
        {
            my $sql = $db->prepare(
                "INSERT INTO poll_submissions_answers (id,poll_id,answer) VALUES( ?,?,?)"
            );
            $sql->execute( $count, $id, $a );
            $sql->finish();
            $count += 1;
        }

    }

}



=head2 getPendingPoll

  Get the given pending poll details from the submission queue.

=cut

sub getPendingPoll
{
    my ( $class, $id ) = (@_);

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    #  Get the author + question.
    #
    my $sql =
      $db->prepare('SELECT author,question FROM poll_submissions WHERE id=?');
    $sql->execute($id) or die $db->errstr();

    my ( $author, $question ) = $sql->fetchrow_array();
    $sql->finish();


    #
    #  Fetch all the possible answers.
    #
    my $answers = $db->prepare(
        "SELECT id,answer FROM poll_submissions_answers WHERE poll_id=? ORDER BY id ASC"
    );
    $answers->execute($id);
    my $dataref = $answers->fetchall_arrayref();
    $answers->finish();

    my @data = @$dataref;

    my @answers;

    foreach my $item (@data)
    {

        #
        # Get the answers.
        #
        my @item   = @$item;
        my $id     = $item[0];
        my $choice = $item[1];

        push @answers, $choice;
    }

    return ( $author, $question, \@answers );
}



=head2 postPoll

  Post a poll from the pending queue onto the live site.

=cut

sub postPoll
{
    my ( $class, $id ) = (@_);

    #
    #  Get the poll data.
    #
    my ( $author, $question, $answers ) = $class->getPendingPoll($id);

    #
    #  Now post it.
    #
    my $polls = Yawns::Polls->new();
    $polls->add( question => $question,
                 author   => $author,
                 answers  => $answers
               );

    #
    #  Now that the poll has been posted delete it from the queue.
    # NOTE: This will flush the cache, so we don't need to do it here.
    #
    $class->rejectPoll($id);
}



=head2 invalidateCache

  Clean any cached content we might have.

=cut

sub invalidateCache
{
    my ( $class, $username ) = (@_);
}



1;


=head1 AUTHOR

Steve Kemp

http://www.steve.org.uk/



=head1 LICENSE

Copyright (c) 2005-2007 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut
