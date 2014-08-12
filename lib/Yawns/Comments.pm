# -*- cperl -*- #

=head1 NAME

Yawns::Comments - A module for working with comments upon something..

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Comments;
    use strict;

    my $comments = Yawns::Comments->new( article => 40 );

    my $data = $comments->get( $);


=for example end


=head1 DESCRIPTION

This module contains code for dealing with a collection of comments.

The comments might be upon a weblog entry, a poll, or an article.

=cut


package Yawns::Comments;

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
use conf::SiteConfig;
use HTML::Balance;
use HTML::BreakupText;
use HTML::Linkize;
use Singleton::DBI;
use Singleton::Session;
use Yawns::Date;
use Yawns::User;
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



=head2 get

  Return the comments associated with a given article, poll, or weblog
 entry.

=cut

sub get
{
    my ($class) = (@_);

    #
    #  Get the various attributes of the current user.
    #
    my $session = Singleton::Session->instance();
    my $username = $session->param("logged_in") || "Anonymous";

    #
    #  Are we logged in?
    #
    my $logged_in = 1;
    $logged_in = 0 if ( $username =~ /^anonymous$/i );


    #
    # Can the user see the full IP address of comments?
    #
    my $comment_admin = 0;
    my $perms = Yawns::Permissions->new( username => $username );
    if ( $perms->check( priv => "edit_comments" ) )
    {
        $comment_admin = 1;
    }


    my $comments;


    #
    # See what we're getting the comments from and fetch
    # them appropriately.
    #
    if ( ( defined( $class->{ 'article' } ) ) &&
         ( $class->{ 'article' } =~ /([0-9]+)/ ) )
    {
        $comments = _get_article_comments( $class->{ 'article' } );
    }
    elsif ( ( defined( $class->{ 'poll' } ) ) &&
            ( $class->{ 'poll' } =~ /([0-9]+)/ ) )
    {
        $comments =
          _get_poll_comments( $class->{ 'poll' }, $class->{ 'enabled' } );
    }
    elsif ( ( defined( $class->{ 'weblog' } ) ) &&
            ( $class->{ 'weblog' } =~ /([0-9]+)/ ) )
    {
        $comments =
          _get_weblog_comments( $class->{ 'weblog' }, $class->{ 'enabled' } );
    }
    else
    {
        die
          "'article', 'poll', or 'weblog' are the only supported comment holders";
    }


    #
    #  Now we need to modify the comments:
    #
    #
    # 1. Logged in users get a 'report' link.
    # 2. Administrators get a 'delete' link.
    # 3. Non-administrators don't get to see the IP addresses.
    #
    #
    my $updated;
    foreach my $c (@$comments)
    {
        if ($comment_admin)
        {
            $c->{ 'comment_admin' } = 1;
        }
        else
        {
            $c->{ 'comment_admin' } = 0;

            my $ip = $c->{ 'ip' };

            if ( defined($ip) && length($ip) )
            {
                if ( $ip =~ /([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/ )
                {
                    $c->{ 'ip' } = $1 . "." . $2 . ".xx.xx";
                }
                if ( $ip =~ /^([^:]+):/ )
                {
                    $c->{ 'ip' } = $1 . ":0xx:0xx:0xxx:0xxx:0xxx:xx";
                }
            }
        }

        if ($logged_in)
        {
            $c->{ 'report' } = 1;
        }

        push @$updated, $c;
    }
    return ($updated);
}



=head2 getRecent

  Return the most recent comments posted, this is used for the recent
 comments RSS feed.

=cut


sub getRecent
{
    my ( $class, $count ) = (@_);

    #
    #  Get access to singleton objects
    #
    my $db = Singleton::DBI->instance();

    my $sql = $db->prepare(
        "SELECT title,body,root,type,id,author FROM comments WHERE score>0 ORDER BY ondate DESC LIMIT 0,$count"
    );

    #
    # get required data
    #
    $sql->execute();


    #
    # Bind our results.
    #
    my ( $title, $body, $root, $type, $id, $author );
    $sql->bind_columns( undef, \$title, \$body, \$root, \$type, \$id,
                        \$author );

    #
    # What we return to the caller.
    #
    my $comments = [];
    my $teasers  = [];

    while ( $sql->fetch() )
    {

        # Make sure body is well-formed.
        $body = HTML::Balance::balance($body);

        #
        #  Comment link
        #
        my $link;
        if ( defined( $ENV{ 'SERVER_NAME' } ) )
        {
            $link = "http://";
            if ( defined( $ENV{ 'HTTPS' } ) && ( $ENV{ 'HTTPS' } =~ /on/i ) )
            {
                $link = "https://";
            }
            $link .= $ENV{ 'SERVER_NAME' };
        }
        else
        {
            $link = get_conf('home_url');
        }


        #
        # Type must be set.
        #
        die "Error at $root - $id" if ( !defined($type) );


        if ( $type eq "a" )
        {
            $link .= "/articles/" . $root . "#comment_" . $id;
        }
        if ( $type eq "p" )
        {
            $link .= "/polls/" . $root . "#comment_" . $id;
        }
        if ( $type eq "w" )
        {
            my $w = Yawns::Weblog->new( gid => $root );
            $link .= $w->getLink();
            $link .= "#comment_$id";
        }

        push( @$comments,
              {  body   => encode_entities($body),
                 title  => $title,
                 link   => $link,
                 author => $author,
              } );
        push( @$teasers, { link => $link, } );
    }


    return ( $teasers, $comments );
}



=head2 getRecentByUser

  Return the most recent comments posted by the given user.

=cut


sub getRecentByUser
{
    my ( $class, $username ) = (@_);


    #
    #  Get access to singleton objects
    #
    my $db = Singleton::DBI->instance();

    my $sql = $db->prepare(
        "SELECT title,body,root,type,id,author FROM comments WHERE score>0 AND author=? ORDER BY ondate DESC LIMIT 0,10"
    );

    #
    # get required data
    #
    $sql->execute($username);


    #
    # Bind our results.
    #
    my ( $title, $body, $root, $type, $id, $author );
    $sql->bind_columns( undef, \$title, \$body, \$root, \$type, \$id,
                        \$author );

    #
    # What we return to the caller.
    #
    my $comments = [];
    my $teasers  = [];

    while ( $sql->fetch() )
    {

        # Make sure body is well-formed.
        $body = HTML::Balance::balance($body);

        #
        #  Comment link
        #
        my $link;
        if ( defined( $ENV{ 'SERVER_NAME' } ) )
        {
            $link = "http://";
            if ( defined( $ENV{ 'HTTPS' } ) && ( $ENV{ 'HTTPS' } =~ /on/i ) )
            {
                $link = "https://";
            }
            $link .= $ENV{ 'SERVER_NAME' };
        }
        else
        {
            $link = get_conf('home_url');
        }


        #
        # Type must be set.
        #
        die "Error at $root - $id" if ( !defined($type) );


        if ( $type eq "a" )
        {
            $link .= "/articles/" . $root . "#comment_" . $id;
        }
        if ( $type eq "p" )
        {
            $link .= "/polls/" . $root . "#comment_" . $id;
        }
        if ( $type eq "w" )
        {
            my $w = Yawns::Weblog->new( gid => $root );
            $link .= $w->getLink();
            $link .= "#comment_$id";
        }

        push( @$comments,
              {  body   => encode_entities($body),
                 title  => $title,
                 link   => $link,
                 author => $author,
              } );
        push( @$teasers, { link => $link, } );
    }

    #
    # Return
    #
    return ( $teasers, $comments );
}



=head2 getReported

  Return the most recent comments which have been reported.

  This is used for an RSS feed.

=cut


sub getReported
{
    my ( $class, $count ) = (@_);

    #
    #  Get access to singleton objects
    #
    my $db = Singleton::DBI->instance();

    my $sql = $db->prepare(
        "SELECT title,body,root,type,id,author,ip,score,ondate FROM comments WHERE score != 5 AND score != -1 ORDER BY id ASC LIMIT 0,$count"
    );

    #
    # get required data
    #
    $sql->execute();


    #
    # Bind our results.
    #
    my ( $title, $body, $root, $type, $id, $author, $ip, $score, $ondate );
    $sql->bind_columns( undef,   \$title, \$body,   \$root,
                        \$type,  \$id,    \$author, \$ip,
                        \$score, \$ondate
                      );

    #
    # What we return to the caller.
    #
    my $comments = [];
    my $teasers  = [];

    while ( $sql->fetch() )
    {

        # Make sure body is well-formed.
        $body = HTML::Balance::balance($body);

        # convert date and time to more readable format
        my ( $postdate, $posttime ) =
          Yawns::Date::convert_date_to_site($ondate);


        #
        #  Comment link
        #
        my $link;
        if ( defined( $ENV{ 'SERVER_NAME' } ) )
        {
            $link = "http://";
            if ( defined( $ENV{ 'HTTPS' } ) && ( $ENV{ 'HTTPS' } =~ /on/i ) )
            {
                $link = "https://";
            }
            $link .= $ENV{ 'SERVER_NAME' };
        }
        else
        {
            $link = get_conf('home_url');
        }

        #
        # Type must be set.
        #
        die "Error at $root - $id" if ( !defined($type) );


        if ( $type eq "a" )
        {
            $link .= "/articles/" . $root . "#comment_" . $id;
        }
        if ( $type eq "p" )
        {
            $link .= "/polls/" . $root . "#comment_" . $id;
        }
        if ( $type eq "w" )
        {
            my $w = Yawns::Weblog->new( gid => $root );
            $link .= $w->getLink();
            $link .= "#comment_$id";
        }

        #
        # Strip faux IPv6 prefix, introduced by nginx
        #
        $ip =~ s/^::ffff://g;

        push( @$comments,
              {  body     => encode_entities($body),
                 title    => $title,
                 link     => $link,
                 ip       => $ip,
                 score    => $score,
                 author   => $author,
                 postdate => $postdate,
                 posttime => $posttime,
              } );
        push( @$teasers, { link => $link, } );
    }

    return ( $teasers, $comments );
}



=head2 getCommentFeed

  Return the a hash of comments suitable for the RSS feeds.

=cut

sub getCommentFeed
{
    my ( $class, %params ) = (@_);

    #
    #  Find out what we're getting.
    #
    if ( ( defined( $params{ 'article' } ) ) &&
         ( $params{ 'article' } =~ /([0-9]+)/ ) )
    {
        return ( _getCommentFeed( $params{ 'article' }, 'a' ) );
    }
    elsif ( ( defined( $params{ 'weblog' } ) ) &&
            ( $params{ 'weblog' } =~ /([0-9]+)/ ) )
    {
        return ( _getCommentFeed( $params{ 'weblog' }, 'w' ) );
    }
    elsif ( ( defined( $params{ 'poll' } ) ) &&
            ( $params{ 'poll' } =~ /([0-9]+)/ ) )
    {
        return ( _getCommentFeed( $params{ 'poll' }, 'p' ) );
    }
    else
    {
        die "Invalid type of comment feed!";
    }
}



=head2 _getCommentFeed

  Fetch the comments for a feed on a poll, weblog, or blog entry.

  This routine manages the caching, and the fetching from the
 database.

=cut

sub _getCommentFeed
{
    my ( $root, $type ) = (@_);

    #
    #  Get access to singleton objects
    #
    my $db = Singleton::DBI->instance();

    my $sql = $db->prepare(
        "SELECT title,body,id FROM comments WHERE root=? AND TYPE=? AND score>0 ORDER BY id ASC"
    );

    #
    # get required data
    #
    $sql->execute( $root, $type );


    #
    #  Now bind the results.
    #
    my ( $title, $body, $id );
    $sql->bind_columns( undef, \$title, \$body, \$id );

    #
    #  What we return to the caller.
    #
    my $comments = [];
    my $teasers  = [];

    #
    #  Add each match to the result.
    #
    while ( $sql->fetch() )
    {

        # Make sure body is balanced
        $body = HTML::Balance::balance($body);

        #
        #  Comment link
        #
        my $link;
        if ( defined( $ENV{ 'SERVER_NAME' } ) )
        {
            $link = "http://";
            if ( defined( $ENV{ 'HTTPS' } ) && ( $ENV{ 'HTTPS' } =~ /on/i ) )
            {
                $link = "https://";
            }
            $link .= $ENV{ 'SERVER_NAME' };
        }
        else
        {
            $link = get_conf('home_url');
        }

        #
        # Type must be set.
        #
        die "Error at $root - $id" if ( !defined($type) );


        if ( $type eq "a" )
        {
            $link .= "/articles/" . $root . "#comment_" . $id;
        }
        if ( $type eq "p" )
        {
            $link .= "/polls/" . $root . "#comment_" . $id;
        }
        if ( $type eq "w" )
        {
            my $w = Yawns::Weblog->new( gid => $root );
            $link .= $w->getLink();
            $link .= "#comment_$id";
        }

        push( @$comments,
              {  body  => encode_entities($body),
                 title => $title,
                 link  => $link,
              } );
        push( @$teasers, { link => $link, } );
    }

    return ( $teasers, $comments );
}



=head2 _get_article_comments

 Get and arrange the comments for an article

=cut

sub _get_article_comments
{
    my ($article_id) = (@_);


    #
    #  If not fetch from database
    #
    my $comments = _get_comments( 'a', 1, $article_id, 0, 0 );
    return ($comments);
}



=head2 _get_weblog_comments

  Get all weblog comments for the given entry.

=cut

sub _get_weblog_comments
{
    my ( $weblog_id, $enabled ) = @_;

    #
    #  Fetch from the database.
    #
    my $comments = _get_comments( 'w', $enabled, $weblog_id, 0, 0 );

    return ($comments);
}


#
# Get and arrange the comments for an article.
#
sub _get_poll_comments
{

    # Get and arrange the comments for a poll
    my ( $poll_id, $enabled ) = @_;

    #
    #  Fetch from database
    #
    my $comments = _get_comments( 'p', $enabled, $poll_id, 0, 0 );

    return ($comments);
}



=head2 _get_comments

   Get the comments for a particular poll, or article.

  Type is 'a' for article comments.
       or 'p' for poll comments.
       or 'w' for weblog comments

  'Enabled' is whether replies are ellowed for the given poll or
 article.

=cut

sub _get_comments
{
    my ( $type, $enabled, $root, $parent, $depth, $comments ) = (@_);

    #
    #  Find the currently logged in username.
    #
    my $db       = Singleton::DBI->instance();
    my $session  = Singleton::Session->instance();
    my $username = $session->param("logged_in") || "Anonymous";

    #
    # Can the user see the full IP address of comments?
    #
    my $comment_admin = 0;
    my $perms = Yawns::Permissions->new( username => $username );
    if ( $perms->check( priv => "edit_comments" ) )
    {
        $comment_admin = 1;
    }

    my $linker = HTML::Linkize->new();


    my $sql = $db->prepare(
        'SELECT a.*,b.suspended FROM comments AS a JOIN users AS b WHERE root=? AND parent=? and type=? AND b.username = a.author AND a.score>0 ORDER BY id ASC'
    );

    # get required data
    $sql->execute( $root, $parent, $type );

    my $commentref = $sql->fetchall_arrayref;
    my $len        = @$commentref;


    for ( my $l = 0 ; $l < $len ; $l++ )
    {

        my $comment = @$commentref[$l];
        my @comment = @$comment;



        # convert date and time to more readable format
        my ( $postdate, $posttime ) =
          Yawns::Date::convert_date_to_site( $comment[4] );

        my $indent = [];
        for ( my $d = 1 ; $d <= ($depth) ; $d++ )
        {
            push( @$indent, { space => ' ' } );
        }

        #
        # Steve
        #
        $comment[5] =~ s/&amp;#13;//g;
        $comment[5] =~ s/&amp;quot;/\"/g;
        $comment[5] =~ s/&amp;amp;/&/g;
        $comment[5] =~ s/&amp;lt;/&lt;/g;
        $comment[5] =~ s/&amp;gt;/&gt;/g;

        #
        # Get the user modifier for the comment author.
        #
        my $usr = Yawns::User->new( username => $comment[3] );
        my $magic = $usr->getModifier();

        #
        # Breakup long lines.
        #
        my $filter = HTML::BreakupText->new( width => 65 );
        my $body_text = $comment[5];

        #
        #  Add links, then breakup text.
        #
        $body_text = $linker->linkize($body_text);
        $body_text = $filter->BreakupText($body_text);
        $body_text = HTML::Balance::balance($body_text);

        #
        # Strip faux IPv6 prefix, introduced by nginx
        #
        my $ip = $comment[6];
        die
          "IP not found for comments: type=$type root=$root parent=$parent depth=$depth"
          unless ($ip);


        $ip =~ s/^::ffff://g;

        my $c;
        if ( $type eq 'a' )
        {


            #
            #  Article comments
            #
            $c = push( @$comments,
                       {  comment_id    => $comment[0],
                          article_id    => $comment[7],
                          title         => $comment[2],
                          byuser        => $comment[3],
                          ondate        => $postdate,
                          attime        => $posttime,
                          body          => $body_text,
                          ip            => $ip,
                          comment_admin => $comment_admin,
                          indent        => $indent,
                          modifier      => $magic,
                          enabled       => $enabled,
                          parent        => $comment[1],
                          suspended     => $comment[10],
                       } );
        }
        if ( $type eq 'p' )
        {

            #
            #  Poll comments.
            #
            $c = push( @$comments,
                       {  comment_id    => $comment[0],
                          is_poll       => 1,
                          poll          => $comment[7],
                          title         => $comment[2],
                          byuser        => $comment[3],
                          ondate        => $postdate,
                          attime        => $posttime,
                          body          => $body_text,
                          ip            => $ip,
                          comment_admin => $comment_admin,
                          indent        => $indent,
                          modifier      => $magic,
                          enabled       => $enabled,
                          parent        => $comment[1],
                          suspended     => $comment[10],
                       } );
        }
        if ( $type eq 'w' )
        {
            my $weblog = Yawns::Weblog->new( gid => $comment[7] );
            my $weblog_link = $weblog->getLink();


            #
            #  Weblog comments
            #
            $c = push( @$comments,
                       {  weblog_id     => $comment[7],
                          weblog_link   => $weblog_link,
                          comment_id    => $comment[0],
                          title         => $comment[2],
                          byuser        => $comment[3],
                          ondate        => $postdate,
                          attime        => $posttime,
                          body          => $body_text,
                          ip            => $ip,
                          comment_admin => $comment_admin,
                          indent        => $indent,
                          modifier      => $magic,
                          enabled       => $enabled,
                          parent        => $comment[1],
                          suspended     => $comment[10],
                       } );
        }

        _get_comments( $type,       $enabled, $root,
                       $comment[0], ++$depth, $comments );
        $depth--;
    }
    $sql->finish();

    # return the requested values
    return ($comments);
}


=begin doc

Hide all comments by the user.

=end doc

=cut

sub hideByUser
{
    my ( $self, %params ) = (@_);

    my $username = $params{ 'username' } || $self->{ 'username' } || undef;

    my $dbi = Singleton::DBI->instance();
    my $sql = $dbi->prepare("UPDATE  comments SET score=-1 WHERE author=?");
    $sql->execute($username);
    $sql->finish();

}



=head2 invalidateCache

  Invalidate any cached comments in memory.

=cut

sub invalidateCache
{
    my ($class) = (@_);
}


1;
