# -*- cperl -*- #

=head1 NAME

Yawns::Articles - A module for working with several articles.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Articles;
    use strict;

    my $article = Yawns::Articles->new();

    my $aresults = $article->searchFor( $terms);

    my $tresults = $article->searchTitlesFor( $terms);


=for example end


=head1 DESCRIPTION

This module contains code for dealing with a collection of articles.

=cut


package Yawns::Articles;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);


require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.42 $' =~ m/Revision:\s*(\S+)/;



#
#  Standard modules which we require.
#
use strict;
use warnings;
use DBI qw/ :sql_types /;    # Database interface
use HTML::Entities;
use Date::Format;
use Date::Parse;

#
#  Yawns modules which we use.
#
use Yawns::Date;
use Singleton::DBI;




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



=head2 count()

  Count the total number of articles available.

=cut

sub count
{
    my ($class) = (@_);

    my $count = 0;

    #
    #  Get the database handle
    #
    my $db = Singleton::DBI->instance();

    #
    # Count articles.
    #
    my $query = "SELECT COUNT(id) FROM articles";
    my $sql   = $db->prepare($query);
    $sql->execute();
    my @ret = $sql->fetchrow_array();
    $count = $ret[0];
    $sql->finish();

    return ($count);
}


=head2 searchByAuthor

  Return the results of an author search against the articles database.

=cut

sub searchByAuthor
{
    my ( $class, $search_terms ) = (@_);

    #
    #  Get the database handle.
    #
    my $db = Singleton::DBI->instance();
    my $querystr =
      "SELECT id,title,author,ondate,leadtext,0  FROM articles WHERE author = ? ";

    # Fetch the required data.
    my $sql = $db->prepare($querystr);
    $sql->execute($search_terms) or die $db->errstr();

    # Bind columns for fetching.
    my ( $id, $title, $author, $ondate, $teaser, $score );
    $sql->bind_columns( undef,    \$id,     \$title, \$author,
                        \$ondate, \$teaser, \$score );

    # The results we return
    my $resultsloop = [];

    while ( $sql->fetch() )
    {
        my ($str_date) = Yawns::Date::convert_date_to_site($ondate);

        my $a        = Yawns::Tags->new();
        my $tags     = $a->getTags( article => $id );
        my $has_tags = defined $tags;

        my $slug = $class->makeSlug($title);

        if ($has_tags)
        {
            push(
                @$resultsloop,
                { id       => $id,
                   title    => $title,
                   slug     => $slug,
                   author   => $author,
                   ondate   => $str_date,
                   teaser   => $teaser,
                   score    => $score,
                   has_tags => $has_tags,
                   tags     => $tags,
                } );
        }
        else
        {
            push(
                @$resultsloop,
                {                #  id     => $id,
                   title  => $title,
                   slug   => $slug,
                   author => $author,
                   ondate => $str_date,
                   teaser => $teaser,
                   score  => $score
                } );
        }
    }

    $sql->finish();

    return ($resultsloop);

}


=head2 getTeasers

 Get the first paragraph of the specified articles from the database

 NOTE:
   This is only used when generating the RDF feeds for the articles.
  this is why the body of the text is escaped with HTML::Entities.

=cut

sub getTeasers
{
    my ( $class, $first_teaser, $counter ) = @_;

    #
    #  Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    # get required data
    my $sql = $db->prepare(
        'SELECT id,title,leadtext,ondate,author FROM articles WHERE id <= ? ORDER BY id DESC LIMIT ?'
    );
    $sql->bind_param( 2, $counter, SQL_INTEGER );
    $sql->execute( $first_teaser, $counter );
    my $resref = $sql->fetchall_arrayref();
    $sql->finish();

    my @results = @$resref;

    my $teasers = [];
    my $result;
    foreach $result (@results)
    {
        my @teaser = @$result;

        #
        # Get data.
        #
        my $title    = $teaser[1];
        my $leadtext = $teaser[2];

        my $slug = $class->makeSlug($title);

        $leadtext =~ s!</?p>!!gi;
        $leadtext =~ s!<a href="(.*?)" rel="nofollow">(.*?)</a>!$2 ($1)!gi;
        $leadtext =~ s/\r//g;
        $leadtext =~ s/\n//g;

        #
        # Make sure we validate and are well-formed.
        #
        $leadtext = encode_entities($leadtext);
        $title    = encode_entities($title);


        #
        # Format per RFC 3339 for Atom format
        #
        my $ondate = $teaser[3];
        $ondate = _format_date_rfc_3339($ondate);

        #
        #  Time for the RSS feed.
        #
        my $time = str2time($ondate);
        my $pubdate = time2str( "%a, %e %b %Y %H:%M:%S GMT", $time );

        push( @$teasers,
              {  id       => $teaser[0],
                 title    => $title,
                 leadtext => $leadtext,
                 slug     => $slug,
                 ondate   => $ondate,
                 pubdate  => $pubdate,
                 author   => $teaser[4],
                 home_url => conf::SiteConfig::get_conf('home_url'),
              } );
    }

    # return the requested values
    return ($teasers);
}



