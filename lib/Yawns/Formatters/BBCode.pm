# -*- cperl -*- #

=head1 NAME

Yawns::Formatters::BBCode - A module for formatting BBCode text into HTML

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Formatters::BBCode;
    use strict;

    # Load the original
    my $html     = Yawns::Formatters::BBCode->new( text=> 'Some text\nhere');

    # Now the accessors.
    my $preview  = $html->getPreview();
    my $original = $html->getOriginal();


=for example end

=head1 DESCRIPTION

This module contains code for formatting user submitted text in
BBCode into HTML.

This is used for comment posting, and weblog entry creation.

=cut


package Yawns::Formatters::BBCode;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.3 $' =~ m/Revision:\s*(\S+)/;


#
#  Standard modules which we require.
#
use HTML::AddNoFollow;
use HTML::BBCode;
use HTML::Entities;



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



=head2 getOriginal

  Return the original text which was entered.

=cut

sub getOriginal
{
    my ($class) = (@_);

    my $text = $class->{ 'text' };
    die "No text" unless ($text);

    # Encode.
    return HTML::Entities::encode_entities($text);
}



=head2 getPreview

  Return the content the user submitted in a format suitable
 for preview-display.

=cut

sub getPreview
{
    my ($class) = (@_);

    # get the text.
    my $text = $class->{ 'text' } || " ";
    die "No text" unless ( defined($text) && length($text) );

    #
    # We use HTML... not CSS
    #
    my %html_tags = (
        i         => '<i>%s</i>',
        url       => '<a href="%s" rel="nofollow">%s</a>',
        b         => '<b>%s</b>',
        u         => '<u>%s</u>',
        code      => '<code>%s</code>',
        pre       => '<pre>%s</pre>',
        img       => '<img src="%s" alt="" />',
        ul        => '<ul>%s</ul>',
        ul        => '<ul>%s</ul>',
        ol_number => '<ol>%s</ol>',
        ol_alpha  => '<ol>%s</ol>',

                    );

    #
    #  Create object and use it.
    #
    my $bbcode = HTML::BBCode->new( { html_tags  => \%html_tags,
                                      linebreaks => 1
                                    } );
    my $html = $bbcode->parse($text);

    #
    # Make sure it is Sanitized
    #
    return ( HTML::AddNoFollow::sanitize_string($html) );
}


1;



=head1 AUTHOR

Steve Kemp

http://www.steve.org.uk/



=head1 LICENSE

Copyright (c) 2007 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut
