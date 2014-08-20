# -*- cperl -*- #

=head1 NAME

Yawns::Comment - A module for working with a single comment.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Comment;
    use strict;

    my $comments = Yawns::Comment->new( article => 40 );

    my $id = $comments->add( title => "test",
                              body => "bob" );


=for example end


=head1 DESCRIPTION

This module contains code for dealing with a single comment.

The comments might be upon a weblog entry, a poll, or an article.

=cut


package Yawns::Comment;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);


require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.50 $' =~ m/Revision:\s*(\S+)/;



#
#  Standard modules which we require.
#
use strict;
use warnings;
use HTML::Entities;


#
#  Yawns modules which we use.
#
use Singleton::DBI;
use Yawns::Article;
use Yawns::Date;
use Yawns::Poll;
use Yawns::Polls;
use Yawns::User;
use Yawns::Weblog;
use Yawns::Weblogs;


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



=head2 get

  Return a single comment from the database.  Used primarily for fetching
 the details of a comment when a user makes a new reply.

=cut

sub get
{
    my ($class) = (@_);

    my ( $type, $root ) = undef;

    if ( ( defined $class->{ 'article' } ) &&
         ( $class->{ 'article' } =~ /^([0-9]+)$/ ) )
    {
        $type = 'a';
        $root = $class->{ 'article' };
    }

    if ( ( defined $class->{ 'poll' } ) &&
         ( $class->{ 'poll' } =~ /^([0-9]+)$/ ) )
    {
        $type = 'p';
        $root = $class->{ 'poll' };
    }

    if ( ( defined $class->{ 'weblog' } ) &&
         ( $class->{ 'weblog' } =~ /^([0-9]+)$/ ) )
    {
        $type = 'w';
        $root = $class->{ 'weblog' };
    }


    #
    # Gain access to the database
    #
    my $db = Singleton::DBI->instance();

    my %results = ();

    #
    #  Get from the database
    #
    my $sql = $db->prepare(
        'SELECT title,author,ip,body,ondate FROM comments WHERE id=? and root=? and type=?'
    );
    $sql->execute( $class->{ 'id' }, $root, $type ) or
      die "Failed to get comment " . $db->errstr();


    my @commentData = $sql->fetchrow_array();
    $sql->finish();


    $results{ 'title' }  = $commentData[0];
    $results{ 'author' } = $commentData[1];
    $results{ 'ip' }     = $commentData[2];
    $results{ 'body' }   = $commentData[3];

    # Patch up the date + time
    my ( $date, $time ) = Yawns::Date::convert_date_to_site( $commentData[4] );
    $results{ 'date' } = $date;
    $results{ 'time' } = $time;

    # Patch up the IP address
    if ( defined( $results{ 'ip' } ) && length( $results{ 'ip' } ) )
    {
        if ( $results{ 'ip' } =~ /([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/ )
        {
            $results{ 'ip' } = $1 . "." . $2 . ".xx.xx";
        }
    }

    return ( \%results );
}



=head2 editComment

  Edit the contents of a comment

=cut

sub editComment
{
    my ( $class, %params ) = (@_);

    #
    #  Get the parameters we're to edit the comment with.
    #
    my $title = $params{ 'newtitle' } or die "No new title";
    my $body  = $params{ 'newbody' }  or die "No new body";


    #
    #  The type + root of the comment.
    #
    my ( $type, $root ) = undef;

    if ( ( defined $class->{ 'article' } ) &&
         ( $class->{ 'article' } =~ /^([0-9]+)$/ ) )
    {
        $type = 'a';
        $root = $class->{ 'article' };
    }

    if ( ( defined $class->{ 'poll' } ) &&
         ( $class->{ 'poll' } =~ /^([0-9]+)$/ ) )
    {
        $type = 'p';
        $root = $class->{ 'poll' };
    }

    if ( ( defined $class->{ 'weblog' } ) &&
         ( $class->{ 'weblog' } =~ /^([0-9]+)$/ ) )
    {
        $type = 'w';
        $root = $class->{ 'weblog' };
    }


    #
    #  Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    #  Update the comment
    #
    my $sql = $db->prepare(
        "UPDATE comments SET title=?, body=? WHERE root=? AND id=? AND type=?");
    $sql->execute( $title, $body, $root, $class->{ 'id' }, $type ) or
      die "Failed to edit comment: " . $db->errstr();
    $sql->finish();

}



=head2 getEmail

  Return the email address of the person who posted a given comment.

  This is only used for testing.

=cut

sub getEmail
{
    my ($class) = (@_);

    #
    # Gain access to the database
    #
    my $db = Singleton::DBI->instance();

    my ( $type, $root ) = undef;

    if ( ( defined $class->{ 'article' } ) &&
         ( $class->{ 'article' } =~ /^([0-9]+)$/ ) )
    {
        $type = 'a';
        $root = $class->{ 'article' };
    }

    if ( ( defined $class->{ 'poll' } ) &&
         ( $class->{ 'poll' } =~ /^([0-9]+)$/ ) )
    {
        $type = 'p';
        $root = $class->{ 'poll' };
    }

    if ( ( defined $class->{ 'weblog' } ) &&
         ( $class->{ 'weblog' } =~ /^([0-9]+)$/ ) )
    {
        $type = 'w';
        $root = $class->{ 'weblog' };
    }

    my $id = $class->{ 'id' };


    my $sql1 = $db->prepare(
        'SELECT a.realemail FROM users AS a INNER JOIN comments AS b ON a.username = b.author AND b.root=? AND b.id=? AND b.type=?'
    );
    $sql1->execute( $root, $id, $type );

    my @details = $sql1->fetchrow_array();
    $sql1->finish();

    return ( $details[0] );
}



=head2 add

  Add a comment to the given article, poll, or weblog:

     my $comment = Yawns::Comment->new();
     $comment->add( article => 40,
                    author  => "Steve",
                    title   => "Comment title",
                    body    => "Body text\nhere" );

=cut

sub add
{
    my ( $class, %parameters ) = (@_);

    #
    # Gain the details we should add
    #
    my $article   = $parameters{ 'article' };
    my $poll      = $parameters{ 'poll' };
    my $weblog    = $parameters{ 'weblog' };
    my $body      = $parameters{ 'body' };
    my $title     = $parameters{ 'title' };
    my $username  = $parameters{ 'username' };
    my $oncomment = $parameters{ 'oncomment' };
    my $ip        = $ENV{ "REMOTE_ADDR" } || "";
    my $force     = $parameters{ 'force' } || 0;

    #
    #  Get the singletons we require
    #
    my $db = Singleton::DBI->instance();

    #
    # The root and type of comment we will use to add to the database.
    #
    my ( $root, $type ) = undef;
    if ( defined($article) && ( $article =~ /([0-9]+)/ ) )
    {
        $type = 'a';
        $root = $article;
    }
    if ( defined($poll) && ( $poll =~ /([0-9]+)/ ) )
    {
        $type = 'p';
        $root = $poll;
    }
    if ( defined($weblog) && ( $weblog =~ /([0-9]+)/ ) )
    {
        $type = 'w';
        $root = $weblog;
    }


    #
    #  Insert the new comment into the database.
    #
    my $query =
      'INSERT INTO comments (root,parent,title,author,ondate,body,ip,type ) VALUES( ?,?,?,?,NOW(),?,?,? )';
    my $sql = $db->prepare($query);
    $sql->execute( $root, $oncomment, $title, $username, $body, $ip, $type ) or
      die "Error " . $db->errstr();
    $sql->finish();

    #
    #  Find the ID of the comment we just added.
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

    #
    # Update the comment count when we're adding to an article.
    #
    if ( $type eq 'a' )
    {

        #
        #  Increase comment count
        #
        my $query_str2 = 'UPDATE articles SET comments=comments+1 WHERE id=?';
        my $sql2       = $db->prepare($query_str2);
        $sql2->execute($article);
        $sql2->finish();

        #
        # Invalidate cache
        #
        my $article = Yawns::Article->new( id => $root );
        $article->invalidateCache();
    }



    #
    # Update the comment count when we're adding to a weblog.
    #
    if ( $type eq 'w' )
    {

        #
        #  Increase comment count.
        #
        my $query_str2 = 'UPDATE weblogs SET comments=comments+1 WHERE gid=?';
        my $sql2       = $db->prepare($query_str2);
        $sql2->execute($weblog);
        $sql2->finish();

        #
        # Invalidate cache
        #
        my $weblog = Yawns::Weblog->new( gid => $root );
        my $user = $weblog->getOwner();
        $weblog->invalidateCache( username => $user );

        #
        # Recent weblogs is now wrong too.
        #
        my $weblogs = Yawns::Weblogs->new();
        $weblogs->invalidateCache();
    }


    #
    #  Invalide the current poll, if that is what was commented upon.
    #
    if ( $type eq 'p' )
    {
        my $polls        = Yawns::Polls->new();
        my $current_poll = $polls->getCurrentPoll();

        my $p = Yawns::Poll->new( id => $poll );
        $p->invalidateCache();
    }


    #
    #  Invalidate comment cache(s).
    #
    $class->invalidateCache();
    my $comments = Yawns::Comments->new( weblog   => $weblog,
                                         article  => $article,
                                         poll     => $poll,
                                         username => $username
                                       );
    $comments->invalidateCache();

    #
    # Flush Hall of Fame cache, since this keeps track of total number
    # of comments posted to the site.
    #
    my $hof = Yawns::Stats->new();
    $hof->invalidateCache();

    #
    #  And the comments the user has posted.
    #
    my $user = Yawns::User->new( username => $username );
    $user->invalidateCache();

    return ($num);
}



=head2 delete

  Delete the given comment.

=cut

sub delete
{
    my ( $class, %parameters ) = (@_);

    #
    # Gain the details we should delete.
    #
    my $article = $parameters{ 'article' };
    my $poll    = $parameters{ 'poll' };
    my $weblog  = $parameters{ 'weblog' };
    my $id      = $parameters{ 'id' };

    #
    # We wish to invalidate the user after deleting the commetn.
    #
    my $username = undef;
    my $root;
    my $type;

    if ( defined($article) && ( $article =~ /([0-9]+)/ ) )
    {
        $username = _getCommentPoster( $article, $id, 'a' );
        $root     = $article;
        $type     = 'a';
    }
    if ( defined($poll) && ( $poll =~ /([0-9]+)/ ) )
    {
        $username = _getCommentPoster( $poll, $id, 'p' );
        $root     = $poll;
        $type     = 'p';
    }
    if ( defined($weblog) && ( $weblog =~ /([0-9]+)/ ) )
    {
        $username = _getCommentPoster( $weblog, $id, 'w' );
        $root     = $weblog;
        $type     = 'w';
    }

    #
    #  Delete the comment
    #
    my $db = Singleton::DBI->instance();
    my $sql =
      $db->prepare('DELETE FROM comments WHERE root=? AND id=? AND type=?');
    $sql->execute( $root, $id, $type ) or die "Failed: " . $db->errstr();
    $sql->finish();

    #
    #  Now decrease the counts.
    #
    if ( $type =~ /w/ )
    {
        _decrease_weblog_comment_count($root);
    }
    if ( $type =~ /p/ )
    {
        _decrease_poll_comment_count($root);
    }
    if ( $type =~ /a/ )
    {
        _decrease_article_comment_count($root);
    }

    #
    #  Invalidate the users comment count.
    #
    my $user = Yawns::User->new( username => $username );
    $user->invalidateCache();

    #
    # Flush Hall of Fame cache
    #
    my $hof = Yawns::Stats->new();
    $hof->invalidateCache();
}



=head2 report

  Report the given comment.

  This doesn't delete the comment, instead it merely flags the
 comment as being poor.

=cut

sub report
{
    my ( $class, %parameters ) = (@_);

    #
    # Gain the details we should delete.
    #
    my $article = $parameters{ 'article' };
    my $poll    = $parameters{ 'poll' };
    my $weblog  = $parameters{ 'weblog' };
    my $id      = $parameters{ 'id' };
    my $user    = $parameters{ 'reporter' };

    #
    # We wish to invalidate the user after deleting the comment.
    #
    my $username = undef;

    #
    #  The root and type.
    #
    my $root;
    my $type;

    if ( defined($article) && ( $article =~ /([0-9]+)/ ) )
    {
        $username = _getCommentPoster( $article, $id, 'a' );
        $root     = $article;
        $type     = 'a';
    }
    if ( defined($poll) && ( $poll =~ /([0-9]+)/ ) )
    {
        $username = _getCommentPoster( $poll, $id, 'p' );
        $root     = $poll;
        $type     = 'p';
    }
    if ( defined($weblog) && ( $weblog =~ /([0-9]+)/ ) )
    {
        $username = _getCommentPoster( $weblog, $id, 'w' );
        $root     = $weblog;
        $type     = 'w';
    }

    #
    #  Default to decreasing score by one for a registered user.
    #  Site users with the "edit_comments" privilege can nuke a comment
    # to zero instantly.
    #
    my $decrease = 1;

    #
    #  You can't report your own comment
    #
    return if ( lc($user) eq lc($username) );

    #
    #  test for comment editing privileges - this is insta-nuke
    #
    my $perms = Yawns::Permissions->new( username => $user );
    if ( $perms->check( priv => "edit_comments" ) )
    {
        $decrease = $class->getScore( $root, $id, $type );

        # Avoid modifying the score if it has gone negative.
        if ( $decrease < 0 ) {$decrease = 1;}
    }
    else
    {

        #
        #  If we're reporting a comment on a weblog then
        # the poster of the weblog can also nuke it to zero.
        #
        if ( defined($weblog) && ( $weblog =~ /([0-9]+)/ ) )
        {
            my $w = Yawns::Weblog->new( gid => $weblog );
            my $weblog_owner = $w->getOwner();

            if ( lc($weblog_owner) eq lc($user) )
            {
                $decrease = $class->getScore( $root, $id, $type );

                # Avoid increasing the score if it has gone negative.
                if ( $decrease < 0 ) {$decrease = 1;}
            }
        }

        #
        #  if we're the author of an article then we get to report
        # that too.
        #
        if ( defined($article) && ( $article =~ /([0-9]+)/ ) )
        {
            my $accessor = Yawns::Article->new( id => $article );

            #
            #  Find the article author.
            #
            my $a      = $accessor->get();
            my $author = $a->{ 'article_byuser' };

            if ( lc($author) eq lc($user) )
            {
                $decrease = $class->getScore( $root, $id, $type );

                # Avoid increasing the score if it has gone negative.
                if ( $decrease < 0 ) {$decrease = 1;}
            }
        }
    }

    #
    #
    #  Actually decrease the score.
    #
    my $db = Singleton::DBI->instance();
    my $sql = $db->prepare(
          'UPDATE comments SET score=score-? WHERE root=? AND id=? AND type=?');
    $sql->execute( $decrease, $root, $id, $type ) or
      die "Failed: " . $db->errstr();
    $sql->finish();

    #
    #  If the score is == 0 then we have to invalidate things more
    # fully.
    #
    #  We only test for equal to zero, because if it is below then
    # the comment count might be decreased too much.
    #
    #  This could happen with reloads, etc.
    #
    if ( $class->getScore( $root, $id, $type ) == 0 )
    {
        if ( $type =~ /w/ )
        {
            _decrease_weblog_comment_count($root);
        }
        if ( $type =~ /p/ )
        {
            _decrease_poll_comment_count($root);
        }
        if ( $type =~ /a/ )
        {
            _decrease_article_comment_count($root);
        }
    }

    #
    #
    #  Invalidate the user.
    #
    my $u = Yawns::User->new( username => $username );
    $u->invalidateCache();

    #
    # Flush Hall of Fame cache
    #
    my $hof = Yawns::Stats->new();
    $hof->invalidateCache();
}



=head2 getScore

   Get the score of a comment.

=cut

sub getScore
{
    my ( $self, $root, $id, $type ) = (@_);

    my $db = Singleton::DBI->instance();

    my $sql = $db->prepare(
                 'SELECT score FROM comments WHERE id=? and root=? and type=?');
    $sql->execute( $id, $root, $type );

    my @commentData = $sql->fetchrow_array();
    $sql->finish();

    return ( $commentData[0] );
}



=head2 _getCommentPoster

   Get the username who posted the given comment.

=cut

sub _getCommentPoster
{
    my ( $root, $id, $type ) = (@_);

    my $db = Singleton::DBI->instance();

    my $sql = $db->prepare(
                'SELECT author FROM comments WHERE id=? and root=? and type=?');
    $sql->execute( $id, $root, $type );


    my @commentData = $sql->fetchrow_array();
    $sql->finish();


    return ( $commentData[0] );
}



=head2 _decrease_article_comment_count

   Decrease the count of comments on the given article.

=cut

sub _decrease_article_comment_count
{

    # delete a comment from the database
    my ($article) = (@_);

    #
    # Get the database handle
    #
    my $db = Singleton::DBI->instance();

    my $query_str2 = 'UPDATE articles SET comments=comments-1 WHERE id=?';
    my $sql2       = $db->prepare($query_str2);
    $sql2->execute($article) or die "Failed: " . $db->errstr();
    $sql2->finish();

    #
    # Invalidate comments cache
    #
    my $comments = Yawns::Comments->new( article => $article );
    $comments->invalidateCache();

    #
    # Invalidate article
    #
    my $art = Yawns::Article->new( id => $article );
    $art->invalidateCache();
}



=head2 _decrease_poll_comment_count

   Decrease the number of comments on a given poll.

=cut

sub _decrease_poll_comment_count
{
    my ($poll) = (@_);

    #
    # Invalidate comments cache
    #
    my $comments = Yawns::Comments->new( poll => $poll );
    $comments->invalidateCache();

    #
    # Invalidate the poll comment count too.
    #
    my $poll_data = Yawns::Poll->new( id => $poll );
    $poll_data->invalidateCache();
}



=head2 _decrease_weblog_comment_count

   Decrease the count of comments on a given weblog.

=cut

sub _decrease_weblog_comment_count
{
    my ($gid) = (@_);

    my $query_str2 = 'UPDATE weblogs SET comments=comments-1 WHERE gid=?';
    my $db         = Singleton::DBI->instance();
    my $sql2       = $db->prepare($query_str2);
    $sql2->execute($gid);
    $sql2->finish();

    #
    # Invalidate comments cache
    #
    my $comments = Yawns::Comments->new( weblog => $gid );
    $comments->invalidateCache();

    #
    #  Invalidate recent weblogs
    #
    my $weblogs = Yawns::Weblogs->new();
    $weblogs->invalidateCache();

    #
    #  Invalidate this weblog
    #
    my $weblog = Yawns::Weblog->new( gid => $gid );
    my $owner = $weblog->getOwner();
    $weblog->invalidateCache( username => $owner );

}



=head2 invalidateCache

  Invalidate any cached comments in memory.

  TODO:  Use caching here.

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
