#!/usr/bin/env ruby

require 'rubygems'
require 'fizzbuzz'

DEFAULT_SIZE = 100

if $0 == __FILE__
  size = ARGV.shift || DEFAULT_SIZE

  fb = FizzBuzz.new(size.to_i)
  fb.each {|i| puts i }
end
