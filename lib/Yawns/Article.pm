# -*- cperl -*- #

=head1 NAME

Yawns::Article - A module for working with a single article.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Article;
    use strict;

    my $article = Yawns::Article->new( id => 33 );

    ...

=for example end


=head1 DESCRIPTION

This module contains code for dealing with a single article.

=cut


package Yawns::Article;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.54 $' =~ m/Revision:\s*(\S+)/;


#
#  Standard modules which we require.
#
use strict;
use warnings;

use JSON;

#
#  Yawns modules which we use.
#
use Singleton::DBI;

use Yawns::Articles;
use Yawns::Comments;
use Yawns::Stats;
use Yawns::Tags;



=head2 new

  Create a new instance of this object.

=cut

sub new
{
    my ( $type, %supplied ) = (@_);

    my $self = { id => $supplied{ 'id' } };

    return bless $self, $type;
}



=head2 get

  Return the actual article.

  This returns a hash containing all the relevant details of an
 article, along with the titles and IDs of the next and previous
 articles.

=cut

sub get
{
    my ($class) = (@_);

    #
    # Get the user supplied article ID.
    #
    my $id = $class->{ id };

    my $r = conf::SiteConfig::get_conf('redis');
    my $redis;

    if ($r)
    {
        $redis = Singleton::Redis->instance();
        my $d = $redis->get("article.$id");
        if ($d)
        {
            my $o = decode_json($d);
            return ($o);
        }
    }

    my $article;

    #
    # find the number of articles.
    #
    my $all   = Yawns::Articles->new();
    my $total = $all->count();
    $total += 1;


    #
    # fetch the article data
    #
    my $db = Singleton::DBI->instance();
    my $sql = $db->prepare(
        "SELECT a.*,b.suspended FROM articles AS a JOIN users AS b WHERE a.id = ? AND a.author=b.username"
    );

    $sql->execute($id);
    my @thisarticle = $sql->fetchrow_array();
    $sql->finish();

    #
    # Previous and next titles for the navigation..
    #
    my $nextTitle = undef;
    my $prevTitle = undef;


    #
    # Get next and previous titles - only fetch them if this is
    # required.
    #
    if ( $id > 0 )
    {
        my $prevArticle = Yawns::Article->new( id => ( $id - 1 ) );
        $prevTitle = $prevArticle->getTitle();
    }
    if ( ( $id + 1 ) <= $total )
    {
        my $nextArticle = Yawns::Article->new( id => ( $id + 1 ) );
        $nextTitle = $nextArticle->getTitle();
    }

    #
    # Show the next and previous items?
    #
    my $next_show = 1 if defined($nextTitle);
    my $prev_show = 1 if defined($prevTitle);


    # convert date and time to more readable format
    my ( $postdate, $posttime ) =
      Yawns::Date::convert_date_to_site( $thisarticle[3] );

    #
    #  Create friendly slug link.
    #
    my $title = $thisarticle[1];
    my $slug  = $title;
    $slug =~ s/[- a-z0-9_]//gi if ($slug);
    $slug =~ s/ /_/g           if ($slug);

    # Store all data away
    my %the_article = ( article_title  => $title,
                        article_slug   => $slug,
                        article_byuser => $thisarticle[2],
                        article_ondate => $postdate,
                        article_attime => $posttime,
                        article_body   => $thisarticle[5],
                        comments       => $thisarticle[7],
                        prevarticle    => $prevTitle,
                        prev           => $id - 1,
                        prev_show      => $prev_show,
                        nextarticle    => $nextTitle,
                        next           => $id + 1,
                        next_show      => $next_show,
                        suspended      => $thisarticle[10],
                      );

    if ($redis)
    {
        $redis->set( "article.$id",
                 JSON->new->utf8->allow_nonref->encode( \%the_article ) );
    }

    return ( \%the_article );
}



=head2 edit

  Edit an article:

        my $article = Yawns::Article->new( id => 30 );
        $article->edit( title => "New title",
                        author => "Author",
                        body   => "Body text here" );

=cut

sub edit
{
    my ( $class, %parameters ) = (@_);

    my $id     = $class->{ id };
    my $title  = $parameters{ 'title' };
    my $body   = $parameters{ 'body' };
    my $author = $parameters{ 'author' };

    #
    #
    # Get the database handle.
    my $db = Singleton::DBI->instance();

    # generate the lead text (for front page - first paragraph of body)
    my $leadtext = $body;
    if ( $leadtext =~ m/^(.+?)\n+.*/ ) {$leadtext = $1;}

    $leadtext = "<p>" . $leadtext  unless $leadtext =~ m/<p>/;
    $leadtext = $leadtext . "</p>" unless $leadtext =~ m/<\/p>/;

    # generate the word count
    my $words = _count_words($body);

    # update the article in the database
    my $sql2 = $db->prepare( 'UPDATE articles SET title=?, ' .
                  'author=?, leadtext=?, bodytext=?, words=? ' . 'WHERE id=?' );

    $sql2->execute( $title, $author, $leadtext, $body, $words, $id );

    # Flush the cache
    my $r = conf::SiteConfig::get_conf('redis');
    my $redis;
    if ($r)
    {
        $redis = Singleton::Redis->instance();
        $redis->del("article.$id");
        $redis->del("article.title.$id");
    }

}



