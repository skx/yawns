
=head1 NAME

Yawns::Tags - A module for working with all the tags used upon the site.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Tags;
    use strict;

    # Get all tags used upon this site.
    my $holder   = Yawns::Tags->new();
    my $all_tags = $holder->getAllTags();

=for example end


=head1 DESCRIPTION

This module contains code for working with the combined list of tags
used upon the site.

Tags may be placed upon three things:

=over 8

=item Articles

=item Pending Article Submissions

=item Polls

=item Weblog Entries

=back

Each of these is stored in the same table, with a "type" column which
identifies the type of tag.  The key is "a"rticles, "s"ubmissions and
"w"eblogs respectively.

So far there is a fair amount of duplication within this class, and
there is some poor organisation, this will be resolved shortly.

=cut


package Yawns::Tags;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;


@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.41 $' =~ m/Revision:\s*(\S+)/;


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
use Singleton::Session;

#
#  Accessors for getting titles, links, etc.
#
use Yawns::Article;
use Yawns::Poll;
use Yawns::Submissions;
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



=head2 getTags

  Return an array of tags used upon a given article, poll, submission,
 or weblog entry.

=cut

sub getTags
{
    my ( $class, %params ) = (@_);

    #
    #  These will need to be determined.
    #
    my $type = undef;
    my $root = undef;


    #
    #  Article tags?
    #
    if ( ( defined( $params{ 'article' } ) ) &&
         ( $params{ 'article' } =~ /^([0-9]+)$/ ) )
    {
        $root = $params{ 'article' };
        $type = 'a';
    }

    #
    #  Poll tags?
    #
    if ( ( defined( $params{ 'poll' } ) ) &&
         ( $params{ 'poll' } =~ /^([0-9]+)$/ ) )
    {
        $root = $params{ 'poll' };
        $type = 'p';
    }

    #
    #  Submission tags?
    #
    if ( ( defined( $params{ 'submission' } ) ) &&
         ( $params{ 'submission' } =~ /^([0-9]+)$/ ) )
    {
        $root = $params{ 'submission' };
        $type = 's';
    }

    #
    #  Weblog tags?
    #
    if ( ( defined( $params{ 'weblog' } ) ) &&
         ( $params{ 'weblog' } =~ /^([0-9]+)$/ ) )
    {
        $root = $params{ 'weblog' };
        $type = 'w';
    }

    #
    # Sanity check
    #
    die "Invalid tag fetch - root:$root type:$type" if ( ( !defined($root) ) ||
                                                         ( !defined($type) ) );


    my $tags;

    #
    # Failed to fetch from the cache, so get from the database.
    #
    my $db = Singleton::DBI->instance();

    #
    #  Run query.
    #
    my $sql = $db->prepare(
        "SELECT DISTINCT(tag) FROM tags WHERE root=? AND TYPE=? ORDER BY tag ");
    $sql->execute( $root, $type );

    #
    # Bind the columns.
    #
    my ($tag);
    $sql->bind_columns( undef, \$tag );

    while ( $sql->fetch() )
    {
        push( @$tags, { tag => $tag, } );
    }
    $sql->finish();


    return ($tags);
}



=head2 addTag

  Add a tag to the given article, poll, submission, or weblog entry.

=cut

sub addTag
{
    my ( $class, %params ) = (@_);

    #
    #  Get the tag, trim space
    #
    my $tag = $params{ 'tag' };
    $tag =~ s/^\s+|\s+$//g;

    #
    #  Disallow invalid tags.
    #
    return if ( !defined($tag) );
    return if ( $tag eq "." );
    return if ( $tag eq ".." );
    return if ( length($tag) < 1 );

    #
    #  Tags are lower-cased.
    #
    $tag = lc($tag);

    #
    #  Don't allow XSS.
    #
    $tag = HTML::Entities::encode_entities($tag);

    #
    #  Make sure we have the username.
    #
    #  If no username is given then we'll use the currently
    # logged in user, if  there is no logged in then we'll
    # use 'Anonymous'.
    #
    my $username = $params{ 'username' };
    if ( !defined($username) )
    {
        my $session = Singleton::Session->instance();
        $username = $session->param("logged_in");

        if ( !defined($username) ) {$username = 'Anonymous';}
    }

    #
    #  These will need to be determined.
    #
    my $type = undef;
    my $root = undef;


    #
    #  Article tag?
    #
    if ( ( defined( $params{ 'article' } ) ) &&
         ( $params{ 'article' } =~ /^([0-9]+)$/ ) )
    {
        $root = $params{ 'article' };
        $type = 'a';
    }

    #
    #  Poll tag?
    #
    if ( ( defined( $params{ 'poll' } ) ) &&
         ( $params{ 'poll' } =~ /^([0-9]+)$/ ) )
    {
        $root = $params{ 'poll' };
        $type = 'p';
    }

    #
    #  Submission tag.
    #
    if ( ( defined( $params{ 'submission' } ) ) &&
         ( $params{ 'submission' } =~ /^([0-9]+)$/ ) )
    {
        $root = $params{ 'submission' };
        $type = 's';
    }

    #
    #  Weblog tag.
    #
    if ( ( defined( $params{ 'weblog' } ) ) &&
         ( $params{ 'weblog' } =~ /^([0-9]+)$/ ) )
    {
        $root = $params{ 'weblog' };
        $type = 'w';
    }

    #
    # Sanity check
    #
    die "Invalid tag submission: $type / $root"
      if ( ( !defined($root) ) ||
           ( !defined($type) ) );


    #
    #  Find the userID for the specified user.
    #
    my $user    = Yawns::User->new( username => $username );
    my $data    = $user->get();
    my $user_id = $data->{ 'id' };

    #
    #  Add the tag to the database.
    #
    my $db = Singleton::DBI->instance();
    my $sql =
      $db->prepare("INSERT INTO tags(tag,root,user_id,type) VALUES(?,?,?,?)");
    $sql->execute( $tag, $root, $user_id, $type ) or die $db->errstr();
    $sql->finish();


    #
    #  Weblog caching.
    #
    if ( $type eq 'w' )
    {
        my $weblog = Yawns::Weblog->new( username => $username,
                                         gid      => $root );
        $weblog->invalidateCache();

        # Flush the weblogs - since the tip entry might be wrong.
        my $weblogs = Yawns::Weblogs->new();
        $weblogs->invalidateCache();
    }
}



