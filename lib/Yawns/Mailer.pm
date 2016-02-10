# -*- cperl -*- #

=head1 NAME

Yawns::Mailer - An interface to sending email.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Mailer;
    use strict;

    my $mailer  = Yawns::Mailer->new();

    $mailer->newComment();

    $mailer->newWeblogReply();


=for example end


=head1 DESCRIPTION

This module contains code for sending out email notices about new
comments in response to:

=over 8

=item Comments posted in reply to articles.

=item Comments posted in reply to weblog entries.

=item A new article submission.

=back

=cut


package Yawns::Mailer;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;


@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.11 $' =~ m/Revision:\s*(\S+)/;


#
#  Standard modules which we require.
#
use strict;
use warnings;


#
#  Yawns modules which we use.
#
use conf::SiteConfig;
use Yawns::Weblog;



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



=head2 newArticleSubmission

  This function will mail a user about a new submission

=cut

sub newArticleSubmission
{
    my ( $self, $recipient, $username, $title, $body, $ip ) = (@_);


    #
    #  Get the sendmail path.
    #
    my $sendmail = conf::SiteConfig::get_conf('sendmail_path');
    my $sender   = conf::SiteConfig::get_conf('submission_mail');

    #
    # If we don't have sendmail setup then we'll not send out a notice.
    #
    if ( ( !defined($sendmail) ) or
         ( length($sendmail) < 1 ) )
    {
        return;
    }

    my $template =
      HTML::Template->new(
                      filename => "../templates/mail/new-submission.template" );

    $template->param( to         => $recipient,
                      from       => $sender,
                      author     => $username,
                      title      => $title,
                      article    => $body,
                      ip_address => $ip
                    );

    open( SENDMAIL, "|$sendmail -f $sender" ) or
      die "Cannot open $sendmail: $!";
    print( SENDMAIL $template->output() );
    close(SENDMAIL);
}



=head2 newArticleReply

  This function will send an email notification to an article
 author when a new comment has been posted in reply to it.

=cut

sub newArticleReply
{
    my ( $self, $address, $title, $id, $author, $comment, $ip ) = (@_);

    #
    #  Details to include in the mail.
    #
    my $sitename = get_conf('sitename');
    my $sender   = get_conf('bounce_email');
    my $home_url = get_conf('home_url');
    my $sendmail = get_conf('sendmail_path');

    if ( ( !defined($sendmail) ) or
         ( length($sendmail) < 1 ) )
    {
        return;
    }


    #
    #  Build up the link to the relevant comment.
    #
    my $article_link = $home_url . "/articles/$id";
    $article_link .= "#comment_" . $comment;

    #
    #  Load and complete the template.
    #
    my $template =
      HTML::Template->new(
                   filename => "../templates/mail/new-article-reply.template" );

    $template->param( sitename     => $sitename,
                      site_email   => $sender,
                      address      => $address,
                      author       => $author,
                      title        => $title,
                      article_link => $article_link,
                      home_url     => $home_url,
                      ip_address   => $ip
                    );


    open( SENDMAIL, "|$sendmail -f $sender" ) or
      die "Cannot open $sendmail: $!";
    print( SENDMAIL $template->output() );
    close(SENDMAIL);
}



=head2 newWeblogReply

  This function sends an email to the owner of a weblog when
 a new comment has been posted in reply to it.

=cut

sub newWeblogReply
{

    my ( $self, $address, $title, $gid, $owner, $entry, $author, $id, $ip ) =
      (@_);


    #
    #  Details to include in the mail.
    #
    my $sitename = get_conf('sitename');
    my $sender   = get_conf('bounce_email');
    my $home_url = get_conf('home_url');
    my $sendmail = get_conf('sendmail_path');

    if ( ( !defined($sendmail) ) or
         ( length($sendmail) < 1 ) )
    {
        return;
    }

    #
    #  Build up the link to the relevant comment.
    #
    my $comment_link = $home_url . "/users/$owner/weblog/$entry";
    $comment_link .= "#comment_" . $id;

    #
    #  Load and complete the template.
    #
    my $template =
      HTML::Template->new(
                    filename => "../templates/mail/new-weblog-reply.template" );

    $template->param( sitename     => $sitename,
                      site_email   => $sender,
                      address      => $address,
                      author       => $author,
                      title        => $title,
                      comment_link => $comment_link,
                      home_url     => $home_url,
                      ip_address   => $ip
                    );


    open( SENDMAIL, "|$sendmail -f $sender" ) or
      die "Cannot open $sendmail: $!";
    print( SENDMAIL $template->output() );
    close(SENDMAIL);
}



=head2 newCommentReply

  This function will send an email to the poster of a comment when
 a new reply has been posted to it.

=cut

sub newCommentReply
{
    my ( $self,   $address, $title,       $article, $poll,
         $weblog, $user,    $comment_num, $ip )
      = @_;

    my $sitename = get_conf('sitename');
    my $sender   = get_conf('bounce_email');
    my $home_url = get_conf('home_url');
    my $sendmail = get_conf('sendmail_path');

    if ( ( !defined($sendmail) ) or
         ( length($sendmail) < 1 ) )
    {
        return;
    }


    #
    #  Build up a link to the newly submitted comment.
    #
    my $article_link = $home_url . "/";

    if ($poll)
    {
        $article_link .= "polls/$poll";
    }
    if ($article)
    {
        $article_link .= "articles/$article";
    }
    if ($weblog)
    {
        my $w            = Yawns::Weblog->new( gid => $weblog );
        my $weblog_owner = $w->getOwner();
        my $weblog_id    = $w->getID();
        $article_link .= "users/$weblog_owner/weblog/$weblog_id";
    }
    $article_link .= "#comment_" . $comment_num;


    #
    #  Load and populate the mail template.
    #
    my $template =
      HTML::Template->new(
                   filename => "../templates/mail/new-comment-reply.template" );

    $template->param( sitename     => $sitename,
                      site_email   => $sender,
                      address      => $address,
                      user         => $user,
                      title        => $title,
                      article_link => $article_link,
                      home_url     => $home_url,
                      ip_address   => $ip
                    );


    open( SENDMAIL, "|$sendmail -f $sender" ) or
      die "Cannot open $sendmail: $!";
    print( SENDMAIL $template->output() );
    close(SENDMAIL);
}



1;


=head1 AUTHOR

Steve Kemp

http://www.steve.org.uk/



=head1 LICENSE

Copyright (c) 2005-2015 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut
