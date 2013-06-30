#!/usr/bin/env ruby

class Cache
  attr_reader :cache

  class << self
    def get(file, expiry, &block)
      raise ArgumentError, 'no block given'  unless block_given?
      Cache.new(file, expiry, &block).cache
    end
  end

  def initialize(file, expiry, &block)
    require 'pstore'

    store = PStore.new(file)

    @cache = begin
       store.transaction do
        if Time.now.to_i - (store[:time] ||= 0) >= expiry
          store[:time]  = Time.now.to_i
          store[:cache] = block.call
        end

        store[:cache]
      end
    end
  end
end

if $0 == __FILE__
  c = Cache.get('/tmp/test.pstore', 10) do
    sleep 5
    Time.new.to_s
  end

  p c
end