=head2 deleteTags

  Delete all tags on the given article, poll, submission, or weblog.

=cut

sub deleteTags
{
    my ( $class, %params ) = (@_);

    #
    #  These will need to be determined.
    #
    my $type = undef;
    my $root = undef;


    #
    #  Article tag?
    #
    if ( ( defined( $params{ 'article' } ) ) &&
         ( $params{ 'article' } =~ /^([0-9]+)$/ ) )
    {
        $root = $params{ 'article' };
        $type = 'a';
    }

    #
    #  Poll tag?
    #
    if ( ( defined( $params{ 'poll' } ) ) &&
         ( $params{ 'poll' } =~ /^([0-9]+)$/ ) )
    {
        $root = $params{ 'poll' };
        $type = 'p';
    }

    #
    #  Submission tag.
    #
    if ( ( defined( $params{ 'submission' } ) ) &&
         ( $params{ 'submission' } =~ /^([0-9]+)$/ ) )
    {
        $root = $params{ 'submission' };
        $type = 's';
    }

    #
    #  Weblog tag.
    #
    if ( ( defined( $params{ 'weblog' } ) ) &&
         ( $params{ 'weblog' } =~ /^([0-9]+)$/ ) )
    {
        $root = $params{ 'weblog' };
        $type = 'w';


        # Flush the weblogs - since the tip entry might be wrong.
        my $weblogs = Yawns::Weblogs->new();
        $weblogs->invalidateCache();
    }

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    # Delete
    #
    my $sql = $db->prepare("DELETE FROM tags WHERE root=? AND type=?");
    $sql->execute( $root, $type );
    $sql->finish();

}



=head2 promoteSubmissionTags

  Move any tags which are associated with a pending submission from
 that onto the article which has just been posted.

  This preserves the tag content, and the tag owner.

=cut

sub promoteSubmissionTags
{
    my ( $self, $submission_id, $article_id ) = (@_);


    #
    #  NOTE:  Since the submission tags and the article tags
    # are in the same table we just need to update their type.
    #
    my $dbi = Singleton::DBI->instance();

    my $query =
      $dbi->prepare("UPDATE tags SET type=?,root=? WHERE root=? AND type=?");

    $query->execute( 'a', $article_id, $submission_id, 's' ) or
      die "Failed to update tag type" . $dbi->errstr();
    $query->finish();

}



=head2 getAllTags

  Return a hash of all the tags which have been applied upon this
 site.

  This makes no distinction between the target of the tag.

  (The type argument is optional.)

=cut

sub getAllTags
{
    my ( $class, $type ) = (@_);

    my $tags;

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    # Now the tags.
    #
    my $sql = $db->prepare(
        'SELECT DISTINCT(tag),COUNT(tag) AS runningtotal FROM tags GROUP BY tag ORDER BY tag'
    );
    $sql->execute();

    my ( $tag, $count );
    $sql->bind_columns( undef, \$tag, \$count );

    #
    # Process the results.
    #
    while ( $sql->fetch() )
    {
        my $size = $count * 5 + 5;
        if ( $size > 40 ) {$size = 40;}

        push( @$tags,
              {  tag   => $tag,
                 count => $count,
                 tsize => $size
              } );

    }
    $sql->finish();

    return ($tags);
}



=head2 getAllTagsByType

  Return all the tags upon the given element, by type.

=cut

