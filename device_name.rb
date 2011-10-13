#!/usr/bin/env ruby

#
# device_name.rb
#
# Display an underlying device on which a particular file has been stored.
#
# For example:
#
#   $ device_name.rb /etc/resolv.conf
#   /dev/rdisk0s2
#

# We monkey-patch a little ...
class File::Stat
  class << self
    def device_name(file)
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

      # Return only the device of interest ...
      known_devices.values_at(File.stat(file).dev).shift
    end
  end
end

def die(message, exit_code=1, with_new_line=true)
  if message and not message.empty?
    STDERR.print message + (with_new_line ? "\n" : '')
  end

  exit(exit_code)
end

def print_usage
  puts <<-EOS

Usage:

  #{$0} <FILE> [--verbose] [--help]

  Options:

    Specify <FILE> for which you wish to display its underlying device.

    --verbose  -v  Optional.  Specify more verbose output.

    --help     -h  This help screen.

  EOS

  exit 1
end

if $0 == __FILE__
  # Make sure that we flush buffers as soon as possible ...
  STDOUT.sync = true
  STDERR.sync = true

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

  die(verbose ? "#{file} does not exists ..." : '') unless File.exists?(file)

  if device = File::Stat.device_name(file)
    puts (verbose ? "#{file} has underlying device #{device}" : "#{device}")
  else
    die(verbose ? "Unable to locate underlying device for #{file} ..." : '')
  end
end

# vim: set ts=2 sw=2 et :
# encoding: utf-8
