#!/usr/bin/env perl

use strict;
use warnings;

$| = 1;

my $count = 0;
my $time = time;

while (<>) {
  $count++;

  if (time > $time) {
    $time = time;
    print "$count";
    $count = 0
  }

  print "\r"
}

# perl -e '$| = 1; while (<>) { $count++; if (time > $time) { $time = time; print "$count"; $count = 0 }; print "\r" }'

# Test with: (while :; do ruby -e 'puts "\n" * rand(5)'; sleep 1 ; done)
