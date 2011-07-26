#!/usr/bin/env ruby

#
# iptables-save-wrapper.rb
#
# This script is a wrapper for iptables-save binary that preserves the order
# in which tables will be shown on the standard output ...
#
# This is due to a sheer fact that there is no guarantee whatsoever that the
# iptables-save binary will output tables in the same precise order every time
# you execute it which makes it harder to process and compare current output
# against any historic one you may have ...
#
# There are two additional options: first for setting packet counters back to
# zero, and second for removing any new lines, empty lines and comments from
# the output ...
#

require 'getoptlong'

IPTABLES_SAVE_BINARY      = '/sbin/iptables-save'
IPTABLES_SUPPORTED_TABLES = %w(filter nat mangle raw)
IPTABLES_COUNTERS_PATTERN = '^:(.+)\s\[\d+:\d+\]'

def die(message, exit_code=1, with_new_line=true)
  if message and not message.empty?
    STDERR.print message + (with_new_line ? "\n" : '')
  end

  exit(exit_code)
end

def print_usage
  puts <<-EOS

This script is a wrapper for iptables-save binary that preserves the order
in which tables will be shown on the standard output.

Currently the order is: #{IPTABLES_SUPPORTED_TABLES.join(' ')}

Usage:

  #{$0} [--clear-counters] [--clear-output] [--help]

  Options:

    --clear-counters  -c  Optional.  Set packet counters per table back to zero.

    --clear-output    -o  Optional.  Remove comment lines from the output.

    --help            -h  This help screen.

  Note: You have to be a super-user in order to run this script ...

  EOS

  exit 1
end

if $0 == __FILE__
  # Make sure that we flush buffers as soon as possible ...
  STDOUT.sync = true
  STDERR.sync = true

  # Check whether iptables-save binary exists at known place?
  unless File.exists?(IPTABLES_SAVE_BINARY)
    die "#{$0}: #{IPTABLES_SAVE_BINARY} does not exists ..."
  end

  # To clear or not to clear ...
  clear_counters = false

  # Whether we strip new lines, empty lines, comments etc ...
  clear_output = false

  begin
    GetoptLong.new(
      ['--clear-counters', '-c', GetoptLong::NO_ARGUMENT],
      ['--clear-output',   '-o', GetoptLong::NO_ARGUMENT],
      ['--help',           '-h', GetoptLong::NO_ARGUMENT]
    ).each do |option, argument|
      case option
        when /^(?:--clear-counters|-c)$/
          clear_counters = true
        when /^(?:--clear-output|-o)$/
          clear_output = true
        when /^(?:--help|-h)$/
          print_usage
      end
    end
  rescue GetoptLong::InvalidOption, GetoptLong::MissingArgument
    print_usage
  end

  # Only root is allowed to access content of Kernel space firewall tables ...
  unless Process.uid == 0 or Process.euid == 0
    die "#{$0}: you have to be a super-user to run this script ..."
  end

  IPTABLES_SUPPORTED_TABLES.each do |name|
    # Grab and process output for a particular table ...
    %x{ #{IPTABLES_SAVE_BINARY} -t #{name} }.each do |line|
      # Remove bloat ...
      line.strip!

      # Skip new lines, empty lines and comment lines ...
      next if line.match(/\r\n|\n|^$|^#/) and clear_output

      # When line matches pattern for counters and we decide to zero them ...
      if match = line.match(IPTABLES_COUNTERS_PATTERN) and clear_counters
        # We cheat a little bit here in order to clear counters ...
        puts ":#{match[1]} [0:0]"
      else
        puts line
      end
    end
  end
end

# vim: set ts=2 sw=2 et :
