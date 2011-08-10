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
  puts "Configuring the lookup client..."
  CgLookupClient::Entry.configure_endpoint

  puts "\nFinding all role types..."
  role_types = CgRoleClient::RoleType.all
  puts role_types.size.to_s + " role types found."
  puts "Listing role types: "
  role_types.each do |role_type|
    puts role_type.role_name + " on " + role_type.target_type
  end

  role_type = role_types.first

  puts "\nFinding the activities for the " + role_type.role_name + " role type on " + role_type.target_type + "..."
  activities = role_types.first.activities
  puts activities.size.to_s + " activities found."
  puts "Listing the activities:"
  activities.each do |activity|
    puts activity.name
  end

  puts "\nCreating an actor..."
  actor = CgRoleClient::Actor.create({:actor_type => "CgUser::User", :actor_id => Time.now.to_i})
  puts "Actor " + actor.actor_type + " " + actor.actor_id.to_s + " created."

  loop do end
end

if __FILE__ == $0
  main
end