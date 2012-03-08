#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;

use constant {
  BLKID_BINARY  => '/sbin/blkid',
  DEFAULT_COUNT => 1,
  MOUNT_POINT   => '/srv/mogilefs',
  MOUNT_OPTIONS => 'defaults,noatime'
};

my $script_name = basename($0);

my $count         = $ARGV[0] ? $ARGV[0] : DEFAULT_COUNT;
my $mount_point   = $ARGV[1] ? $ARGV[1] : MOUNT_POINT;
my $mount_options = $ARGV[2] ? $ARGV[2] : MOUNT_OPTIONS;

if ($ARGV[0] && $ARGV[0] =~ /^(-h|-help)/) {
  $mount_options = join(', ', split(',', $mount_options));

  print <<EOS;

Generate output suitable for use in "/etc/fstab" when using RAW hard disks (e.g. no partition table is present).

Usage: $script_name [COUNT] [MOUNT POINT] [MOUNT OPTIONS]

 Options:

   [COUNT]          Optional.  Start value for the numeric device count. By default set to: $count
   [MOUNT POINT]    Optional.  By default mount point is set to: $mount_point
   [MOUNT OPTIONS]  Optional.  When no mount options are given it defaults to: $mount_options

EOS

  exit 0;
}

my $blkid = BLKID_BINARY . ' -w /dev/null -c /dev/null 2> /dev/null | sort';

open(BLKID, $blkid . ' |');

while (my $line = <BLKID>)
{
  if ($line =~ /^(?<device>[a-zA-Z\/]+):\sUUID="(?<uuid>.+)"\sTYPE="(?<type>.+)"/)
  {
    print "# $+{device}\nUUID=$+{uuid} $mount_point/dev${count} $+{type} $mount_options 0 0\n";
  }

  $count += 1;
}

close(BLKID);
