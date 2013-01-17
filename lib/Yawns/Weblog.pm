
=head1 NAME

Yawns::Weblog - A module for interfacing with a single weblog.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Weblog;
    use strict;

    #
    #  Add a weblog entry.
    #
    my $blog = Yawns::Weblog->new();

    $blog->add( username => "username",
                title    => "Title",
                text     => "Text" );


    #
    # Find the email address of a weblog owner.
    #
    my $lookup = Yawns::Weblog->new( gid => 22 );

=for example end


=head1 DESCRIPTION

This module will allow a user to work with their weblogs:

   * Adding an entry.
   * Editing an entry.
   * Deleting an entry.

=cut


package Yawns::Weblog;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.70 $' =~ m/Revision:\s*(\S+)/;


#
#  Standard modules which we require.
#
use strict;
use warnings;
use HTML::Entities;

#
#  Yawns modules which we use.
#
use HTML::Balance;
use Singleton::DBI;
use Yawns::Stats;
use Yawns::Tags;
use Yawns::User;
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



=head2 count

  Count the number of weblog entries the given user has made.

=cut

sub count
{
    my ($class) = (@_);

    my $username = $class->{ 'username' };
    my $user = Yawns::User->new( username => $username );
    return ( $user->getWeblogCount() );
}



=head2 add

  Add a new weblog entry.

=for example begin

     $weblog->add(  subject          => "Test subject",
                    body             => "Body goes here",
                    comments_allowed => 1,
                 );

=for example end

  This function returns the ID of the entry inserted.

=cut

sub add
{
    my ( $class, %parameters ) = (@_);

    my $username = $class->{ 'username' };
    my $subject  = $parameters{ 'subject' };
    my $body     = $parameters{ 'body' };
    my $comments = $parameters{ 'comments_allowed' };


    #
    #
    #  Comments may optionally be allowed in weblog entries.
    # if they are allowed then the comments field is '0' for
    # zero comments, otherwise the number of comments on that
    # entry.
    #
    #  To mark an entry as 'comments are prohibitted' then the
    # comments field is set to '-1'.
    #
    if ($comments)
    {
        $comments = 0;
    }
    else
    {
        $comments = -1;
    }

    #
    # Find the number of weblog entries.
    #
    my $count = $class->count();
    $count++;


    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    my $query_string =
      'INSERT INTO weblogs (username,ondate,title,bodytext,id,comments) VALUES ( ?, NOW(), ?, ?, ?, ? )';
    my $sql = $db->prepare($query_string);
    $sql->execute( $username, $subject, $body, $count, $comments );
    $sql->finish();

    #
    # User's weblog count is now wrong.
    #
    my $user = Yawns::User->new( username => $username );
    $user->invalidateCache();

    #
    # Hall of fame weblog count is now wrong.
    #
    my $hof = Yawns::Stats->new();
    $hof->invalidateCache();

    #
    # recent weblogs is now wrong
    #
    my $weblogs = Yawns::Weblogs->new( username => $username );
    $weblogs->invalidateCache();

    return ($count);
}



=head2 edit

  Edit an existing weblog entry.

=cut

sub edit
{
    my ( $class, %parameters ) = (@_);

    my $username = $parameters{ 'username' } || $class->{ 'username' };
    my $id       = $parameters{ 'id' }       || $class->{ 'id' };
    my $gid      = $parameters{ 'gid' }      || $class->{ 'gid' };

    die "No username" unless defined($username);
    die "No id"       unless defined($id);

    if ( !defined($gid) )
    {
        $gid = $class->getGID( username => $username,
                               id       => $id );
    }


    #
    # Get the updated text + GID.
    #
    my $title = $parameters{ 'title' };
    my $body  = $parameters{ 'body' };

    #
    # First update the entry text + title.
    #
    my $db = Singleton::DBI->instance();
    my $sql = $db->prepare(
            "UPDATE weblogs SET title=?, bodytext=? WHERE username=? AND id=?");
    $sql->execute( $title, $body, $username, $id );
    $sql->finish();


    #
    # Now disable comments if necessary.
    #
    if ( $parameters{ 'comments_enabled' } )
    {

        #
        #  Allow comments
        #
        my $comment_count = $class->getCommentCount( gid => $gid );

        my $sql2 = $db->prepare(
                     "UPDATE weblogs SET comments=? WHERE username=? AND id=?");
        $sql2->execute( $comment_count, $username, $id );
        $sql2->finish();
    }
    else
    {

        #
        # Disable comments.
        #
        my $sql2 = $db->prepare(
                    "UPDATE weblogs SET comments=-1 WHERE username=? AND id=?");
        $sql2->execute( $username, $id );
        $sql2->finish();
    }

    #
    # Save the GID so we can invalidate the entry.
    #
    $class->{ 'gid' } = $gid;

}



