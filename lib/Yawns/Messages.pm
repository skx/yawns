# -*- cperl -*- #

=head1 NAME

Yawns::Messages - A module for dealing with user-messaging.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Messages;
    use strict;

    my $msg   = Yawns::Messages->new( username => $username );

    my ( $new, $total) = $msg->messageCounts();

    my $i = 0;
    while( $i < $total )
    {
      my ( $to, $from, $text ) = $msg->getMessage( $i );
      $i += 1;
    }


=for example end


=head1 DESCRIPTION

This module deals with the static "about" pages we contain.

=cut


package Yawns::Messages;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.18 $' =~ m/Revision:\s*(\S+)/;


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
use Singleton::Session;



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


=head2 send

  Send a new message to a user.

=cut

sub send
{
    my ( $self, %params ) = (@_);

    #
    # Get the data.
    #
    my $to   = $params{ 'to' };
    my $body = $params{ 'body' };
    my $from = $self->{ 'username' };

    #
    #  Insert the message.
    #
    my $db = Singleton::DBI->instance();
    my $sql = $db->prepare(
        "INSERT INTO messages (sender,recipient,bodytext,sent) VALUES( ?,?,?,NOW()) "
    );
    $sql->execute( $from, $to, $body ) or die "Failed to send" . $db->errstr();
    $sql->finish();

    #
    #  Find the ID of the message we just inserted.
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
    #  Invalidate the cache of the recipient so that they see
    # the new message.
    #
    my $msg = Yawns::Messages->new( username => $to );
    $msg->invalidateCache();

    return ($num);
}



=head2 messageCounts

  Get the total of the messages.

=cut

sub messageCounts
{
    my ($self) = (@_);

    my $username = $self->{ 'username' };

    #
    #  Fetch from the cache first.
    #
    my $cache  = Singleton::Memcache->instance();
    my $total  = $cache->get("total_messages_for_$username");
    my $unread = $cache->get("unread_messages_for_$username");

    if ( defined($total) && defined($unread) )
    {
        return ( $unread, $total );
    }

    #
    # Get from the database.
    #
    my $db = Singleton::DBI->instance();

    #
    #  Total messages
    #
    my $totalQ =
      $db->prepare('SELECT COUNT(*) FROM messages WHERE recipient=?');
    $totalQ->execute($username);
    $total = $totalQ->fetchrow_array();
    $totalQ->finish();

    #
    #  Unread messages
    #
    my $unreadQ = $db->prepare(
                'SELECT COUNT(*) FROM messages WHERE recipient=? AND status=?');
    $unreadQ->execute( $username, "new" );
    $unread = $unreadQ->fetchrow_array();
    $unreadQ->finish();

    #
    #  Store in the cache
    #
    $cache->set( "total_messages_for_$username",  $total );
    $cache->set( "unread_messages_for_$username", $unread );

    return ( $unread, $total );
}



=head2 getMessage

  Return an individual message.

  TODO: Caching.

=cut

sub getMessage
{
    my ( $self, $id ) = (@_);

    #
    #  Get our username and make sure it exists.
    #
    my $username = $self->{ 'username' };
    die "No username" unless defined($username);

    #
    #  Get the individual message.
    #
    my $msgs;

    my $db = Singleton::DBI->instance();

    my $sql = $db->prepare(
        "SELECT sender,recipient,bodytext,sent,id FROM messages WHERE recipient=? AND id=?"
    );
    $sql->execute( $username, $id ) or die "SQL error " . $db->errstr();

    my ( $from, $to, $text, $sent, $mid );
    $sql->bind_columns( undef, \$from, \$to, \$text, \$sent, \$mid );

    #
    #  Fetch the results.
    #
    $msgs = [];
    while ( $sql->fetch() )
    {

        # can we reply to this message?
        my $replyable = 1;
        $replyable = 0 if ( $from =~ /^messages$/i );

        push( @$msgs,
              {  from      => $from,
                 to        => $to,
                 text      => $text,
                 sent      => $sent,
                 id        => $mid,
                 replyable => $replyable,
              } );
    }
    $sql->finish();

    return ($msgs);
}



=head2 markRead

  Mark a message as read.

=cut

sub markRead
{
    my ( $self, $id ) = (@_);

    #
    #  Get our username and make sure it exists.
    #
    my $username = $self->{ 'username' };
    die "No username" unless defined($username);

    #
    # Get the database and session.
    #
    my $db = Singleton::DBI->instance();
    my $sql = $db->prepare(
                "UPDATE messages SET status='read' WHERE recipient=? AND id=?");
    $sql->execute( $username, $id );
    $sql->finish();

    #
    #  Invalidate cache.
    #
    $self->invalidateCache();

}


=head2 markReplied

  Mark a message a replied..

=cut

