#!/usr/bin/perl -w -I..
#
#  Test that we have only a single number for each migration script.
#
# $Id: db-migration.t,v 1.1 2007-03-09 10:49:03 steve Exp $
#

use Test::More qw( no_plan );


#
#  Find the directory
#
my $dir;


foreach my $d ( qw! tables/migrations ../tables/migrations  ! )
{
    $dir = $d if ( -d $d );
}



#
#  Got a directory
#
ok( -d $dir , "The migrations directory was found" );


#
#  Now look at each file.
#
my @files = glob( $dir . "/*.sql" );
ok( $#files, "We found some migration files" );

#
#  Split up into the number
#
my %counts;

foreach my $f ( @files )
{
    my $num = 0;

    if ( $f =~ /([0-9]+)/ )
    {
        # strip leading zeros
        my $num =$1;
        $num =~ s/^0+//g;
        $num = 0 if (!length( $num ) );
        ok( $num =~ /^([0-9]+)$/ , "The migration file was numbered." );
        $count{$num} += 1;
    }
}

#
#  Now make sure each number is only used once.
#
foreach my $key ( sort keys %count )
{
    is( 1, $count{$key}, "The migration number is only used once: $key." );
}