=head2 remove

  Remove a given weblog entry.

  NOTE: This doesn't remove any comments associated with the entry.

=cut

sub remove
{
    my ( $class, %params ) = (@_);

    my $gid      = $params{ 'gid' };
    my $username = $params{ 'username' };

    die "No GID"      unless defined($gid);
    die "No Username" unless defined($username);

    my $db  = Singleton::DBI->instance();
    my $sql = $db->prepare("DELETE FROM weblogs WHERE gid=?");
    $sql->execute($gid);
    $sql->finish();

    #
    #  Delete any tags.
    #
    my $holder = Yawns::Tags->new();
    $holder->deleteTags( weblog => $gid );

    #
    # recent weblogs is now wrong
    #
    my $weblogs = Yawns::Weblogs->new();
    $weblogs->invalidateCache();

    #
    #  Weblog count of the user is incorrect.
    #
    my $user = Yawns::User->new( username => $username );
    $user->invalidateCache();

}



=head2 getTitle

  Return the title of the given weblog entry.

=cut

sub getTitle
{
    my ( $self, %parameters ) = (@_);

    #
    # The gid of the weblog entry we care about.
    #
    my $gid = $parameters{ 'gid' } || $self->{ 'gid' };

    die "No gid specified" if ( !defined($gid) );

    #
    #  Attempt to fetch from the cache
    #
    my $title = "";


    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    # Get the title.
    #
    my $query = $db->prepare('SELECT title FROM weblogs WHERE gid=?');
    $query->execute($gid) or die "Failed to get weblog title " . $db->errstr();

    $title = $query->fetchrow_array();

    return ($title);
}



=head2 report

  Flag an entry as abusive.

=cut

sub report
{
    my ( $self, %parameters ) = (@_);


    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    # The gid of the weblog entry we care about.
    #
    my $gid = $parameters{ 'gid' } || $self->{ 'gid' };
    die "No gid specified" if ( !defined($gid) );

    $self->{ 'username' } = $self->getOwner( gid => $gid );


    # Decrese the score.  Make it non-negative.
    my $query = $db->prepare(
                  'UPDATE weblogs SET score=score-1 WHERE gid=? AND score > 0');
    $query->execute($gid) or die "Failed to change score " . $db->errstr();
    $query->finish();

    # Invalidate our cache.
    $self->invalidateCache( gid => $gid );

    # And the recent feed, etc.
    my $weblogs = Yawns::Weblogs->new();
    $weblogs->invalidateCache();
}



=head2 getScore

  Return the current score of a weblog

=cut

sub getScore
{
    my ( $self, %parameters ) = (@_);

    #
    # The gid of the weblog entry we care about.
    #
    my $gid = $parameters{ 'gid' } || $self->{ 'gid' };

    die "No gid specified" if ( !defined($gid) );

    my $score = undef;

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    # get the score from the database.
    #
    my $query = $db->prepare('SELECT score FROM weblogs WHERE gid=?');
    $query->execute($gid) or die "Failed to get weblog score " . $db->errstr();

    $score = $query->fetchrow_array();
    return ($score);

}



=head2 getCommentCount

  Return the count of comments upon this weblog.

=cut

sub getCommentCount
{
    my ( $self, %parameters ) = (@_);

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    # The gid of the weblog entry we care about.
    #
    my $gid = $parameters{ 'gid' } || $self->{ 'gid' };

    die "No gid specified" if ( !defined($gid) );

    #
    #  Attempt to fetch from the cache
    #
    my $count = "";


    #
    # get the count of comments on this entry.
    #
    my $query = $db->prepare(
           'SELECT COUNT(*) FROM comments WHERE score>0 AND root=? AND type=?');
    $query->execute( $gid, 'w' ) or
      die "Failed to get weblog comment count " . $db->errstr();

    $count = $query->fetchrow_array();
    $query->finish();

    return ($count);
}



=head2 getOwner

  Return the owner of the given weblog entry.

=cut

sub getOwner
{
    my ( $self, %parameters ) = (@_);

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    # The gid of the weblog entry we care about.
    #
    my $gid = $parameters{ 'gid' } || $self->{ 'gid' };

    die "No gid specified" if ( !defined($gid) );

    #
    #  Attempt to fetch from the cache
    #
    my $name  = "";

    #
    # Find the user who posted this entry.
    #
    my $query = $db->prepare('SELECT username FROM weblogs WHERE gid=?');
    $query->execute( $gid, );

    $name = $query->fetchrow_array();
    return ($name);
}



=head2 getLink

  Return the link to the weblog entry with the given GID.

=cut

sub getLink
{
    my ( $self, %parameters ) = (@_);

    #
    # The gid of the weblog entry we care about.
    #
    my $gid = $parameters{ 'gid' } || $self->{ 'gid' };
    die "No gid specified" if ( !defined($gid) );

    my $link  = '';

    #
    #  Get the owner + ID.
    #
    my $owner = $self->getOwner( gid => $gid );
    my $id = $self->getID( gid => $gid );

    #
    #  Build up the link.
    #
    $link = "/users/$owner/weblog/$id";

    return ($link);
}



=head2 getID

  Return the ID of the given weblog entry.

=cut

sub getID
{
    my ( $self, %parameters ) = (@_);

    #
    # The gid of the weblog entry we care about.
    #
    my $gid = $parameters{ 'gid' } || $self->{ 'gid' };
    die "No gid specified" if ( !defined($gid) );

    #
    #  Attempt to fetch from the cache
    #
    my $id    = "";

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    # Get the id.
    my $query = $db->prepare('SELECT id FROM weblogs WHERE gid=?');
    $query->execute( $gid, );

    $id = $query->fetchrow_array();

    return ($id);
}


=head2 getGID

  Return the GID of the given user's weblog entry.

  NOTE: Not cached - because this causes problems if the username + id
 isn't stored...

=cut

sub getGID
{
    my ( $self, %parameters ) = (@_);

    #
    # The gid of the weblog entry we care about.
    #
    my $id       = $parameters{ 'id' }       || $self->{ 'id' };
    my $username = $parameters{ 'username' } || $self->{ 'username' };

    die "No ID specified:"      if ( !defined($id) );
    die "No username specified" if ( !defined($username) );

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    # Get the id.
    my $query =
      $db->prepare('SELECT gid FROM weblogs WHERE id=? AND username=?');
    $query->execute( $id, $username ) or
      die "Failed to run query " . $db->errstr();

    my $gid = $query->fetchrow_array();
    $query->finish();

    return ($gid);
}



=head2 getSingleWeblogEntry

  Return a single weblog entry.

=cut

sub getSingleWeblogEntry
{
    my ( $class, %params ) = (@_);

    #
    #  Make sure we have either a GID, or we can find one.
    my $gid      = $params{ 'gid' };
    my $editable = $params{ 'editable' };
    if ( !defined($gid) )
    {
        die "No GID";
    }

    my $entry;


    #
    #  Count of entries.
    #
    my $max = $class->count();


    #
    #  Entry is not in the cache.  Find it from the database
    #
    my $db = Singleton::DBI->instance();
    my $sql = $db->prepare(
        "SELECT username,ondate,title,bodytext,id,gid,comments FROM weblogs WHERE gid=?"
    );
    $sql->execute($gid) or die "SQL error " . $db->errstr();

    #
    #  Bind the columns
    #
    my ( $username, $ondate, $title, $body, $id, $g_id, $comments );
    $sql->bind_columns( undef, \$username, \$ondate, \$title, \$body, \$id,
                        \$g_id, \$comments );


    #
    #  Fetch the results.
    #
    $entry = [];
    while ( $sql->fetch() )
    {

        # convert date and time to more readable format
        my @posted = Yawns::Date::convert_date_to_site($ondate);

        # Make sure body is well-formed.
        $body = HTML::Balance::balance($body);

        #
        # Should we show the next and previous entries?
        #
        my $next = $id + 1;
        my $prev = $id - 1;
        if ( $prev <= 0 )
        {
            $prev = undef;
        }

        if ( $id >= $max )
        {
            $next = undef;
        }


        #
        #  If the comment count is -1 then they are disabled.
        #
        my $enabled = 0;
        $enabled = 1 if ( $comments != -1 );
        $comments = $class->getCommentCount( gid => $gid );


        my $plural = 0;
        if ( ( $comments == 0 ) || ( $comments > 1 ) )
        {
            $plural = 1;
        }

        #
        #  Get any tags on this weblog entry.
        #
        my $tagHolder = Yawns::Tags->new();
        my $tags = $tagHolder->getTags( weblog => $gid );

        if ($tags)
        {
            push( @$entry,
                  {  user             => $username,
                     ondate           => $posted[0],
                     attime           => $posted[1],
                     title            => $title,
                     bodytext         => $body,
                     item_id          => $id,
                     gid              => $g_id,
                     edit             => $editable,
                     comment_count    => $comments,
                     plural           => $plural,
                     comments_enabled => $enabled,
                     next             => $next,
                     prev             => $prev,
                     tags             => $tags,
                  } );
        }
        else
        {
            push( @$entry,
                  {  user             => $username,
                     ondate           => $posted[0],
                     attime           => $posted[1],
                     title            => $title,
                     bodytext         => $body,
                     item_id          => $id,
                     gid              => $g_id,
                     edit             => $editable,
                     comment_count    => $comments,
                     plural           => $plural,
                     comments_enabled => $enabled,
                     next             => $next,
                     prev             => $prev,
                  } );
        }
    }
    $sql->finish();

    return ($entry);
}



