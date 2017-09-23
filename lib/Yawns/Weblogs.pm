# -*- cperl -*- #

=head1 NAME

Yawns::Weblogs - A module for working with a collection of weblogs.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Weblogs;
    use strict;

    my $blogs  = Yawns::Weblogs->new();

    my $recent = $blogs->getRecent();

=for example end


=head1 DESCRIPTION

This module contains code for working with multiple weblogs.

=cut


package Yawns::Weblogs;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

use DBI qw/ :sql_types /;    # Database interface
use HTML::Entities;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.28 $' =~ m/Revision:\s*(\S+)/;


#
#  Standard modules which we require.
#
use strict;
use warnings;


#
#  Yawns modules which we use.
#
use Singleton::DBI;
use JSON;


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


=head2 getRecent

  Return the most recent weblogs.

=cut

sub getRecent
{
    my ($class) = (@_);

    my $number = 10;
    my $bignum = $number * $number;

    #
    # This function is a bit of a hack, because it is designed to
    # retrieve all recent weblog posters who have made "recent"
    # entries - but each name should only be included once.
    #
    #  Ordinarily we'd use the SQL "DISTINCT" term to ensure
    # that each given name appears only once, eg:
    #
    #  SELECT DISTINCT(username) FROM weblogs ORDER BY ondate LIMIT 10;
    #
    #  However we *cannot* do that here, because we also wish to
    # retrieve the count of comments upon the entries.
    #
    #  So we instead we retrieve more than we require and use
    # a hash to keep track of multiple entries.
    # The alternative approach would be to select distinct
    # usernames - then find the comment counts separately
    # but this would result in
    #
    #  1 + N x $number selects
    #
    #  (one to retrive the names, then $number of separate
    # queries to retrive the comment counts).
    #
    # Steve
    #
    my $db = Singleton::DBI->instance();

    my $sql = $db->prepare(
        "SELECT username,id,title,comments FROM weblogs WHERE bodytext != '' AND title != '' AND score > 0 ORDER BY ondate DESC LIMIT ?"
    );
    $sql->bind_param( 1, $bignum, SQL_INTEGER );
    $sql->execute($bignum);

    #
    # Bind the columns for our results.
    #
    my ( $username, $id, $title, $comments );
    $sql->bind_columns( undef, \$username, \$id, \$title, \$comments );

    #
    # Entries and count of ones we found.
    #
    my $entries = [];
    my $i       = 1;

    #
    # Hash to detect duplicate/previously-encountered usernames.
    #
    my %found;

    #
    # Process the results.
    #
    while ( $sql->fetch() )
    {

        #
        #  Encode the title, as it might have quotations in it which will
        # screw up our <a .. title="$title" ..> link.
        #
        $title =~ s!<!&lt;!g;
        $title =~ s!>!&gt;!g;

        #$title =~ s!"!&quot;!g;
        #$title =~ s!&!&amp;!g;

        unless ( $found{ $username } or $i > $number )
        {

            #
            #  `comments` is -1 to disable comments upon the given
            # entry.  So we'll set that to 0.
            #
            if ( $comments < 0 )
            {
                $comments = 0;
            }

            #
            # Store weblog poster's name, and comment count.
            #
            push( @$entries,
                  {  poster   => $username,
                     comments => $comments,
                     id       => $id,
                     title    => $title,
                     plural   => ( !( $comments == 1 ) ),
                  } );

            #
            # Found another, and mark the username as being seen.
            #
            $i++;
            $found{ $username }++;
        }
    }

    #
    #
    # Return the entries.
    #
    return ($entries);
}



=head2 getTipEntries

  Here we want to find the most recent N tip entries.

=cut

