#!/usr/bin/env ruby

#
# mogilefs_orphans.rb
#

require 'ostruct'
require 'optparse'

begin
  require 'mysql'
rescue LoadError
  require 'rubygems'
  require 'mysql'
end

class OpenStruct
  def has_item?(item)
    self.marshal_dump.has_key?(item.to_sym)
  end
end

class Numeric
  def to_human_readable
    result = ''
    value  = self

    %w(B K M G T P).each do |unit|

      if value <= 1024
        result = unit
        break
      end

      value /= 1024.to_f
    end

    "%.1f%s" % [value, result]
  end
end

if $0 == __FILE__
  STDOUT.sync = true
  STDERR.sync = true

  fids    = {}
  options = OpenStruct.new

  options.show_orphans_only = true
  options.show_paths_only   = false

  options.database = 'mogilefs'
  options.storage  = '/srv/mogilefs'

  parser = OptionParser.new do |option|
    option.banner = <<-EOS

Search for orphaned files in the MogileFS storage directory.

Usage:

#{option.summary_indent}#{$0} --host <HOST> --user <USER> --password [PASSWORD]
#{option.summary_indent}#{$0} --database <DATABASE> --storage-path <PATH>
#{option.summary_indent}#{$0} [--show-all-files] [--help]
    EOS

    option.separator "\nMandatory options:\n\n"

    option.on('-h', '--host <HOST>',
      'Host name of the database server to connect to.'
    ) do |value|
      options.host = value
    end

    option.on('-u', '--user <USER>',
      'Name of the user to use when connecting to database.'
    ) do |value|
      options.user = value
    end

    option.on('-p', '--password [PASSWORD]',
      'Password for given user to use when connecting to database.'
    ) do |value|
      options.password = value
    end

    option.separator "\nOptions:\n\n"

    option.on('-d', '--database <DATABASE>',
      'Specify database name to select and use. ' +
      'By default set to "mofilefs".'
    ) do |value|
      options.database = value
    end

    option.on('-s', '--storage-path <PATH>',
      'Specify path to the storage directory. ' +
      'By default set to "/srv/mogilefs".') do |value|
      options.storage = value
    end

    option.on('-o', '--show-paths-only',
      'Show absolute path only for all files. Useful for scripting.'
    ) do |value|
      options.show_paths_only = true
    end

    option.on('-a', '--show-all-files',
      'Show details about all files present in the storage directory.'
    ) do |value|
      options.show_orphans_only = false
    end

    option.on('--help',
      'Display this help message.'
    ) do
      puts option.help
      exit
    end

    option.separator "\n"
  end

  parser.parse!

  unless options.host and options.user and options.has_item?(:password)
    puts parser.help
    exit 1
  end

  unless File.exists?(options.storage)
    puts "Storage directory `#{options.storage}' does not exists ..."
    exit 1
  end

  pattern = File.join(options.storage, '/**/*')

  files = Dir.glob(pattern).select do |entry|
    entry.match(/\.[fF][iI][dD]$/)
  end

  if files.empty?
    STDERR.puts "Storage directory `#{options.storage}' " +
                "does not seem to have any files ..."
    exit 1
  end

  unless options.password
    print "Please provide password for user #{options.user}: "

    %x{stty -echo}
    secret = gets
    %x{stty echo}

    options.password = secret.strip

    puts "\n"
  end

  mysql = Mysql.new(options.host, options.user,
                    options.password, options.database)

  statement = mysql.prepare <<-EOS
    SELECT fid
    FROM tempfile
    UNION
      SELECT fid
      FROM file
    UNION
      SELECT fid
      FROM file_to_delete
  EOS

  statement.execute

  mysql.close

  if statement.num_rows == 0
    STDERR.puts 'No information about files available in the database yet.'
    exit 1
  end

  statement.each {|row| fids[row.shift] = 1 }

  output = []

  files.each do |file|
    path = file
    file = File.basename(file)
    fid  = file.split('.')[0].to_i

    if File.exists?(path)
      stat = File.stat(path)

      size  = stat.size
      ctime = stat.ctime
      mtime = stat.mtime
      atime = stat.atime

      orphan = fids.has_key?(fid)

      next if orphan and options.show_orphans_only

      if options.show_paths_only
        output << path
      else
        output << "#{file}\n" +
                  "\t orphan: #{orphan ? 'No' : 'Yes'}\n" +
                  "\t    fid: #{fid}\n" +
                  "\t   size: #{size.to_human_readable} (#{size})\n" +
                  "\t  ctime: #{ctime.to_s} (#{ctime.to_i})\n" +
                  "\t  mtime: #{mtime.to_s} (#{mtime.to_i})\n" +
                  "\t  atime: #{atime.to_s} (#{atime.to_i})\n" +
                  "\t   path: #{path}\n"
      end
    end
  end

  puts output.join("\n")
end

# vim: set ts=2 sw=2 et :
# encoding: utf-8
