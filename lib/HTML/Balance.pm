
=head1 NAME

HTML::Balance - A simple Perl module to ensure HTML is "balanced".

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w
    use HTML::Balance;
    use strict;

    my $html = q[ <p><i>This is a <b>test</i></p>];

    my $output = HTML::Balance::balance( $html );

=for example end


=head1 DESCRIPTION

If you wish to display user supplied HTML text you may well find yourself
a victim of people submitting malformed text, with tags that are not closed.

This module is designed to prevent that.


=cut


=head1 SOURCE

This code was taken from discussions held on Perlmonks.  For full details
please see the following URI:

http://www.perlmonks.org/?node_id=534760

=cut


package HTML::Balance;

use strict;
use HTML::TreeBuilder;


=head2 balance

  Balance some HTML using the HTML::TreeBuilder module.
  This is designed to ensure all open HTML tags are closed.

=cut

sub balance
{
    my ($text) = (@_);

    return ("") if ( !defined($text) );
    return ("") if ( !length($text) );

    my $tree = HTML::TreeBuilder->new();

    $tree->parse($text);
    $tree->eof();

    my $ret = $tree->as_HTML();

    $ret =~ s/<html><head><\/head><body>//g;
    $ret =~ s/<\/body><\/html>//g;

    chomp($ret);
    return ($ret);
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
