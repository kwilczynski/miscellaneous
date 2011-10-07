#!/usr/bin/env ruby

#
# csv_compare.rb
#
# This script allows for comparing together two files utilising the popular
# comma-separated values (CVS) pseudo-file format.
#

# Ruby Core CSV is slow but it will do the job this time ...
require 'csv'

# Small helper class ...
class Compare
  class << self
    def csv(this, other, headers=false)
      this  = CSV.read(this)
      other = CSV.read(other)

      # Store each row in the CSV file here ...
      rows = []

      # I hope no Ruby Developer will ever see this. Heresy :-)
      %w(this other).each { |i| eval "#{i}.shift" } unless headers

      # Select file with greater number of rows and/or records ...
      size = [this.size, other.size].max

      # We have this row, other row and index.  Ugly, but convenient ...
      size.times do |i|
        # Substitute with empty array when no value is present e.g. empty line ...
        this[i]  ||= []
        other[i] ||= []

        # Store both values and position at which they were ...
        rows << [this[i], other[i], i] unless this[i] == other[i]
      end

      rows
    end
  end
end

if $0 == __FILE__
  # Poor man's command line arguments processing ...
  this  = ARGV.shift
  other = ARGV.shift

  # We terminate if no files are given ...
  unless this and other
    puts 'Please specify files you wish to compare.'
    exit 1
  end

  # We accept anything and simply go about with including headers ...
  headers = ARGV.shift ? true : false

  begin
    # Compare given CVS files ...
    result = Compare.csv(this, other, headers)
  rescue Exception => e
    puts "An error occurred while comparing files: #{e}"
    exit 1
  end

  # Keep things simple and avoid long path names ...
  this  = File.basename(this)
  other = File.basename(other)

  unless result.empty?
    result.each do |i|
      # Turn back in CVS-alike list and/or value ...
      t = i[0].join(',')
      o = i[1].join(',')

      # Human beings like when things start counting from 1 ...
      row = i[2] += 1

      puts "#{this}(#{row}): #{t}\n#{other}(#{row}): #{o}"
    end

    exit 1
  end

  exit 0
end
