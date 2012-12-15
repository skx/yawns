# -*- cperl -*- #

=head1 NAME

Yawns::Comment::Notifier - Alert a user of a comment reply.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Comment::Notifier;
    use strict;

    my $alert = Yawns::Comment::Notifier->new( article => 1,
                                               comment => 0 );

    $alert->send();

=for example end


=head1 DESCRIPTION

This module contains code for notifying a user that there is a comment
posted, either:

  * In reply to a comment they left upon the site.
  * In reply to a weblog entry they made.
  * In reply to an article they wrote.

=cut


package Yawns::Comment::Notifier;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.12 $' =~ m/Revision:\s*(\S+)/;


#
#  Yawns modules which we use.
#
use conf::SiteConfig;
use Singleton::DBI;

use Yawns::Article;
use Yawns::Mailer;
use Yawns::Messages;
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



=head2 sendNotification

  This routine is invoked when a new comment is posted upon the site,
 it is responsible for sending out a notification email or message.

  This depends upon the preferences of the recipient.

=cut

sub sendNotification
{
    my ( $self, $new_id ) = (@_);

    #
    #  Get the details
    #
    my $oncomment = $self->{ 'oncomment' };
    my $onweblog  = $self->{ 'onweblog' };
    my $onpoll    = $self->{ 'onpoll' };
    my $onarticle = $self->{ 'onarticle' };

    #
    #  Comment replies.
    #
    if ( defined($oncomment) && ( $oncomment =~ /^([0-9]+)$/ ) )
    {
        $self->commentReply($new_id);
    }
    else
    {

        #
        #  Reply to either an article, weblog, or poll.
        #
        if ( defined($onarticle) && ( $onarticle =~ /^([0-9]+)$/ ) )
        {

            # Reply to an article
            $self->articleReply($new_id);
        }
        elsif ( defined($onpoll) && ( $onpoll =~ /^([0-9]+)$/ ) )
        {

            # NOP - we don't care about replies to polls.
            return;
        }
        elsif ( defined($onweblog) && ( $onweblog =~ /^([0-9]+)$/ ) )
        {

            # Notification of a reply to a weblog.
            $self->weblogReply($new_id);
        }
        else
        {
            die "Unknown notification method";
        }
    }

}



=head2 getNotificationKeys

  Return the keys we have available for notication use.

  This is used for cache cleaning, and testing.

=cut

sub getNotificationKeys
{
    return (qw/ article comment weblog submissions /);
}



=head2  getNotificationMethod

  See if the user wants the given notifications

=cut

sub getNotificationMethod
{
    my ( $self, $user, $type ) = (@_);

    #
    #  Not in the cache so get from the database.
    #
    my $dbi = Singleton::DBI->instance();

    #
    #  Prepare and execute the SQL.
    #
    my $sql = $dbi->prepare(
                 "SELECT type FROM notifications WHERE username=? AND event=?");
    $sql->execute( $user, $type ) or die "Failed to execute " . $dbi->errstr();

    my @ret = $sql->fetchrow_array();
    my $result = $ret[0];
    $sql->finish();

    return ($result);
}



=head2 deleteNotifications

  Delete any notification options for the given user.

=cut

sub deleteNotifications
{
    my ($self) = (@_);

    #
    #  Delete all notification preferences.
    #
    my $dbi = Singleton::DBI->instance();
    my $sql = $dbi->prepare("DELETE FROM notifications WHERE username=?");
    $sql->execute( $self->{ 'username' } ) or
      die "failed to delete notifications: " . $dbi->errstr();
    $sql->finish();

}



=head2 setupNewUser

  Setup the default options for a new user.

=cut

sub setupNewUser
{
    my ($self) = (@_);

    $self->save( article => "email",
                 comment => "email",
                 weblog  => "email"
               );
}



=head2 save

  Save updated preferences

=cut

