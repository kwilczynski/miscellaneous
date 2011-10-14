#!/usr/bin/env ruby

#
# mysql_show_slave_status.rb
#
# This script allows for querying multiple databases for their replication status.
#

require 'thread'
require 'rubygems'

require 'mysql'

# Authentication details ...
DATABASE_USER     = 'user'
DATABASE_PASSWORD = 'passsword'

# Name of the database ...
DATABASE_NAME     = 'database'

# A default statement to check replication status ...
QUERY_STRING = 'SHOW SLAVE STATUS'

# List of database hosts of interest ...
hosts = %w(host-a host-b host-c)

threads = []

hosts.each do |host|
  # Concatenate to create fully qualified domain name ...
  host = "#{host}.domain.name"

  threads << Thread.new(host) do |h|
    my = Mysql.new(h, DATABASE_USER, DATABASE_PASSWORD, DATABASE_NAME)

    result = my.query(QUERY_STRING)

    # This should never have place ...
    if result.num_rows > 0
      result = result.fetch_hash
    else
      puts 'Replication status not available?  Aborting ...'
      exit 1
    end

    Thread.exclusive do
      result = sprintf("Slave_IO_Running = %s, Slave_SQL_Running = %s, " +
                       "Seconds_Behind_Master = %i, Read_Master_Log_Pos = %i, " +
                       "Relay_Log_Pos = %i, Exec_Master_Log_Pos = %i ",
                       result['Slave_IO_Running'], result['Slave_SQL_Running'],
                       result['Seconds_Behind_Master'], result['Read_Master_Log_Pos'],
                       result['Relay_Log_Pos'], result['Exec_Master_Log_Pos'])

      puts "#{h}: #{result}"
    end
  end

end

# Collect our little workers ...
threads.each { |t| t.join }

# vim: set ts=2 sw=2 et :
# encoding: utf-8
