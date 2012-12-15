# -*- cperl -*- #

=head1 NAME

HTML::Linkize - Add Hyperlinks to plain text/HTML.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w
    use HTML::Linkize;
    use strict;

    # Text to add links to.
    my $text = q[ http://foo.com/  <a href="http://bar.com/">Bar</a> ];

    # Create linker object.
    my $linker = HTML::Linkize->new();

    # Display results.
    print $linker->linkize($text) . "\n";

=for example end

=head1 DISCUSSION

  For more discussion on the code, and why it is implemented in this
 manner you might be interested in the following node at Perlmonks:

   http://www.perlmonks.org/?node_id=514464

=cut


=head1 DESCRIPTION

If you wanna display HTML links in text, but you don't want to break
text which already contains well-formed HTML links then this is the
module you'll need.

=cut


package HTML::Linkize;


use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.6 $' =~ m/Revision:\s*(\S+)/;

use HTML::Parser;
use URI::Find;



=head2 new

  Create a new instance of this object.

=cut

sub new
{
    my ( $proto, %supplied ) = (@_);

    my $class = ref($proto) || $proto;

    my $self = {};

    # the options hash
    $self->{ 'uri_find' } = URI::Find->new(
        sub {
            my ( $uri, $orig_uri ) = @_;
            return qq|<a href="$uri" rel="nofollow">$orig_uri</a>|;
        } );


    bless( $self, $class );
    return $self;
}


=head2 linkize

    Actually perform the linking of the text.

=cut

sub linkize
{
    my ( $class, $str ) = (@_);

    my $result = "";

    #
    # Get the URI::Find object we previously created.
    #
    my $finder = $class->{ 'uri_find' };


    #
    # Create a new HTML parser to process the text.
    #
    my $p = HTML::Parser->new(
        unbroken_text => 1,

        default_h => [sub {$result .= shift}, 'text'],

        text_h => [
            sub {
                my $text = shift;
                $finder->find( \$text );
                $result .= $text;
            },
            'text'
                  ],
    );

    #
    # Parse our input
    #
    if ( ( defined($str) ) and ( length($str) ) )
    {
        $p->parse($str);
        $p->eof();
    }

    #
    # All done.
    #
    return ($result);

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