=head2 getHeadlines

  Get the given headlines from the database

=cut

sub getHeadlines
{
    my ( $class, $first_headline, $counter, $dates ) = (@_);

    #
    #  Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    # get required data
    my $sql = $db->prepare(
        'SELECT id,title,ondate FROM articles WHERE id <= ? ORDER BY id DESC LIMIT ?'
    );
    $sql->bind_param( 2, $counter, SQL_INTEGER );
    $sql->execute( $first_headline, $counter );
    my $resref = $sql->fetchall_arrayref();
    $sql->finish();


    my @results   = @$resref;
    my $headlines = [];

    foreach my $result (@results)
    {
        my @headline = @$result;

        my $time = str2time( $headline[2] );
        my $pubDate = time2str( "%a, %e %b %Y %H:%M:%S GMT", $time );

        my $title = $headline[1];
        my $slug  = $class->makeSlug($title);

        if ($dates)
        {
            push(
                @$headlines,
                {  id      => $headline[0],
                   title   => $title,
                   slug    => $slug,
                   pubdate => $pubDate,
                } );
        }
        else
        {
            push(
                @$headlines,
                {  id    => $headline[0],
                   title => $title,
                   slug  => $slug,
                } );
        }
    }

    # return the requested values
    return ($headlines);
}



=head2 getPreviousHeadlines

 Get the previous site headlines from the site.

=cut

sub getPreviousHeadlines
{
    my ($class) = (@_);

    #
    # The number of articles to show in previous headlines box
    #
    #
    my $count = 10;

    #
    # Find out the last item on the front page, if it is more than 10
    # then reduce the number we show.
    #
    my $items = $class->count();
    $count = $items if ( $count > $items );

    #
    # start from the first headline that's not being shown
    #
    $items -= ($count);

    #
    # get the required amount of headlines
    #
    my $previous_headlines = $class->getHeadlines( $items, $count, 0 );

    return ($previous_headlines);
}



=head2 getArticles

  Return all the relevant articles for display upon the front page.

=cut

sub getArticles
{
    my ( $class, $start, $count ) = (@_);

    my $sql;

    my $db = Singleton::DBI->instance();


    my $query =
      "SELECT * FROM articles WHERE id <= ? ORDER BY id DESC LIMIT $count";
    $sql = $db->prepare($query);
    $sql->execute($start);

    my $articleref  = $sql->fetchall_arrayref();
    my @articlelist = @$articleref;
    $sql->finish();

    my $articles = ();
    my $article;
    my $last_id;


    foreach $article (@articlelist)
    {
        my @article = @$article;
        my ( $postdate, $posttime ) =
          Yawns::Date::convert_date_to_site( $article[3] );

        my $comments = $article[7];
        my $comment  = 0;
        if ( $comments == 1 ) {$comment = 1;}

        #
        # Get the tags associated with this article.
        #
        my $a        = Yawns::Tags->new();
        my $tags     = $a->getTags( article => $article[0] );
        my $has_tags = defined $tags;

        my $title = $article[1];
        my $slug  = $class->makeSlug($title);

        if ($has_tags)
        {
            push(
                @$articles,
                {  id       => $article[0],
                   title    => $title,
                   slug     => $slug,
                   byuser   => $article[2],
                   ondate   => $postdate,
                   attime   => $posttime,
                   comment  => $comment,
                   comments => $comments,
                   words    => $article[6],
                   body     => $article[4],
                   tags     => $tags,
                   has_tags => $has_tags
                } );
        }
        else
        {
            push(
                @$articles,
                {             #article       => $article[0],
                   title    => $title,
                   slug     => $slug,
                   byuser   => $article[2],
                   ondate   => $postdate,
                   attime   => $posttime,
                   comment  => $comment,
                   comments => $comments,
                   words    => $article[6],
                   body     => $article[4] } );
        }
        $last_id = $article[0];
    }

    # return the requested values
    return ( $articles, $last_id );
}



