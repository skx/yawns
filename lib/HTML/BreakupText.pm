# -*- cperl -*- #

=head1 NAME

HTML::BreakupText - Perl extension for adding whitespace to HTML text.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w
    use HTML::BreakupText;
    use strict;

    my $html = q[<a href="http://foooooooooooooooo.com/">http://foooooooooooooooooooooooooooooo.com</a>];

    my $formatter = HTML::BreakupText->new( width => 10 );
    my $output = $formatter->BreakupText( $html );

=for example end


=head1 DESCRIPTION

If you wish to display user supplied HTML text you may well find yourself
a victim of people submitting long, unbroken, strings of input.

This results in so-called "page widening".

This module is designed to prevent this from occurring by breaking up
supplied content into space deliminated output.  The module is clever
enough to not modify HTML attribute values - only their text componants.


=cut


package HTML::BreakupText;

use vars qw($VERSION $DEFAULT_WIDTH @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.8 $' =~ m/Revision:\s*(\S+)/;
($DEFAULT_WIDTH) = 60;

use HTML::TokeParser;


=head2 new

  Create a new instance of this object.

=cut

sub new
{
    my ( $self, %supplied ) = (@_);

    my $class = ref($self) || $self;

    # the options hash
    my $options = {};
    $self->{ options } = $options;

    # Set default width
    $options{ width } = $DEFAULT_WIDTH;

    #
    #  Allow user supplied values to override our defaults
    #
    foreach my $key ( keys %supplied )
    {
        $options{ lc $key } = $supplied{ $key };
    }
    return bless {}, $class;
}


=head2 BreakupText

  Process the given text and optional hash of options.

  Return the modified text;

=cut

sub BreakupText
{
    my ( $class, $str ) = (@_);

    #
    # Get the user supplied split-width.
    #
    my $options = $self->{ options };
    my $width   = $options{ width };

    my $tp = HTML::TokeParser->new( \$str ) or
      die "Couldn't parse $str: $!";

    $tp->unbroken_text(1);

    my ( $html, $start );

    while ( my $tag = $tp->get_token )
    {

        if ( $tag->[0] eq 'T' )
        {

            #
            #  Here is where we breakup
            #
            my $t = $tag->[1];
            $t =~ s/(\S{$width})/$1 /g;
            $html .= $t;
        }
        else
        {
            $html .= $tag->[4] if $tag->[0] eq 'S';
            $html .= $tag->[1] if $tag->[0] eq 'C';
            $html .= $tag->[2] if $tag->[0] eq 'E';
        }
    }

    return ($html);
}


1;


=head1 AUTHOR

Steve Kemp

http://www.steve.org.uk/



=head1 LICENSE

Copyright (c) 2005 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut
