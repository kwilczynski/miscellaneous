#!/usr/bin/env ruby

#
# surprise.rb
#

module Surprise
  SPEED = 1.0

  DELIMETER = "\x1"

  QUOTE = "\x4c\x6f\x6f\x6b\x73\x20\x6c\x69" +
          "\x6b\x65\x20\x2e\x2e\x2e\x0a\x0a" +
          "\x01\x0a\x0a\x2e\x2e\x2e\x20\x79" +
          "\x6f\x75\x20\x66\x65\x6c\x6c\x20" +
          "\x66\x6f\x72\x20\x69\x74\x2e"

  FRAMES = "\x28\x20\xe2\x80\xa2\x5f\xe2\x80" +
           "\xa2\x29\x01\x28\x20\xe2\x80\xa2" +
           "\x5f\xe2\x80\xa2\x29\x3e\xe2\x8c" +
           "\x90\xe2\x96\xa0\x2d\xe2\x96\xa0" +
           "\x01\x28\x20\xe2\x80\xa2\x5f\xe2" +
           "\x8c\x90\xe2\x96\xa0\x2d\xe2\x96" +
           "\xa0\x01\x28\xe2\x8c\x90\xe2\x96" +
           "\xa0\x5f\xe2\x96\xa0\x29"

  def self.surprise!
    frames = FRAMES.split(DELIMETER)
    quote  = QUOTE.split(DELIMETER)

    swype_area = frames.max_by {|i| i.size }.size

    puts quote.shift
    sleep 0.5

    frames.each_with_index do |frame,index|
      print frame
      sleep SPEED
      print "\r" + (" " * swype_area) + "\r" if index < frames.size - 1
    end

    sleep 0.5
    puts quote.shift
    sleep 0.5
  end
end

if $0 == __FILE__
  STDOUT.sync = true
  Surprise.surprise!
end

# vim: set ts=2 sw=2 et :
# encoding: utf-8
