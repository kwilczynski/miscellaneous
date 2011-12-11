#!/usr/bin/env ruby

#
# fstab.rb
#
# This script provides the ability to retro-fit UUID device identifiers (and
# vice-versa) back into the "/etc/fstab" file that is currently present on
# the file system ...
#
# Unfortunately, this script cannot and should not be used to re-generate
# missing and/or broken "/etc/fstab" file from scratch.  This is because
# this script will consolidate both: a content of current "/etc/fstab" file
# and output from the "/sbin/blkid" binary; to do its work and therefore it
# cannot be used for restoration ...
#

require 'getoptlong'

# The default location of the "/etc/fstab".  It MUST be there, period.
FSTAB_FILE = '/etc/fstab'

# The default location on most modern Linux distributions ...
BLKID_BINARY = '/sbin/blkid'

def die(message, exit_code=1, with_new_line=true)
  if message and not message.empty?
    STDERR.print message + (with_new_line ? "\n" : '')
  end

  exit(exit_code)
end

def print_usage
  puts <<-EOS

This script provides the ability to retro-fit UUID device identifiers (and vice-versa)
back into the "/etc/fstab" file that is currently present on the file system.

Usage:

  #{$0} [--device] [--uuid] [--no-comments] [--no-header] [--help]

  Options:

    --uuid         -u  Optional.  Select an UUID identifier over device.  This is the default.

    --device       -d  Optional.  Select a device i.e. "/dev/sda1" over an UUID identifier.

    --no-comments  -c  Optional.  Remove auto-generated comment lines from the output.

    --no-header    -h  Optional.  Remove header from the output.

    --help             This help screen.

  Results will be shown on the standard output.

  Note: You have to be a super-user in order to run this script.

  EOS

  exit 1
end

if $0 == __FILE__
  # Make sure that we flush buffers as soon as possible ...
  STDOUT.sync = true
  STDERR.sync = true

  print_usage if ARGV.first == '-'

  fstab  = FSTAB_FILE
  binary = BLKID_BINARY

  # Which output mode was chosen?
  uuid_mode   = false
  device_mode = false

  # Whether to add header to the output or not?
  no_header = false

  # Whether to add comments to the output or not?
  no_comments = false

  begin
    GetoptLong.new(
      ['--device',      '-d', GetoptLong::NO_ARGUMENT],
      ['--uuid',        '-u', GetoptLong::NO_ARGUMENT],
      ['--no-comments', '-c', GetoptLong::NO_ARGUMENT],
      ['--no-header',   '-h', GetoptLong::NO_ARGUMENT],
      ['--help',              GetoptLong::NO_ARGUMENT]
    ).each do |option, argument|
      case option
        when /^(?:--device|-d)$/
           device_mode = true
        when /^(?:--uuid|-u)$/
           uuid_mode = true
        when /^(?:--no-comments|-c)$/
           no_comments = true
        when /^(?:--no-header|-h)$/
           no_header = true
        when /^(?:--help)$/
          print_usage
      end
    end
  rescue GetoptLong::InvalidOption, GetoptLong::MissingArgument
    print_usage
  end

  # Only root is allowed to read super-block information from a block device ...
  unless Process.uid == 0 or Process.euid == 0
    die "#{$0}: you have to be a super-user to run this script ..."
  end

  # We cannot have both ...
  if uuid_mode and device_mode
    die "#{$0}: options --uuid and --device are mutually exclusive ..."
  end

  # Check whether both files of interest actually exist on the file system ...
  %w(fstab binary).each do |i|
    i = eval(i)
    die "#{$0}: #{i} does not exists ..." unless File.exists?(i)
  end

  # We choose the UUID mode by default ...
  uuid_mode = true unless uuid_mode or device_mode

  devices      = {}
  file_systems = []

  #
  # Grab and process output of the "/sbin/blkid" binary ...
  #
  # We suppress reading from and writing to the cache file that usually
  # resides under the "/etc/blkid.tab" file (default location) in order
  # to get the most up-to-date information from a particular device
  # super-block.  Unfortunately this requires a low-level access to an
  # underlying device and therefore a super-user access level privileges
  # are required ...
  #
  %x{#{binary} -w /dev/null -c /dev/null 2> /dev/null}.each_line do |line|
    # Remove bloat ...
    line.strip!

    # Remove unwanted double-quotes ...
    line.tr!('"', '')

    entries = line.split(/\s+/)

    # Remove unwanted colon at the end of the device name ...
    device = entries[0].tr(':', '')

    # We only want the actual UUID ...
    uuid = entries[1].split('=')[1]

    devices[device] = uuid
  end

  # Grab and process content of the "/etc/fstab" file ...
  %x{cat #{fstab} 2>/dev/null}.each_line do |line|
    # Remove bloat ...
    line.strip!

    # Skip comments, new and empty lines ...
    next if line.match(/^(\r\n|\n|\s*)$|^$|^#/)

    entries = line.split(/\s+/)

    if entries[0].match(/^UUID/)
      # We only want the actual UUID ...
      uuid   = entries[0].split('=')[1]
      device = devices.invert[uuid]
    else
      # The uuid may not exist for some of the entries i.e. NFS mounts, etc ...
      device = entries[0]
      uuid   = devices[device]
    end

    # We turn file system list and options into an array ...
    file_system = entries[2].split(',')
    options     = entries[3].split(',')

    file_systems << { :device      => device,
                      :mount_point => entries[1],
                      :file_system => file_system,
                      :options     => options,
                      :dump        => entries[4],
                      :pass        => entries[5],
                      :uuid        => uuid }
  end

  # We provide a default header with basic information about "/etc/fstab" file ...
  unless no_header
    puts <<-EOS
#
# /etc/fstab: A static file system information.
#
# Fields are as follows:
#
#  <device> <mount point> <file system> <options> <dump> <pass>
#
# For more details please refer to: man 5 fstab.
#
    EOS
  end

  # Process each entry ...
  file_systems.each do |i|
    if uuid_mode
      # Assemble comment if possible to indicate an underlying device ...
      if i[:uuid]
        device  = "UUID=#{i[:uuid]}"
        comment = "# #{i[:device]}"
      else
        device = i[:device]
      end
    elsif device_mode
      # Assemble comment to show UUID when available ...
      comment = "# UUID=#{i[:uuid]}" if i[:uuid]
      device  = i[:device]
    end

    file_system = i[:file_system].join(',')
    options     = i[:options].join(',')

    # Whether to add comment or not ...
    puts comment unless no_comments or not comment

    # We print fields that are space-separated.  Simplicity is desirable ...
    puts "#{device} #{i[:mount_point]} #{file_system} #{options} " +
         "#{i[:dump]} #{i[:pass]}"
  end
end

# vim: set ts=2 sw=2 et :
# encoding: utf-8
