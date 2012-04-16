#!/usr/bin/env ruby

#
# ext4_crtime.rb
#
# This script allows for accessing details of crtime (Creation Time) available
# on the ext4 file system alongside ctime (Change Time), atime (Access Time)
# and mtime (Modification Time).
#

DEBUGFS_BINARY = '/sbin/debugfs'

def die(message, exit_code=1, with_new_line=true)
  if message and not message.empty?
    STDERR.print message + (with_new_line ? "\n" : '')
  end

  exit(exit_code)
end

def print_usage
  puts <<-EOS

Usage:

  #{$0} <FILE>

  Options:

    Specify <FILE> for which you wish to display its crtime (Creation Time).

    --verbose  -v  Optional.  Specify more verbose output.  The ctime (Change Time),
                   atime (Access Time) and mtime (Modification Time) will be also shown.

    --help     -h  This help screen.

    Please note that this is for ext4 file system only.

  EOS

  exit 1
end

if $0 == __FILE__
  # Make sure that we flush buffers as soon as possible ...
  STDOUT.sync = true
  STDERR.sync = true

  # No option given and/or bad option?
  print_usage if ARGV.size < 1 or ARGV.first == '-'

  file    = ''
  verbose = false

  option = ARGV.shift

  # Very rudimentary approach ...
  case option
    when /^--verbose|-v$/
      verbose = true
      file    = ARGV.shift
    when /^--help|-h$/
      print_usage
    else
      file = option
  end

  print_usage unless file

  # Only root is allowed to access meta-data of the underlying file system ...
  unless Process.uid == 0 or Process.euid == 0
    die "#{$0}: you have to be a super-user to run this script ..."
  end

  die "#{$0}: given file does not exists: #{file}" unless File.exists?(file)

  # List of numeric identifiers with their corresponding canonical forms ...
  known_devices = Dir['/dev/*'].inject({}) do |k,v|
    #
    # We protect ourselves against broken symbolic links under "/dev" and
    # skip all non-block devices as for example a sound card cannot really
    # host a file system ...
    #
    if File.exists?(v) and File.blockdev?(v)
      # Resolve any symbolic links we may encounter ...
      v = File.readlink(v) if File.symlink?(v)

      #
      # Make sure that we have full path to the entry under "/dev" ...
      # This tends to be often broken there ...  Relative path hell ...
      #
      v = File.join('/dev', v) unless File.exists?(v)

      k.update(File.stat(v).rdev => v)
    end

    k # Yield hash back into the block ...
  end

  # Select underlying device name based on the device ID ...
  device = known_devices[File.stat(file).dev].first

  # Grab and process output for particular file given ...
  %x{ #{DEBUGFS_BINARY} -R "stat #{file}" #{device} 2> /dev/null }.each_line do |line|
    # Remove bloat ...
    line.strip!

    # We parse only matching lines ...
    if line.match(/^.+?time:.+/)
      type, date = line.split('--')
      type = type.split(':')[0]

      # Remove bloat ...
      type.strip!
      date.strip!

      # Whether we show all meta-data or only Creation Time ...
      if verbose
        puts "#{type}: #{date}"
      elsif type.match(/^crtime/)
        puts "#{type}: #{date}"
        break
      end
    else
      # Skip irrelevant entries ...
      next
    end
  end
end

# vim: set ts=2 sw=2 et :
# encoding: utf-8