sub save
{
    my ( $self, %params ) = (@_);

    #
    #  delete any existing notifications.
    #
    $self->deleteNotifications();

    #
    #  Get the database handle.
    #
    my $dbi = Singleton::DBI->instance();

    #
    #  Now insert the new values.
    #
    my $a = $dbi->prepare(
             "INSERT INTO notifications (username,event,type) VALUES( ?,?,? )");
    $a->execute( $self->{ 'username' }, "article", $params{ 'article' } ) or
      die "Failed to update" . $dbi->errstr();
    $a->finish();

    my $b = $dbi->prepare(
             "INSERT INTO notifications (username,event,type) VALUES( ?,?,? )");
    $b->execute( $self->{ 'username' }, "comment", $params{ 'comment' } ) or
      die "Failed to update" . $dbi->errstr();
    $b->finish();

    my $c = $dbi->prepare(
             "INSERT INTO notifications (username,event,type) VALUES( ?,?,? )");
    $c->execute( $self->{ 'username' }, "weblog", $params{ 'weblog' } ) or
      die "Failed to update" . $dbi->errstr();
    $c->finish();

    if ( defined( $params{ 'submissions' } ) )
    {
        my $d = $dbi->prepare(
             "INSERT INTO notifications (username,event,type) VALUES( ?,?,? )");
        $d->execute( $self->{ 'username' },
                     "submissions", $params{ 'submissions' } ) or
          die "Failed to update" . $dbi->errstr();
        $d->finish();
    }


    #
    #  Flush our cache
    #
    $self->invalidateCache();
}



=head2 articleReply

  Process a comment which has been posted in response to an article.

=cut

sub articleReply
{
    my ( $self, $id ) = (@_);

    #
    #  Get the person who just posted the reply
    #
    my $session = Singleton::Session->instance();
    my $sender = $session->param("logged_in") || "Anonymous";

    #
    #  Find the username of the article poster.
    #
    my $article      = Yawns::Article->new( id => $self->{ 'onarticle' } );
    my $article_data = $article->get();
    my $author       = $article_data->{ 'article_byuser' };
    my $title        = $article_data->{ 'article_title' };

    #
    #  No notifications for anonymous article posters.
    #
    return if ( $author =~ /^anonymous$/i );

    #
    #  Get the email address of the article poster.
    #
    my $user = Yawns::User->new( username => $author );
    my $data = $user->get();
    my $mail = $data->{ 'realemail' };

    #
    #  Now test the notification the user wants.
    #
    my $method = $self->getNotificationMethod( $author, "article" );

    #
    #  No notification?
    #
    return if ( $method =~ /^none$/i );

    #
    #  Do we want to get a notification by site-message?
    #
    if ( $method =~ /^message$/ )
    {
        my $text = <<EOM;

<a href="/users/$sender">$sender</a> has <a href="/articles/$self->{'onarticle'}#comment_$id">posted a new comment</a> in reply to your article <a href="/articles/$self->{'onarticle'}">$title</a>.

EOM

        #
        #  Send the message
        #
        my $msg = Yawns::Messages->new( username => "Messages" );
        $msg->send( to   => $author,
                    body => $text );

    }

    #
    #  OK notification by email it is.
    #
    if ( $method =~ /^email$/i )
    {
        my $mailer = Yawns::Mailer->new();
        $mailer->newArticleReply( $mail, $title, $self->{ 'onarticle' },
                                  $sender, $id );
    }
}



=head2 commentReply

  Reply to a posted comment

=cut

