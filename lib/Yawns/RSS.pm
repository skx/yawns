# -*- cperl -*- #

=head1 NAME

Yawns::RSS - A module for outputing the RSS feeds we serve

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::RSS;
    use strict;

    my $feeds = Yawns::RSS->new();
    $feeds->output();

    #
    # Setup different output files.
    #
    my $feeds = Yawns::RSS->new( headlines => "headlines.rdf",
                                 articles  => "/tmp/articles.rdf",
                                 atom      => "/blah/atom.xml" );
    $feeds->output();

=for example end


=head1 DESCRIPTION

This module contains code for outputting the various RSS feeds we
serve.

=cut


package Yawns::RSS;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.13 $' =~ m/Revision:\s*(\S+)/;



#
#  Standard modules which we require.
#
use strict;
use warnings;
use HTML::Entities;
use HTML::Template;


#
#  Yawns modules which we use.
#
use Yawns::Articles;



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



=head2 output

  Create the various output feeds we write:

      ./articles.rdf
      ./headlines.rdf
      ./atom.xml

=cut

sub output
{
    my ($class) = (@_);

    #
    #  Find the number of articles.
    #
    my $entries = Yawns::Articles->new();
    my $max     = $entries->count() + 1;
    my $latest  = $max;

    #
    # Get the number of items to include in the feed.
    #
    my $num = conf::SiteConfig::get_conf('rdf_headlines');

    $num = $max if $max < $num;


    #
    #  Get my current home directory.  We assume this code
    # is deployed beneath ~/current/
    #
    #
    my $login = getlogin || getpwuid($<);
    my ( undef, undef, undef, undef, undef, undef, undef, $home, undef, undef )
      = getpwnam($login);

    #
    #  Get the filenames we output, falling back to the defaults
    # if none are specified in the constructor.
    #
    my $articles = $class->{ 'articles' } ||
      $home . "/current/htdocs/articles.rdf";
    my $headlines = $class->{ 'headlines' } ||
      $home . "/current/htdocs/headlines.rdf";
    my $atom = $class->{ 'atom' } || $home . "/current/htdocs/atom.xml";


    #
    #
    #  First the minimal feed, with just the headlines, and links.
    #
    _generate_headlines_rdf( $headlines, $latest, $num );


    #
    #  Now the full links
    #
    _generate_articles_rdf( $articles, $latest, $num );

    #
    #  Again in "Atom" format.
    #
    _generate_articles_atom( $atom, $latest, $num );


}



=head2 _generate_headlines_rdf

  Generate the headlines RDF feed into the file ./headlines.rdf

  This is an internal function

=cut

sub _generate_headlines_rdf
{
    my ( $file, $latest, $num ) = (@_);

    #
    #  Get the various constants.
    #
    my $sitename    = conf::SiteConfig::get_conf('sitename');
    my $home_url    = conf::SiteConfig::get_conf('home_url');
    my $site_desc   = conf::SiteConfig::get_conf('site_desc');
    my $site_slogan = conf::SiteConfig::get_conf('site_slogan');


    #
    #  Get the relevant headlines from the database.
    #
    my $articles  = Yawns::Articles->new();
    my $headlines = $articles->getHeadlines( $latest, $num, 1 );
    my @headlines = @$headlines;


    #
    #  Massage it into a form for use in a HTML::Template loop
    #
    my $headline_data = [];


    foreach my $h (@headlines)
    {

        #
        # Make sure our title is well-formed.
        #
        my $title = $h->{ 'title' };
        my $slug  = $articles->makeSlug($title);

        $title = encode_entities($title);

        push( @$headline_data,
              {  slug     => $slug,
                 id       => $h->{ 'id' },
                 title    => $title,
                 pubdate  => $h->{ 'pubdate' },
                 home_url => $home_url,
              } );
    }


    my $tmp = "templates/xml/headlines.template";
    if ( !-e $tmp )
    {
        $tmp = "../$tmp";
    }

    #
    #  Load the template
    #
    my $template = HTML::Template->new( filename          => $tmp,
                                        die_on_bad_params => 0 );


    $template->param( headlines   => $headline_data,
                      sitename    => $sitename,
                      site_slogan => $site_slogan,
                      home_url    => $home_url,
                      site_desc   => $site_desc,
                    );

    open( RSS, ">", $file ) or
      die "Failed to open output file for Headline RDF ($file) File - $!";
    print RSS $template->output;
    close(RSS);

}



=head2 _generate_articles_rdf

  Generate the articles RDF feed into the file ./articles.rdf

  This is an internal function

=cut

sub _generate_articles_rdf
{
    my ( $file, $latest, $num ) = (@_);

    #
    #  Get the various constants.
    #
    my $sitename    = conf::SiteConfig::get_conf('sitename');
    my $home_url    = conf::SiteConfig::get_conf('home_url');
    my $site_desc   = conf::SiteConfig::get_conf('site_desc');
    my $site_slogan = conf::SiteConfig::get_conf('site_slogan');


    #
    #  Get the relevant headlines from the database.
    #
    my $articles = Yawns::Articles->new();
    my $teasers  = $articles->getTeasers( $latest, $num );
    my @teasers  = @$teasers;


    my $tmp = "templates/xml/articles.template";
    if ( !-e $tmp )
    {
        $tmp = "../$tmp";
    }

    #
    #  Load the template
    #
    my $template = HTML::Template->new( filename          => $tmp,
                                        die_on_bad_params => 0 );


    $template->param( teasers     => $teasers,
                      sitename    => $sitename,
                      site_slogan => $site_slogan,
                      home_url    => $home_url,
                      site_desc   => $site_desc,
                    );

    open( RSS, ">", $file ) or
      die "Failed to open output file for Articles RDF ($file) File - $!";
    print RSS $template->output;
    close(RSS);

}



=head2 _generate_articles_atom

  Generate the articles XML feed into the file ./atom.xml

  This is an internal function

=cut

sub _generate_articles_atom
{
    my ( $file, $latest, $num ) = (@_);

    #
    #  Get the various constants.
    #
    my $sitename    = conf::SiteConfig::get_conf('sitename');
    my $home_url    = conf::SiteConfig::get_conf('home_url');
    my $site_desc   = conf::SiteConfig::get_conf('site_desc');
    my $site_slogan = conf::SiteConfig::get_conf('site_slogan');


    #
    #  Get the relevant headlines from the database.
    #
    my $articles = Yawns::Articles->new();
    my $teasers  = $articles->getTeasers( $latest, $num );
    my @teasers  = @$teasers;

    #
    # Format the date
    #
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst );
    ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      localtime(time);

    #
    # Make numbers "real".
    #
    $year += 1900;
    $mon  += 1;

    #
    #  Ensure all two digit numbers actually are two digits.
    #
    $hour = "0" . $hour unless ( length($hour) > 1 );
    $min  = "0" . $min  unless ( length($min) > 1 );
    $sec  = "0" . $sec  unless ( length($sec) > 1 );
    $mday = "0" . $mday unless ( length($mday) > 1 );
    $mon  = "0" . $mon  unless ( length($mon) > 1 );

    #
    # Date + Time in RFC 3339 format
    #
    my $now = "$year-$mon-$mday" . "T" . "$hour:$min:$sec" . "Z";

    my $tmp = "templates/xml/atom.template";
    if ( !-e $tmp )
    {
        $tmp = "../$tmp";
    }

    #
    #  Load the template
    #
    my $template = HTML::Template->new( filename          => $tmp,
                                        die_on_bad_params => 0 );


    $template->param( teasers     => $teasers,
                      sitename    => $sitename,
                      site_slogan => $site_slogan,
                      home_url    => $home_url,
                      site_desc   => $site_desc,
                      now         => $now,
                    );

    open( RSS, ">", $file ) or
      die "Failed to open output file for Articles Atom ($file) File - $!";
    print RSS $template->output;
    close(RSS);

}



1;
