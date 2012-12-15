# -*- cperl -*- #

=head1 NAME

Yawns::Formatters::BBCode - A module for formatting plain text into HTML


=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Formatters::Text;
    use strict;

    # Load the original
    my $html     = Yawns::Formatters::Text->new( text=> 'Some text\nhere');

    # Now the accessors.
    my $preview  = $html->getPreview();
    my $original = $html->getOriginal();


=for example end


=head1 DESCRIPTION

This module contains code for formatting user submitted text in
BBCode into HTML.

This is used for comment posting, and weblog entry creation.

=cut


package Yawns::Formatters::Text;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.4 $' =~ m/Revision:\s*(\S+)/;


#
#  Standard modules which we require.
#
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

    # get the text.
    my $text = $class->{ 'text' };
    die "No text" unless ($text);

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

    # encode it.
    $text = HTML::Entities::encode_entities($text);

    # Now we'll do some touchups.

    #
    #  Italic
    #
    $text =~ s/&lt;i&gt;/<i>/g;
    $text =~ s/&lt;\/i&gt;/<\/i>/g;

    #
    #  Bold
    #
    $text =~ s/&lt;b&gt;/<b>/g;
    $text =~ s/&lt;\/b&gt;/<\/b>/g;

    #
    #  tt
    #
    $text =~ s/&lt;tt&gt;/<tt>/gi;
    $text =~ s/&lt;\/tt&gt;/<\/tt>/gi;

    #
    #  Pre
    #
    ##
    #  <pre> + </pre>
    ##
    while ( $text =~ m!(.*)&lt;pre&gt;(.*)&lt;/pre&gt;(.*)!s )
    {
        my $pre = $1;
        my $txt = $2;
        my $pos = $3;

        $txt =~ s/&lt;br&gt;//gi;
        $txt =~ s/&lt;br \/&gt;//gi;
        $txt =~ s/<br \/>//gi;
        $txt =~ s/<br>//gi;
        $txt =~ s/\n//gi;
        $text = $pre . "<pre>" . $txt . "</pre>" . $pos;
    }

    # add newlines.
    $text =~ s/\n/<br \/>/g;

    # return.
    return $text;
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