sub commentReply
{
    my ( $self, $id ) = (@_);

    my $oncomment = $self->{ 'oncomment' };
    my $onweblog  = $self->{ 'onweblog' };
    my $onpoll    = $self->{ 'onpoll' };
    my $onarticle = $self->{ 'onarticle' };

    #
    #  Get the person who just posted the reply
    #
    my $session = Singleton::Session->instance();
    my $sender = $session->param("logged_in") || "Anonymous";

    #
    #  Find the username of the comment we've received a reply to.
    #
    my $comment = Yawns::Comment->new( article => $onarticle,
                                       poll    => $onpoll,
                                       weblog  => $onweblog,
                                       id      => $oncomment
                                     );
    my $commentStuff  = $comment->get();
    my $parent_author = $commentStuff->{ 'author' };
    my $parent_title  = $commentStuff->{ 'title' };

    #
    #  Get the email address of that user.
    #
    my $user = Yawns::User->new( username => $parent_author );
    my $data = $user->get();
    my $mail = $data->{ 'realemail' };

    #
    #  Now test the notification the user wants.
    #
    my $method = $self->getNotificationMethod( $parent_author, "comment" );

    #
    #  No notification?
    #
    return if ( $method =~ /^none$/i );

    #
    #  Do we want to get a notification by site-message?
    #
    if ( $method =~ /^message$/ )
    {

        #
        #  Build up the link to the comment.
        #
        my $link = '';

        if ($onpoll)
        {
            $link = "/polls/$onpoll";
        }
        elsif ($onarticle)
        {
            $link = "/articles/$onarticle";
        }
        elsif ($onweblog)
        {
            my $w            = Yawns::Weblog->new( gid => $onweblog );
            my $weblog_owner = $w->getOwner();
            my $weblog_id    = $w->getID();
            $link = "/users/$weblog_owner/weblog/$weblog_id";
        }
        else
        {
            die "Uknown type in the comment notification code.";
        }
        $link .= "#comment_" . $id;

        my $text = <<EOM;

<a href="/users/$sender">$sender</a> has <a href="$link">posted a new comment</a> in reply a comment you left.

EOM

        #
        #  Send the message
        #
        my $msg = Yawns::Messages->new( username => "Messages" );
        $msg->send( to   => $parent_author,
                    body => $text );

    }

    #
    #  OK notification by email it is.
    #
    if ( $method =~ /^email$/i )
    {
        my $mailer = Yawns::Mailer->new();
        $mailer->newCommentReply( $mail, $parent_title, $onarticle, $onpoll,
                                  $onweblog, $sender, $id );
    }
}



=head2 weblogReply

  Reply to a weblog entry

=cut

sub weblogReply
{
    my ( $self, $id ) = (@_);

    #
    #  Get the person who just posted the reply
    #
    my $session = Singleton::Session->instance();
    my $sender = $session->param("logged_in") || "Anonymous";

    #
    #  Find the username of the article poster.
    #
    my $weblog = Yawns::Weblog->new( gid => $self->{ 'onweblog' } );
    my $owner  = $weblog->getOwner();
    my $title  = $weblog->getTitle();

    #
    #  Get the email address of that user.
    #
    my $user = Yawns::User->new( username => $owner );
    my $data = $user->get();
    my $mail = $data->{ 'realemail' };

    #
    #  Now test the notification the user wants.
    #
    my $method = $self->getNotificationMethod( $owner, "weblog" );

    #
    #  No notification?
    #
    return if ( $method =~ /^none$/i );

    #
    #  Do we want to get a notification by site-message?
    #
    if ( $method =~ /^message$/ )
    {
        my $weblog_id   = $weblog->getID();
        my $weblog_link = "/users/$owner/weblog/$weblog_id";

        my $text = <<EOM;

<a href="/users/$sender">$sender</a> has <a href="$weblog_link#comment_$id">posted a new comment</a> in reply to your weblog entry <a href="$weblog_link">$title</a>.

EOM

        #
        #  Send the message
        #
        my $msg = Yawns::Messages->new( username => "Messages" );
        $msg->send( to   => $owner,
                    body => $text );

    }

    #
    #  OK notification by email it is.
    #
    if ( $method =~ /^email$/i )
    {
        my $mailer = Yawns::Mailer->new();
        $mailer->newWeblogReply( $mail,                    # address
                                 $title,                   # title
                                 $self->{ 'onweblog' },    #gid
                                 $owner,                   # owner
                                 $weblog->getID(),         # entry
                                 $sender,                  # author
                                 $id
                               );     # id
    }
}



=head2 invalidateCache

  Clean any cached content we might have.

=cut

sub invalidateCache
{
    my ($self) = (@_);
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
