# -*- cperl -*- #

=head1 NAME

Yawns::Stats - A module for retrieving site statistics.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Stats;
    use strict;

    #
    #  Get handle
    #
    my $stats = Yawns::Stats->new();


    #
    #  Hall of fame.
    my $hof   = $stats->getStats();


=for example end


=head1 DESCRIPTION

This module returns interesting information for display upon the
"hall of fame" page.


=cut


package Yawns::Stats;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.8 $' =~ m/Revision:\s*(\S+)/;


#
#  Standard modules which we require.
#
use strict;
use warnings;


#
#  Yawns modules which we use.
#
use Singleton::DBI;



=head2 new

  Create a new instance of this object.

=cut

sub new
{
    my ( $self, %supplied ) = (@_);

    my $class = ref($self) || $self;

    return bless {}, $class;
}



=head2 getStats

  Find the "hall of fame" information.

=cut

sub getStats
{
    my ($class) = (@_);

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
    my @ret           = $sql->fetchrow_array();
    my $article_count = $ret[0];
    $sql->finish();


    #
    # Count comments.
    #
    $query = "SELECT COUNT(id) FROM comments";
    $sql   = $db->prepare($query);
    $sql->execute();
    @ret = $sql->fetchrow_array();
    my $comment_count = $ret[0];
    $sql->finish();

    #
    # Count users
    #
    $query = "SELECT COUNT(username) FROM users";
    $sql   = $db->prepare($query);
    $sql->execute();
    @ret = $sql->fetchrow_array();
    my $user_count = $ret[0];
    $sql->finish();

    #
    # Count weblog entries.
    #
    $query = "SELECT COUNT(id) FROM weblogs";
    $sql   = $db->prepare($query);
    $sql->execute();
    @ret = $sql->fetchrow_array();
    my $weblog_count = $ret[0];
    $sql->finish();

    #
    # Most active articles.
    #
    my $sql1 = $db->prepare(
        'SELECT id,title,author,ondate,comments FROM articles ORDER BY comments DESC LIMIT 10'
    );
    $sql1->execute();
    my $active_articles = $sql1->fetchall_arrayref();
    $sql1->finish();

    #
    # Longest articles.
    #
    my $sql3 = $db->prepare(
        'SELECT id,title,author,ondate,words FROM articles ORDER BY words DESC LIMIT 10'
    );
    $sql3->execute();
    my $longest_articles = $sql3->fetchall_arrayref();
    $sql3->finish();

    #
    # Most read articles.
    #
    my $sql4 = $db->prepare(
        'SELECT id,title,author,ondate,readcount FROM articles ORDER BY readcount DESC LIMIT 10'
    );
    $sql4->execute();
    my $popular_articles = $sql4->fetchall_arrayref();
    $sql4->finish();


    # format the data to be returned
    my %stats_info = ( article_count    => $article_count,
                       comment_count    => $comment_count,
                       user_count       => $user_count,
                       active_articles  => $active_articles,
                       longest_articles => $longest_articles,
                       popular_articles => $popular_articles,
                       weblog_count     => $weblog_count,
                     );

    return ( \%stats_info );
}




=head2 invalidateCache

  Invalidate the cached information we contain.

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
