#!/usr/bin/env ruby

rotating    = []
solid_state = []
unknown     = []

block_devices = '/sys/block'

exclude = %w(loop.* ram.* sr.*)
exclude = Regexp.union(*exclude.collect { |i| Regexp.new(i) })

Dir.entries(block_devices).each do |name|
  next if ['.', '..'].include?(name) or name.match(exclude)

  directory      = File.join(block_devices, name)
  rotation_state = File.join(directory, 'queue/rotational')

  # This file often does not exists when system runs as virtual machine guest ...
  if File.exists?(rotation_state)
    File.read(rotation_state).each_line do |line|
      line.strip!

      #
      # Numeric value can be:
      #
      # 0 -- SSD or something that does not rotate at all;
      # 1 -- HDD or antything that physically rotates.
      #
      # Anything else might like different storage type ...
      #
      if line.match(/^1$/)
        rotating << name
      elsif line.match(/^0$/)
        solid_state << name
      else
        unknown << name
      end
    end
  end
end

p [:rotating, rotating]
p [:solid_state, solid_state]
p [:unknown, unknown]

# vim: set ts=2 sw=2 et :
# encoding: utf-8