=head2 getArticleYears

  Return the years which have had at least one article posted in them

  This is an internal method used to expire the article archive cache.

=cut

sub getArticleYears
{

    #
    #  Get the database handle.
    #
    my $db       = Singleton::DBI->instance();
    my $querystr = "SELECT DISTINCT YEAR(ondate) FROM articles";

    # Fetch the required data.
    my $sql = $db->prepare($querystr);
    $sql->execute() or die $db->errstr();

    # Bind columns for fetching.
    my ($year);
    $sql->bind_columns( undef, \$year );

    # The results we return
    my %years;

    while ( $sql->fetch() )
    {
        $years{ $year } += 1;
    }

    $sql->finish();

    return (%years);
}



=head2 getArchivedArticles

  Return the list of articles for the given period of time.

=cut

sub getArchivedArticles
{
    my ( $class, $year ) = (@_);

    my $db = Singleton::DBI->instance();

    my $sql;


    # get required data
    my $query =
      "SELECT month(ondate),monthname(ondate),year(ondate),id,title,leadtext FROM articles WHERE year(ondate)=?  ORDER BY id DESC";
    $sql = $db->prepare($query);
    $sql->execute($year) or die "Error : " . $db->errstr();

    my $articleref  = $sql->fetchall_arrayref();
    my @articlelist = @$articleref;
    $sql->finish();

    my $articles = ();
    my $article;


    foreach $article (@articlelist)
    {
        my @article = @$article;

        my $month  = $article[0];
        my $name   = $article[1];
        my $year   = $article[2];
        my $id     = $article[3];
        my $title  = $article[4];
        my $teaser = $article[5];

        my $slug = $class->makeSlug($title);

        push(
            @$articles,
            {
             id         => $id,
             title      => $title,
             slug       => $slug,
             teaser     => $teaser,
             # year       => $year,
            } );

    }

    # return the requested values
    return ($articles);
}



=head2 _format_date_rfc_3339

  Format a date and time from the database in RFC 3339 form.

 Note: This is only ever used in the Atom output in 'RSS.pl'


=cut

sub _format_date_rfc_3339
{
    my $both = shift;

    if ( $both =~ /(.*) (.*)/ )
    {
        $both = $1 . "T" . $2 . "Z";
    }

    return ($both);
}


=begin doc

  Find the ID of the article with the given Slug.

=end doc

=cut

sub findBySlug
{
    my ( $self, %params ) = (@_);

    my $slug = $params{ 'slug' } || $self->{ 'slug' } || undef;
    die "No slug given" unless defined($slug);

    my $id = undef;

    #
    #  Get the database handle
    #
    my $db = Singleton::DBI->instance();

    #
    # Fetch articles.
    #
    my $query = "SELECT id FROM articles WHERE ( ";

    my @terms = split( /_/, $slug );

    my $c = 0;
    foreach my $t (@terms)
    {
        my $st = $db->quote( '%' . $t . '%' );
        $query .= " title LIKE $st ";
        $query .= " AND ";
    }

    $query =~ s/ AND $//g;
    $query .= ")";

    my $sql = $db->prepare($query) or die "Failed to prepare";
    $sql->execute() or die "Failed to execute";
    my @ret = $sql->fetchrow_array();
    $id = $ret[0];
    $sql->finish();

    return ($id);
}



=begin doc

  Make a slug from the given human-readable title.

=end doc

=cut

sub makeSlug
{
    my ( $self, $title ) = (@_);

    die "No title" if ( !defined($title) );

    $title =~ s/[^- a-z0-9_'.\/]//gi;
    $title =~ s/ /_/g;

    return ($title);
}



=head2 invalidateCache

  Clean any cached content we might have.

=cut

sub invalidateCache
{
    my ($class) = (@_);

}




1;
