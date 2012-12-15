
=head1 NAME

HTML::AddNoFollow - A simple module to add 'rel="nofollow"' to hyperlinks.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w
    use HTML::AddNoFollow;
    use strict;

    my $html = q[ <a href="http://foo.com/">Test</a> ];

    my $cgi  = new CGI;
    $cgi->param( "html", $html );

    $cgi = HTML::AddNoFollow::sanitize( $cgi );

=for example end


=head1 DESCRIPTION

If you wish to display user supplied HTML text you may well find that
people submit links inside HTML, designed to increase their page-rank.

This module automatically defeats those people by adding the 'rel="nofollow"'
to the hyperlinks.

The module will correctly modify all input which is accessed via a
CGI object - if you wish to only filter one particular variable then
you must create a fake CGI object, as shown in the example.


=cut


=head1 SOURCE

This code was achieved via a discussion on Perlmonks.org, via a question
I submitted.  For all the discussion please see the following URI:

http://www.perlmonks.org/?node_id=452790

=cut


require Encode;

package HTML::AddNoFollow;
use strict;
use base 'HTML::Scrubber';


sub _validate
{
    my ( $self, $t, $r, $a, $as ) = @_;

    if ( $t eq 'a' )
    {
        $$a{ rel } = 'nofollow';
        push @$as, 'rel' unless grep {/rel/} @$as;
    }

    $self->SUPER::_validate( $t, $r, $a, $as );
}



# ===========================================================================
#  Sanitize all input variables from the given form.
# ===========================================================================
sub sanitize
{
    my ($form) = (@_);

    #
    #  Update each paramater with the cleaned version
    #
    foreach my $p ( $form->param() )
    {

        # Get value
        my $val = $form->param($p);

        # scrub it
        $val = sanitize_string($val);

        # store the clena version.
        $form->param( $p, $val );
    }

    return ($form);

}



=head2 sanitize_string

  Sanitize a single HTML String.

=cut

sub sanitize_string
{
    my ($str) = (@_);

    my @allow = qw[cut blockquote];
    my @deny =
      qw[script center embed object form input marquee menu meta option font div];
    my @rules = (
        img => {src   => qr{^(http://)}i,    # only absolute image links allowed
                alt   => 1,                  # alt attribute allowed
                align => 1,                  # align attribute allowed
                '*'   => 0,                  # deny all other attributes
               },
        a => { href  => 1,                  # HREF
               name  => 1,                  # name attribute allowed
               id    => 1,                  # id attribute allowed
               title => 1,                  # title attribute allowed
               rel   => qr/^nofollow$/i,    # Link relationship
               '*'   => 0,                  # deny all other attributes
             },
        pre => { class => 1,
                 style => 0,
               },
        span => { class => 1,
                  style => 0,
                },
    );

    my @default = (
        1 =>                             # default rule, allow all tags
          { '*' => 1,                    # default rule, allow all attributes
            'href'     => qr{^(?!(?:java)?script)}i,
            'src'      => qr{^(?!(?:java)?script)}i,
            'cite'     => '(?i-xsm:^(?!(?:java)?script))',
            'language' => 0,
            'name'        => 1,          # could be sneaky, but hey ;)
            'onblur'      => 0,
            'color'       => 0,
            'class'       => 0,
            'style'       => 0,
            'onchange'    => 0,
            'onclick'     => 0,
            'ondblclick'  => 0,
            'onerror'     => 0,
            'onfocus'     => 0,
            'onkeydown'   => 0,
            'onkeypress'  => 0,
            'onkeyup'     => 0,
            'onload'      => 0,
            'onmousedown' => 0,
            'onmousemove' => 0,
            'onmouseout'  => 0,
            'onmouseover' => 0,
            'onmouseup'   => 0,
            'onreset'     => 0,
            'onselect'    => 0,
            'onsubmit'    => 0,
            'onunload'    => 0,
            'type'        => 0,
            'font'        => 0,
          } );


    #
    #  Create the scrubber.
    #
    my $safe = HTML::AddNoFollow->new();
    $safe->allow(@allow);
    $safe->rules(@rules);
    $safe->deny(@deny);
    $safe->default(@default);

    # deny HTML Comments
    $safe->comment(0);

    return ( $safe->scrub($str) );
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
