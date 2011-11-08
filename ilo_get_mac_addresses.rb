#!/usr/bin/env ruby

#
# ilo_get_mac_addresses.rb
#
# This script allows for querying HP iLO (hopefully, including iLO2 and iLO3)
# for network cards MAC address details using Secure Shell (SSH version 2) as
# a transport ...
#
# Unfortunately, all the host names and their passwords are hard-coded for
# the time being ... :-(
#

require 'rubygems'

require 'thread'
require 'net/ssh'
require 'timeout'

# Number of seconds after which we consider execution as expired ...
DEFAULT_EXECUTION_TIME_OUT = 5

# Default built-in user name that every iLO has as per factory defaults ...
DEFAULT_ILO_USER_NAME = 'Administrator'

# iLO command line path for querying network cards details ...
DEFAULT_ILO_NICS_PATH = 'system1/network1/Integrated_NICs'

# We only look for details concerning network cards ...
DEFAULT_ILO_MAC_PATTERN = '[iI][lL][oO]3_MAC.+'
DEFAULT_ILO_NIC_PATTERN = '[Pp]ort\d+NIC_.+'

# Static map of hosts to iLO passwords ...
hosts = { 'host-001' => 'XXXXXXX1',
	  'host-002' => 'XXXXXXX2',
	  'host-003' => 'XXXXXXX3',
	  'host-004' => 'XXXXXXX4' }

if $0 == __FILE__
  mutex = Mutex.new

  # We store details of the MAC addresses here ...
  configuration = Hash.new { |k,v| k[v] = {} }

  # Capture all worker threads here so we collect them later ...
  threads = []

  # Process each host in a separate thread ...
  hosts.each do |host,password|
    threads << Thread.new(host) do |h|
      begin
	timeout(DEFAULT_EXECUTION_TIME_OUT) do
	  Net::SSH.start(
	    host,
	    DEFAULT_ILO_USER_NAME,
	    :password => password,
	    :paranoid => false
	  ) do |ssh|
	    ssh.exec("show #{DEFAULT_ILO_NICS_PATH}") do |channel, stream, data|
	      #
	      # Check whether there was any error.  Technically there should
	      # not be any as we are working with remote appliance which is
	      # noting alike Bash shell etc ...
	      #
	      if stream == :stderr
		mutex.synchronize do
		  configuration[host][:error] = "An error occurred: #{data}"
		end

		break
	      elsif stream == :stdout
		# We should have network cards details for processing already ...
		data.split("\n").each do |line|
		  # Remove bloat ...
		  line.strip!

		  # Skip new and empty lines ...
		  next if line.match(/^(\r\n|\n|\s*)$|^$/)

		  if line.match(DEFAULT_ILO_MAC_PATTERN)
		    address = line.split('=')[1]

		    mutex.synchronize do
		      configuration[host][:ilo] = address
		    end
		  elsif line.match(DEFAULT_ILO_NIC_PATTERN)
		    address = line.split('=')[1]

		    mutex.synchronize do
		      (configuration[host][:nics] ||= []) << address
		    end
		  else
		    # Skip irrelevant entries ...
		    next
		  end
		end
	      end
	    end
	  end
	end
      rescue Timeout::Error
      	configuration[host][:error] = 'Execution timed out'
      rescue Errno::ETIMEDOUT
      	configuration[host][:error] = 'Connection timed out'
      rescue Errno::EHOSTUNREACH
	configuration[host][:error] = 'Host unreachable'
      rescue => e
	configuration[host][:error] = "Unknown error: #{e.to_s}"
      end
    end
  end

  # Collect our little workers ...
  threads.each { |t| t.join }

  configuration.keys.sort_by { |i| i.scan(/\d+/).shift.to_i }.each do |host|
    details = configuration[host]

    puts "Host: #{host}"

    details.each do |k,v|
      if v.is_a?(Array)
	v.each_with_index do |entry,index|
	  puts "\tNetwork Card #{index + 1} MAC Address: #{entry}"
	end
      else
        case k
        when :ilo
          puts "\tiLO iLO MAC Address: #{v}"
        when :error
          puts "\tError: #{v}"
        end
      end
    end

    puts
  end
end

# vim: set ts=2 sw=2 et :
# encoding: utf-8
