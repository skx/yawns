#!/usr/bin/perl -w -Ilib/
#
#  Minimal general purpose tag testing.
#
# $Id: yawns-tags.t,v 1.7 2007-02-11 15:23:09 steve Exp $
#


use Test::More qw( no_plan );

#
#  Load the modules we use.
#
BEGIN { use_ok( 'Yawns::Tags'); }
require_ok( 'Yawns::Tags' );


#  Pick a random tag
my $new_tag = join ( '', map {('a'..'z')[rand 26]} 0..7 );

#
# Get a tag object
#
my $tag = Yawns::Tags->new();
isa_ok( $tag, "Yawns::Tags" );



#
#  Get *all* tags and count them.
#
my $all   = $tag->getAllTags();
my $total = scalar(@$all);

ok( $total, "Found total: $total" );
ok( $total =~ /^([0-9]+)$/, "Which is a number" );



#
#  Now get all the tags of each type.
#
my %results;
my @types    = $tag->getTagTypes();

foreach my $type ( @types )
{
    #
    #  Get the tags + counts.
    #
    my $tmp_tags  = $tag->getAllTagsByType( $type );
    my $tmp_count = 0;
    $tmp_count    = scalar @$tmp_tags if ( defined( $tmp_tags ) );

    #
    #  Ensure they are found + numbers.
    #
    ok( defined $tmp_count, "Found count for $type: $tmp_count" );
    ok( $tmp_count =~ /^([0-9]+)$/, "Which is a number" );

    # All tags doesn't include submissions.
    next if ( $type =~ /s/ );

    # Store count
    $results{$type} = $tmp_count;

}



#
#  Add a tag and confirm that the case is changed.
#
my $value = join ( '', map {('A'..'Z')[rand 26]} 0..17 );
ok( $value =~ /^([A-Z]+)$/, "New tag is completely upper-cased" );

#
#  Add the tag
#
$tag->addTag( article => 0,
              tag     => $value );

#
#  Get the updated tags.
#
my $set = $tag->getTags( article => 0 );

#
#  Find the newly added value.
#
my $tag_value =  @$set[0]->{"tag"};

#
#  Ensure it is lowercased.
#
is( $tag_value, lc($value), "The new tag had the case changed." );

#
#  Delete the tag
#
$tag->deleteTags( article => 0 );
