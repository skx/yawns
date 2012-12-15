# -*- cperl -*- #

=head1 NAME

Yawns::Formatters - A helper module for formatting user Text comments.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Formatters;
    use strict;

    # Get the list of available formatters.
    my $factory   = Yawns::Formatters->new;
    my %installed = $factory->getAvailable();

    # Create a new BBCode formatter.
    my $bbcode = $factory->create( "bbcode", "text to be formated" );

=for example end


=head1 DESCRIPTION

This module allows the site to dynamically determine which formatting
modules are available, and to create instances of each one.

It is a simple factory pattern, albeit a hard-wired one rather than
a dynamic one.

=cut


package Yawns::Formatters;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.3 $' =~ m/Revision:\s*(\S+)/;


#
#  The actual formatters we create, and return.
#
use Yawns::Formatters::HTML;
use Yawns::Formatters::Text;
use Yawns::Formatters::Textile;
use Yawns::Formatters::Markdown;



=head2 new

  Constructor, not really used for much.

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



=head2 getAvailable

  Return the formatting types which are available.

=cut

sub getAvailable
{
    my ($class) = (@_);

    my %results;

    #
    #  The formatters are the keys, and the values
    # are the human-readable names.
    #
    $results{ 'html' }     = "HTML";
    $results{ 'text' }     = "Plain Text";
    $results{ 'textile' }  = "Textile";
    $results{ 'markdown' } = "Markdown";

    return (%results);
}



=head2 create

  Create an instance of the correct type - this is the factory part
 of the code.

=cut

sub create
{
    my ( $self, $type, $text ) = (@_);

    if ( $type =~ /^html$/i )
    {
        return ( new Yawns::Formatters::HTML->new( text => $text ) );
    }
    elsif ( $type =~ /^text$/i )
    {
        return ( new Yawns::Formatters::Text->new( text => $text ) );
    }
    elsif ( $type =~ /^markdown$/i )
    {
        return ( new Yawns::Formatters::Markdown->new( text => $text ) );
    }
    elsif ( $type =~ /^textile$/i )
    {
        return ( new Yawns::Formatters::Textile->new( text => $text ) );
    }

    die "Invalid formatter.";
}



1;



=head1 AUTHOR

Steve Kemp

http://www.steve.org.uk/



=head1 LICENSE

Copyright (c) 2007-2012 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut
