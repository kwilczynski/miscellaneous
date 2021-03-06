#!/usr/bin/env ruby

#
# fetch_haproxy_backend_bytes.rb
#
# This script fetches byte counters (both input and output) from HA Proxy for
# a given back-end server pool.  Resulting output format works perfectly with
# Cacti as its data source ...
#

require 'rubygems'

require 'csv'
require 'uri'
require 'net/http'
require 'getoptlong'

# We assume that by default HTTP is of interest ...
DEFAULT_PORT = 80

def die(message, exit_code=1, with_new_line=true)
  if message and not message.empty?
    STDERR.print message + (with_new_line ? "\n" : '')
  end

  exit(exit_code)
end

def print_usage
  puts <<-EOS

Fetch both input and output byte counters from HA Proxy for a given back-end server pool.

Usage:

  #{$0} --host <HOST NAME> --backend <BACKEND NAME> [--port <PORT NUMBER>] [--help]

  Options:

    --host     -h  <HOST NAME>     Required.  Specify the remote HA Proxy to connect to.

    --backend  -b  <BACKEND NAME>  Required.  Specify the back-end pool name for which to fetch the input and output byte counters.

    --port     -p  <PORT NUMBER>   Optional.  Specify a port on the remote host to use when establishing a connection.
                                              By default this is set to be #{DEFAULT_PORT}.

    --help   -h                    This help screen.

  EOS

  exit 1
end

if $0 == __FILE__
  # Make sure that we flush buffers as soon as possible ...
  STDOUT.sync = true
  STDERR.sync = true

  print_usage if ARGV.size < 1 or ARGV.first == '-'

  host_name = ''
  host_port = DEFAULT_PORT

  backend_name = ''

  # We store content of the response from HA Proxy here ...
  response = ''

  begin
    GetoptLong.new(
      [ '--host',    '-h', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--port',    '-p', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--backend', '-b', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--help',    '-?', GetoptLong::NO_ARGUMENT       ]
    ).each do |option, argument|
      case option
        when /^(?:--host$|-h)$/
          host_name = argument
        when /^(?:--port|-p)$/
          host_port = argument
        when /^(?:--backend$|-b)$/
          backend_name = argument
        when /^(?:--help|-?)$/
          print_usage
      end
    end
  rescue GetoptLong::InvalidOption, GetoptLong::MissingArgument
    print_usage
  end

  print_usage if host_name.empty? or backend_name.empty?

  uri = URI.parse("http://#{host_name}:#{host_port}/")

  begin
    # Fire the request against HA Proxy ...
    response = Net::HTTP.start(uri.host, uri.port) do |http|
      http.get('/haproxy?stats;csv')
    end

    # And get the response back ...
    response = response.body
  rescue Exception => e
    die "#{$0}: unable to establish connection with the remote host given: #{e}"
  end

  begin
    # Parse response and process fields of interest in the row given ....
    CSV.parse(response) do |row|
      proxy = row[0]
      type  = row[1]
      bytes_in  = row[8]
      bytes_out = row[9]

      # We look for back-end pool only ...
      if type.match(/BACKEND/) and proxy == backend_name
        puts "bytes_in:#{bytes_in} bytes_out:#{bytes_out}"
      end

    end
  rescue Exception => e
    # Broken CSV?  Not really possible... but you never know ...
    die "#{$0}: unable to correctly parse the CSV data given: #{e}"
  end
end

# vim: set ts=2 sw=2 et :
# encoding: utf-8
