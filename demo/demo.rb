#!/usr/bin/env ruby

# If running this from the command line, make sure your working directory is the demo directory,
# then run: ruby -I ../lib demo.rb

$: << File.expand_path(File.dirname(__FILE__) + '../../lib')

require 'cg_role_client'

# Demonstrates how to use the role service client with a single endpoint.
# For this demo to work, you must first start up an instance of the lookup
# service on port 5000 as well as an instance of the role service
# on port 5200.
def main

  # Ordinarily this would be done in application initializer code.
  puts "Configuring the lookup client...\n\n"
  CgLookupClient::Entry.configure_endpoint

  puts "Finding all role types..."
  role_types = CgRoleClient::RoleType.all


  loop do end
end

if __FILE__ == $0
  main
end