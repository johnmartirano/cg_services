#!/usr/bin/env ruby

$: << File.expand_path(File.dirname(__FILE__) + '../../lib')

require 'cg_lookup_client'

# Demonstrates how to use the lookup service client with a single endpoint.
# For this demo to work, you must first start up two instances of the lookup
# service, one on port 5000 (the default port) and one on port 5001.
def main

  puts "Configuring a default endpoint on port 5000..."
  CgLookupClient::Entry.configure_endpoint

  puts "Creating a new Entry instance..."
  entry = CgLookupClient::Entry.new(
      {:type_name=>"Notification",
       :description=>"Sinatra Notification Service",
       :uri=>"http://localhost:5100/",
       :version=>"1"})

  puts "Registering the new Entry without a callback block..."
  entry.register

  puts "Waiting a minute for the Entry to be renewed..."
  sleep 60


  puts "\n\nCreating a second Entry instance..."
  entry = CgLookupClient::Entry.new(
      {:type_name=>"Request",
       :description=>"Java Request Service",
       :uri=>"http://localhost:5200/",
       :version=>"1"})

  puts "Registering the second Entry with a callback..."
  entry.register do |update|
    puts "Entry ID: " + update[:id].to_s
    puts "Endpoint: " + update[:endpoint].to_s
    puts "Success: " + update[:success].to_s
    puts "Message: " + update[:message].to_s
  end


  puts "Waiting a minute for the Entry to be renewed..."
  sleep 60


  puts "\n\nLooking up Entries of type Notification."
  result = CgLookupClient::Entry.lookup("Notification","1")
  puts "Got " + result["entry"].to_s


  puts "\n\nConfiguring a second endpoint on port 5001..."
  endpoint = CgLookupClient::RestEndpoint.new("http://localhost:5001","1")
  CgLookupClient::Entry.configure_endpoint(endpoint)

  puts "Waiting a minute for Entries to be registered on all endpoints..."
  sleep 60

  loop do end
end

if __FILE__ == $0
  main
end