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

IPTABLES_SAVE_BINARY  = '/sbin/iptables-save'
IPTABLES6_SAVE_BINARY = '/sbin/ip6tables-save'

SUPPORTED_TABLES = %w( filter nat mangle raw )
COUNTERS_PATTERN = '^:(.+)\s\[\d+:\d+\]'

def die(message, exit_code=1, with_new_line=true)
  if message and not message.empty?
    STDERR.print message + (with_new_line ? "\n" : '')
  end

  exit(exit_code)
end

def print_usage
  # Tables for IPv4 are filter, nat, mangle and raw.
  tables_IPv4 = SUPPORTED_TABLES

  # Tables for IPv6 are filter, mangle and raw.  There is no NAT in IPv6 ...
  tables_IPv6 = tables_IPv4.clone
  tables_IPv6.delete('nat')

  tables_IPv4 = tables_IPv4.join(' ')
  tables_IPv6 = tables_IPv6.join(' ')

  puts <<-EOS

This script is a wrapper for iptables-save and ip6tables-save binary that preserves
the order in which tables will be shown on the standard output.

Currently the order is:

  IPv4 tables are: #{tables_IPv4}
  IPv6 tables are: #{tables_IPv6}

Usage:

  #{$0} [--clear-counters] [--clear-output] [--help]

  Options:

    --ipv4            -4  Optional.  Select the IPv4 networking.  This is the default.

    --ipv6            -6  Optional.  Select the IPv6 networking.

    --clear-counters  -c  Optional.  Set packet counters per table back to zero.

    --clear-output    -o  Optional.  Remove comment lines from the output.

    --help            -h  This help screen.

  Note: You have to be a super-user in order to run this script.

  EOS

  exit 1
end

if $0 == __FILE__
  # Make sure that we flush buffers as soon as possible ...
  STDOUT.sync = true
  STDERR.sync = true

  print_usage if ARGV.first == '-'

  # Which binary do we want to use?  Defaults to IPv4 one ...
  binary = IPTABLES_SAVE_BINARY

  # Which tables do we support?  Default to IPv4 ones ...
  tables = SUPPORTED_TABLES

  # Which networking type was choosen?
  network_IPv4 = false
  network_IPv6 = false

  # To clear or not to clear ..?
  clear_counters = false

  # Whether we strip new lines, empty lines, comments etc ...
  clear_output = false

  begin
    GetoptLong.new(
      ['--ipv4',           '-4', GetoptLong::NO_ARGUMENT],
      ['--ipv6',           '-6', GetoptLong::NO_ARGUMENT],
      ['--clear-counters', '-c', GetoptLong::NO_ARGUMENT],
      ['--clear-output',   '-o', GetoptLong::NO_ARGUMENT],
      ['--help',           '-h', GetoptLong::NO_ARGUMENT]
    ).each do |option, argument|
      case option
        when /^(?:--ipv4|-4)$/
          network_IPv4 = true
        when /^(?:--ipv6|-6)$/
          network_IPv6 = true
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

  # We cannot have both ...
  if network_IPv4 and network_IPv6
    die "#{$0}: options --ipv4 and --ipv6 are mutually exclusive ..."
  end

  if network_IPv6
    # There is no concept of NAT in IPv6 networking ...
    tables.delete('nat')
    binary = IPTABLES6_SAVE_BINARY
  end

  # Check whether an appropriate binary exists at known place?
  die "#{$0}: #{binary} does not exists ..." unless File.exists?(binary)

  tables.each do |name|
    # Grab and process output for a particular table ...
    %x{ #{binary} -t #{name} }.each_line do |line|
      # Remove bloat ...
      line.strip!

      # Skip new lines, empty lines and comment lines ...
      next if line.match(/^(\r\n|\n|\s*|#.*)$|^$/) and clear_output

      # When line matches pattern for counters and we decide to zero them ...
      if match = line.match(COUNTERS_PATTERN) and clear_counters
        # We cheat a little bit here in order to clear counters ...
        puts ":#{match[1]} [0:0]"
      else
        puts line
      end
    end
  end
end

# vim: set ts=2 sw=2 et :
# encoding: utf-8