sub getAllTagsByType
{
    my ( $class, $type ) = (@_);

    my $tags;

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    # Now the tags.
    #
    my $sql = $db->prepare(
        'SELECT DISTINCT(tag),COUNT(tag) AS runningtotal FROM tags WHERE type=? GROUP BY tag ORDER BY tag'
    );
    $sql->execute($type);

    my ( $tag, $count );
    $sql->bind_columns( undef, \$tag, \$count );

    #
    # Process the results.
    #
    while ( $sql->fetch() )
    {
        my $size = $count * 5 + 5;
        if ( $size > 40 ) {$size = 40;}

        push( @$tags,
              {  tag   => $tag,
                 count => $count,
                 tsize => $size
              } );

    }
    $sql->finish();

    return ($tags);
}



=head2 getRecent

  Return a hash of all the tags added recently.

  This includes those added to articles, polls, submissions, and weblog
 entries.

=cut

sub getRecent
{
    my ( $class, $count ) = (@_);

    #
    #  No explicit count?
    #
    $count = 10 if ( !defined($count) );

    my $tags;

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    # Now the tags - don't fetch 's'ubmission tags..
    #
    my $sql = $db->prepare(
        "SELECT DISTINCT(tag) FROM tags WHERE type !='s' ORDER BY id DESC LIMIT 0,$count"
    );
    $sql->execute() or die $db->errstr();

    my ($tag);
    $sql->bind_columns( \$tag );

    #
    # Process the results.
    #
    while ( $sql->fetch() )
    {

        #
        #  Now we can add the tag to our results hash.
        #
        push( @$tags, { tag => $tag, } );

    }
    $sql->finish();

    return ($tags);
}



=head2 getTagTypes

  Return the type of tags which are in use upon the site.

=cut

sub getTagTypes
{

    # article, poll, submission, weblog.
    return (qw/ a p s w /);
}



=head2 findByTag

  Find all items which match the given tag.

=cut

sub findByTag
{
    my ( $self, $tag ) = (@_);

    #
    #  Results.
    #
    my @results;

    #
    #  Find the tag types
    #
    my @types = $self->getTagTypes();

    #
    #  Add on each type.
    #
    foreach my $type (@types)
    {
        push( @results, $self->_findByTagType( $tag, $type ) );
    }

    return (@results);
}


sub _findByTagType
{
    my ( $self, $tag, $type ) = (@_);

    # results
    my $tags;

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    # Now the tags.
    #
    my $sql = $db->prepare(
              "SELECT DISTINCT root,type,tag FROM tags WHERE tag=? AND type=?");
    $sql->execute( $tag, $type ) or die $db->errstr();

    my ( $t_root, $t_type, $t_name );
    $sql->bind_columns( undef, \$t_root, \$t_type, \$t_name );

    #
    # Process the results.
    #
    while ( $sql->fetch() )
    {

        #
        #  Get the title of the relevent tag target.
        #
        my $title = '';
        my $link  = '';

        if ( $t_type eq 'a' )
        {

            #
            # Get the title
            #
            my $art = Yawns::Article->new( id => $t_root );
            $title = $art->getTitle();


            my $articles = Yawns::Articles->new();
            my $slug     = $articles->makeSlug($title);

            #
            #  Get the link
            #
            $link = "/article/$t_root/$slug";

        }
        elsif ( $t_type eq 'p' )
        {

            #
            # Get the title
            #
            my $poll = Yawns::Poll->new( id => $t_root );
            $title = $poll->getTitle();

            #
            #  Get the link
            #
            $link = "/polls/$t_root";

        }
        elsif ( $t_type eq 's' )
        {

            #
            #  Get the title.
            #
            my $queue = Yawns::Submissions->new();
            my %sub   = $queue->getSubmission($t_root);
            $title = $sub{ 'title' };

            #
            #  Get the link
            #
            $link = "/view/submission/$t_root";
        }
        elsif ( $t_type eq 'w' )
        {

            #
            # Get the title & link.
            #
            my $weblog = Yawns::Weblog->new( gid => $t_root );
            $title = $weblog->getTitle();
            $link  = $weblog->getLink();
        }
        else
        {
            die "There was an unknown tag type.";
        }


        #
        #  Now we can add the tag to our results hash.
        #
        push( @$tags,
              {  link  => $link,
                 title => $title,
              } );

    }
    $sql->finish();

    return ($tags);
}



=head2 getRelatedTags

  Get tags related to the specified one.

=cut

sub getRelatedTags
{
    my ( $class, $tag ) = (@_);
    die "No tag" if ( !defined($tag) );

    my $tags;

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    #  Run query.
    #
    my $sql = $db->prepare(
        "SELECT DISTINCT(a.tag) FROM tags AS a JOIN tags b ON b.root=a.root AND a.type=b.type WHERE b.tag=? AND a.tag != b.tag ORDER BY a.tag"
    );

    $sql->execute($tag);

    #
    # Bind the columns.
    #
    my ($t);
    $sql->bind_columns( undef, \$t );

    while ( $sql->fetch() )
    {
        push( @$tags, { tag => $t, } );
    }
    $sql->finish();

    #
    #
    #
    return ($tags);
}



=head2 invalidateCache

  Invalidate the cache of recent weblogs.

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
