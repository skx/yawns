#!/usr/bin/perl -w -Ilib/
#
# Test that external links have 'nofollow' added to them.
#
# $Id: add-no-follow.t,v 1.7 2006-03-13 08:08:37 steve Exp $
#

use Test::More qw( no_plan );

# Can we load the module?
BEGIN { use_ok( 'HTML::AddNoFollow' ); }
require_ok( 'HTML::AddNoFollow' );

# Create object?
my $safe = HTML::AddNoFollow->new();

# Is it created OK?
ok( defined( $safe ), "Created OK" );

# Is it the correct type?
isa_ok( $safe, "HTML::AddNoFollow" );


#
# Test using the code.
#
my $html1 = q[ <a href="http://www.foo.com/">foo.com</a> ];
my $html2 = q[ <p>This is some test text</p> ];
my $html3 = q[ <a href="http://www.foo.com/" rel="1">test</a> ];

my @allow = qw[ a p ];
my @rules = (
	     a => {
		   href => 1,                # HREF
		   title => 1,               # ALT attribute allowed
		   rel => qr/^nofollow$/i,
		   '*' => 0,                 # deny all other attributes
		  },
	    );

$safe->allow( @allow );
$safe->rules( @rules );

#
#  Process a link.
#
my $out1 = $safe->scrub( $html1 );
ok( $out1 =~ /nofollow/, 'link added');


#
#  Now a non-link
#
my $out2 = $safe->scrub( $html2 );
ok( $out2 eq $html2, 'paragraph ignored');

#
#  Modify the rel
#
my $out3 = $safe->scrub( $html3 );
ok( $out3 =~ /nofollow/, 'rel atribute changed');