=head2 create

   Create a new article:

        my $article = Yawns::Article->new( id => 30 );
        $article->create( title => "New title",
                          author => "Author",
                          body   => "Body text here" );

=cut

sub create
{
    my ( $class, %parameters ) = (@_);

    my $title  = $parameters{ 'title' };
    my $body   = $parameters{ 'body' };
    my $author = $parameters{ 'author' };
    my $id     = $parameters{ 'id' };

    #
    #  Generate the new article number if one isn't given.
    #
    if ( !defined($id) )
    {
        my $articles = Yawns::Articles->new();
        $id = $articles->count();
        $id += 1;
    }

    #
    #  Count the words.
    #
    my $words = _count_words($body);

    #
    #  Make the lead text.
    #
    my $leadtext = $body;
    if ( $leadtext =~ m/^(.+?)\n+.*/ ) {$leadtext = $1;}
    $leadtext = "<p>" . $leadtext  unless $leadtext =~ m/<p>/;
    $leadtext = $leadtext . "</p>" unless $leadtext =~ m/<\/p>/;

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();


    # Insert the new article into the database
    my $sql = $db->prepare(
        'INSERT INTO articles (id, title, author, leadtext, bodytext, words, comments, readcount ,ondate ) VALUES(?,?,?,?,?,?,?,?, NOW() );'
    );
    my $ok =
      $sql->execute( $id, $title, $author, $leadtext, $body, $words, 0, 0 ) or
      die "Cannot create new article " . $db->errstr();
    $sql->finish();

    #
    # We are now a new article ID.
    #
    $class->{ id } = $id;

    # flush the cache
    my $r = conf::SiteConfig::get_conf('redis');
    if ($r)
    {
        my $redis = Singleton::Redis->instance();
        $redis->del("article.count");
    }

    return ($id);
}



=head2 delete

  Delete the given article.

=cut

sub delete
{
    my ($class) = (@_);

    #
    # Get the user supplied article ID.
    #
    my $id = $class->{ id };

    #
    #  Get the article author, before it is deleted.
    #
    my $info   = $class->get();
    my $author = $info->{ 'article_byuser' };

    #
    #  Fetch from the database.
    #
    my $db = Singleton::DBI->instance();

    #
    #  Delete the article text.
    #
    my $query = "DELETE FROM articles WHERE id=?";
    my $sql   = $db->prepare($query);
    $sql->execute($id);
    $sql->finish();

    #
    # Delete any tags.
    #
    my $tags = Yawns::Tags->new();
    $tags->deleteTags( article => $id );

    # Flush the cache
    my $r = conf::SiteConfig::get_conf('redis');
    if ($r)
    {
        my $redis = Singleton::Redis->instance();
        $redis->del("article.$id");
        $redis->del("article.title.$id");
        $redis->del("article.count");
    }
}



=head2 getTitle

  Get the title of this article.

=cut

sub getTitle
{
    my ($class) = (@_);

    #
    # Get the article ID
    #
    my $id = $class->{ id };

    my $r = conf::SiteConfig::get_conf('redis');
    my $redis;
    if ($r)
    {
        $redis = Singleton::Redis->instance();
        my $t = $redis->get("article.title.$id");
        return ($t) if ($t);
    }

    #
    #  Attempt to fetch from the cache
    #
    my $title = "";

    #
    #  Attempt to fetch from database.
    #
    my $db    = Singleton::DBI->instance();
    my $query = "SELECT title FROM articles WHERE id=?";
    my $sql   = $db->prepare($query);
    $sql->execute($id);
    my @ret = $sql->fetchrow_array();
    $title = $ret[0];
    $sql->finish();

    if (defined $redis && ( $title ) )
    {
        $redis->set( "article.title.$id", $title );
    }
    return ($title);
}


=head2 getLeadText

  Find and return the lead text for a given article.

=cut

sub getLeadText
{
    my ($self) = (@_);

    #
    #  Get the article data
    #
    my $data = $self->get();

    #
    #  Get the text.
    #
    my $body = $data->{ 'article_body' };

    #
    #  Generate the lead text.
    #
    my $leadtext = $body;
    if ( $leadtext =~ m/^(.+?)\n+.*/ ) {$leadtext = $1;}

    $leadtext = "<p>" . $leadtext  unless $leadtext =~ m/<p>/;
    $leadtext = $leadtext . "</p>" unless $leadtext =~ m/<\/p>/;

    return ($leadtext);
}



=head2 _count_words

  Count the words in the given text

=cut

sub _count_words
{
    my ($text) = (@_);

    $text =~ s!<.*?>!!gs;
    $text =~ s!'!!gs;
    my @words = split( /\s+/, $text );
    my $words = @words;

    return ($words);
}



=head2 invalidateCache

  Clean any cached content we might have.

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