sub getTipEntries
{
    my ($class) = (@_);

    #
    #  Run the query.
    #
    my $dbi = Singleton::DBI->instance();
    my $sql = $dbi->prepare(
        "SELECT DISTINCT(a.username),a.id,a.title,a.comments FROM weblogs AS a join tags AS b WHERE b.type='w' AND b.tag='tip' AND b.root=a.gid ORDER BY b.id DESC LIMIT 0,10"
    );
    $sql->execute() or die "Failed to fetch tips" . $dbi->errstr();

    #
    # Bind the columns for our results.
    #
    my ( $username, $id, $title, $comments );
    $sql->bind_columns( undef, \$username, \$id, \$title, \$comments );


    my $entries;

    #
    # Process the results.
    #
    while ( $sql->fetch() )
    {

        #
        #  Encode the title, as it might have quotations in it which will
        # screw up our <a .. title="$title" ..> link.
        #
        $title =~ s!<!&lt;!g;
        $title =~ s!>!&gt;!g;

        #
        #  `comments` is -1 to disable comments upon the given
        # entry.  So we'll set that to 0.
        #
        if ( $comments < 0 )
        {
            $comments = 0;
        }

        #
        # Store weblog poster's name, and comment count.
        #
        push( @$entries,
              {  poster   => $username,
                 comments => $comments,
                 id       => $id,
                 title    => $title,
                 plural   => ( !( $comments == 1 ) ),
              } );

    }
    $sql->finish();

    return ($entries);
}



=head2 getReportedWeblogs

  Return all the weblog entries which have been recently reported.

=cut

sub getReportedWeblogs
{
    my ($self) = (@_);

    #
    #  Failed to find them.  Load from the database.
    #
    my $db = Singleton::DBI->instance();

    my $sql = $db->prepare(
        "SELECT username,ondate,title,bodytext,id,score FROM weblogs WHERE score != 5 AND score != -1 ORDER by gid DESC limit 10"
    );
    $sql->execute();

    my ( $username, $ondate, $title, $bodytext, $id, $score );
    $sql->bind_columns( undef, \$username, \$ondate, \$title, \$bodytext, \$id,
                        \$score );

    #
    # Get the results
    #
    my $entries = [];
    while ( $sql->fetch() )
    {

        # convert date and time to more readable format
        my @posted = Yawns::Date::convert_date_to_site($ondate);


        #
        #  Add a comma after the month name.
        #
        if ( $posted[0] =~ /^([a-zA-Z]+)([ ]+)(.*)/ )
        {
            $posted[0] = $1 . ", " . $3;
        }

        # Make sure body is well-formed.
        $bodytext = HTML::Balance::balance($bodytext);


        # Make the feed show the score too.
        $bodytext .= "<p>Score: $score</p>";

        #
        #  Encode body and title of the weblog entries
        # with HTML::Entities - this will ensure our
        # final outputted data is well-formed XML.
        #
        $title    = encode_entities($title);
        $bodytext = encode_entities($bodytext);


        #
        #  Store.
        #
        push( @$entries,
              {  user     => $username,
                 ondate   => $posted[0],
                 attime   => $posted[1],
                 title    => $title,
                 bodytext => $bodytext,
                 item_id  => $id,
              } );
    }

    #
    # Tidy up
    #
    $sql->finish();
    return ($entries);
}



=head2 deleteByUser

  Delete all weblogs belonging to the given user.

=cut

sub deleteByUser
{
    my ( $class, %parameters ) = (@_);

    my $username = $parameters{ 'username' } || $class->{ 'username' };

    die "No username " if ( !defined($username) );

    #
    #  Get the database handle.
    #
    my $db    = Singleton::DBI->instance();
    my $query = $db->prepare("DELETE FROM weblogs WHERE username=?");
    $query->execute($username);
    $query->finish();

}



=head2 hideByUser

  Update all weblogs belonging to a particular user.

=cut

sub hideByUser
{
    my ( $class, %parameters ) = (@_);

    my $username = $parameters{ 'username' } || $class->{ 'username' };

    die "No username " if ( !defined($username) );

    #
    #  Get the database handle.
    #
    my $db    = Singleton::DBI->instance();
    my $query = $db->prepare("UPDATE weblogs SET score=-1 WHERE username=?");
    $query->execute($username);
    $query->finish();
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