=head2 getEntries

  Get the specified users weblog data from the database

=cut

sub getEntries
{
    my ( $self, %params ) = (@_);

    #
    #  First of all get the username and the starting entry.
    #
    my $username = $self->{ 'username' };
    my $start    = $params{ 'start' };

    #
    #  We need a username.
    #
    die "No username" if ( !defined($username) );


    #
    # No starting point defined.  Use the most recent entries.
    #
    $start = $self->count() if ( !defined($start) );

    #
    #  See if these are in the cache.
    #
    my $entries;



    #
    #  Failed to find them in the cache, so load from the database.
    #
    my $db = Singleton::DBI->instance();


    #
    #  Prepare, and execute the cache.
    #
    my $sql = $db->prepare(
        "SELECT username,ondate,title,bodytext,id,gid,comments FROM weblogs WHERE username=? AND id <=? ORDER BY id DESC limit 10"
    );
    $sql->execute( $username, $start );

    #
    #  Accessor for tags.
    #
    my $tagHolder = Yawns::Tags->new();

    #
    #  Bind the columns for the result.
    #
    #  e_foo == "Entry_foo"
    #
    my ( $e_username, $e_ondate, $e_title, $e_body, $e_id, $e_gid,
         $e_comments );
    $sql->bind_columns( undef, \$e_username, \$e_ondate, \$e_title, \$e_body,
                        \$e_id, \$e_gid, \$e_comments );


    #
    #  Fetch the results.
    #
    while ( $sql->fetch() )
    {

        # convert date and time to more readable format
        my @posted = Yawns::Date::convert_date_to_site($e_ondate);

        #
        #  Handle the cut ..
        #
        my $cut      = 0;
        my $cut_text = "";
        if ( ( $e_body =~ /(.*)<cut([^>]*)>(.*)/gis ) ||
             ( $e_body =~ /(.*)&lt;cut([a-zA-Z0-9 \t'"]*)&gt;(.*)/gis ) )
        {
            $e_body = $1;
            $cut    = 1;

            #
            #  See if they supplied text="xxxxx"
            #
            my $text = $2;
            if ( defined($text) && ( $text =~ /text=['"]([^'"]+)['"]/i ) )
            {
                $cut_text = $1;
            }
        }


        if ($cut)
        {

            #
            #  Are we using SSL?
            #
            my $protocol = "http://";
            if ( defined( $ENV{ 'HTTPS' } ) && ( $ENV{ 'HTTPS' } =~ /on/i ) )
            {
                $protocol = "https://";
            }

            my $host = $protocol;
            $host .= $ENV{ "SERVER_NAME" } || "";

            #
            #  User-specified cut text.
            #
            if ( length($cut_text) )
            {
                $e_body .=
                  "<p><b>(</b><a href=\"$host/users/$e_username/weblog/$e_id\" title=\"This entry has been truncated; click to read more.\">$cut_text</a><b>)</b></p>";
            }
            else
            {
                $e_body .=
                  "<p>This entry has been truncated <a href=\"$host/users/$e_username/weblog/$e_id\">read the full entry</a>.</p>";
            }
        }

        #
        # Make sure body is well-formed.
        #
        # NOTE: Do this after the cut-tag addition...
        #
        $e_body = HTML::Balance::balance($e_body);



        #
        #  If the comments are -1 then comments are disabled.
        #
        my $enabled = 0;
        $enabled = 1 if ( $e_comments != -1 );
        $e_comments = $self->getCommentCount( gid => $e_gid );


        #
        #  Plurals on the comments?
        #
        my $plural = 0;
        if ( ( $e_comments == 0 ) || ( $e_comments > 1 ) )
        {
            $plural = 1;
        }


        #
        #  Get any tags on this weblog entry.
        #
        my $tags = $tagHolder->getTags( weblog => $e_gid );

        if ($tags)
        {
            push( @$entries,
                  {  user             => $e_username,
                     ondate           => $posted[0],
                     attime           => $posted[1],
                     title            => $e_title,
                     bodytext         => $e_body,
                     item_id          => $e_id,
                     gid              => $e_gid,
                     comment_count    => $e_comments,
                     plural           => $plural,
                     comments_enabled => $enabled,
                     tags             => $tags,
                  } );
        }
        else
        {
            push( @$entries,
                  {  user             => $e_username,
                     ondate           => $posted[0],
                     attime           => $posted[1],
                     title            => $e_title,
                     bodytext         => $e_body,
                     item_id          => $e_id,
                     gid              => $e_gid,
                     comment_count    => $e_comments,
                     plural           => $plural,
                     comments_enabled => $enabled,
                  } );
        }
    }

    # Cleanup
    $sql->finish();

    return ($entries);
}



=head2 getWeblogFeed

  Get the weblog feed for the given user.

=cut

sub getWeblogFeed
{
    my ($class) = (@_);

    my $username = $class->{ 'username' };
    die "No username" unless defined($username);

    #
    # Fetch from the cache first.
    #
    my $feed;

    #
    #  Find the entries.
    #
    my $entries = $class->getEntries();

    #
    #  Are we using SSL?
    #
    my $protocol = "http://";
    if ( defined( $ENV{ 'HTTPS' } ) && ( $ENV{ 'HTTPS' } =~ /on/i ) )
    {
        $protocol = "https://";
    }
    my $host = $protocol;
    $host .= $ENV{ "SERVER_NAME" } || "";


    #
    #  Get the entries, sorted by ID.
    #
    my @items;
    @items = @$entries if ($entries);

    #
    #  Sort the items, if there are any.
    #
    if ( scalar(@items) )
    {
        @items = sort {$b->{ 'gid' } <=> $a->{ 'gid' }} @items;
    }

    #
    #  Update each one to be XML encoded.
    #
    foreach my $e (@items)
    {
        my %hash = %$e;

        my $t = $hash{ 'title' }    || "";
        my $b = $hash{ 'bodytext' } || "";

        $hash{ 'title' }    = encode_entities($t);
        $hash{ 'bodytext' } = encode_entities($b);


        #
        #  Find the real name.
        #
        if ( $hash{ 'user' } )
        {
            my $u        = Yawns::User->new( username => $hash{ 'user' } );
            my $userdata = $u->get();
            my $realname = $userdata->{ 'realname' };
            $hash{ 'realname' } = $realname;
        }

        #
        #  Add in tags, if present.
        #
        my $tags = "<p><b>Tags</b>: ";

        if ( defined( $hash{ 'tags' } ) )
        {
            my $a = $hash{ 'tags' };
            foreach my $t (@$a)
            {
                my $name = $t->{ 'tag' };

                $tags .= "<a href=\"$host/tag/$name\">$name</a>, ";
            }

            $tags =~ s/\, $//g;
            $tags .= "</p>";

            $hash{ 'bodytext' } .= encode_entities($tags);

        }


        #
        #  Add a comma after the month name.
        #
        if ( $hash{ 'ondate' } =~ /^([a-zA-Z]+)([ ]+)(.*)/ )
        {
            $hash{ 'ondate' } = $1 . ", " . $3;
        }
        push( @$feed, \%hash );

    }

    return ($feed);
}



=head2 invalidateCache

  Clean any cached content we might have.

=cut

sub invalidateCache
{
    my ( $class, %params ) = (@_);
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