sub markReplied
{
    my ( $self, $id ) = (@_);

    #
    #  Get our username and make sure it exists.
    #
    my $username = $self->{ 'username' };
    die "No username" unless defined($username);

    #
    # Get the database and session.
    #
    my $db = Singleton::DBI->instance();
    my $sql = $db->prepare(
                "UPDATE messages SET replied=NOW() WHERE recipient=? AND id=?");
    $sql->execute( $username, $id );
    $sql->finish();

    my $sql2 = $db->prepare(
                "UPDATE messages SET status='read' WHERE recipient=? AND id=?");
    $sql2->execute( $username, $id );
    $sql2->finish();

    #
    #  Invalidate cache.
    #
    $self->invalidateCache();

}



=head2 getMessages

  Return an array of all the messages for the given user.

=cut

sub getMessages
{
    my ($self) = (@_);

    #
    #  Get our username and make sure it exists.
    #
    my $username = $self->{ 'username' };
    die "No username" unless defined($username);

    #
    #  Fetch from the cache?
    #
    my $cache = Singleton::Memcache->instance();
    my $msgs  = $cache->get("messages_for_$username");
    if ( defined($msgs) )
    {
        return ($msgs);
    }

    #
    #  Not found, get from the database.
    #
    my $db = Singleton::DBI->instance();

    my $sql = $db->prepare(
        "SELECT id,sender,recipient,bodytext,status,replied,sent FROM messages WHERE recipient=? ORDER BY sent DESC"
    );
    $sql->execute($username) or die "SQL error " . $db->errstr();

    my ( $id, $from, $to, $text, $status, $replied, $sent );
    $sql->bind_columns( undef, \$id, \$from, \$to, \$text, \$status, \$replied,
                        \$sent );

    #
    #  Fetch the results.
    #
    $msgs = [];
    while ( $sql->fetch() )
    {

        # new message?
        my $new = 0;

        # can we reply?
        my $replyable = 1;

        $new = 1 if ( $status eq "new" );
        $replyable = 0 if ( $from =~ /^messages$/i );

        push( @$msgs,
              {  from      => $from,
                 id        => $id,
                 new       => $new,
                 replied   => $replied,
                 sent      => $sent,
                 replyable => $replyable,
              } );
    }
    $sql->finish();

    #
    #  Store in the cache
    #
    $cache->set( "messages_for_$username", $msgs );
    return ($msgs);

}



=head2 deleteMessage

  Delete a given message.

=cut

sub deleteMessage
{
    my ( $self, $id ) = (@_);

    #
    #  Get our username and make sure it exists.
    #
    my $username = $self->{ 'username' };
    die "No username" unless defined($username);

    #
    # Perform the deletion.
    #
    my $db  = Singleton::DBI->instance();
    my $sql = $db->prepare("DELETE FROM messages WHERE recipient=? AND id=?");
    $sql->execute( $username, $id );
    $sql->finish();


    #
    #  Invalidate our cache.
    #
    $self->invalidateCache();
}



=head2 deleteOldMessages

  Delete messages older than the given number of days

=cut

sub deleteOldMessages
{
    my ( $self, $days ) = (@_);

    die "Invalid period" if ( $days !~ /^([0-9]+)$/ );

    #
    #  Get the username
    #
    my $username = $self->{ 'username' };

    #
    #  Get the database handle
    #
    my $dbi = Singleton::DBI->instance();

    #
    #  Delete the messages
    #
    my $sql = $dbi->prepare(
        "DELETE FROM messages WHERE recipient=? AND status='read' AND DATEDIFF( NOW(), sent ) >= ?"
    );
    $sql->execute( $username, $days ) or
      die "Failed to delete messages " . $dbi->errstr();
    $sql->finish();

    #
    #  Flush our cache
    #
    $self->invalidateCache();
}



=head2 deleteByUser

  Delete all messages for the given user.

=cut

sub deleteByUser
{
    my ($self) = (@_);

    #
    #  Get our username and make sure it exists.
    #
    my $username = $self->{ 'username' };
    die "No username" unless defined($username);

    #
    # Perform the deletion.
    #
    my $db  = Singleton::DBI->instance();
    my $sql = $db->prepare("DELETE FROM messages WHERE recipient=?");
    $sql->execute($username);
    $sql->finish();


    #
    #  Invalidate our cache.
    #
    $self->invalidateCache();
}



=head2 invalidateCache

  Clean any cached content we might have.

=cut

sub invalidateCache
{
    my ($class) = (@_);

    #
    #  Get our username
    #
    my $username = $class->{ 'username' };

    #
    #  Make sure we have one.
    #
    die "No username" unless defined($username);

    #
    #  Flush the cached data
    #
    my $cache = Singleton::Memcache->instance();
    $cache->delete("total_messages_for_$username");
    $cache->delete("unread_messages_for_$username");
    $cache->delete("messages_for_$username");
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
