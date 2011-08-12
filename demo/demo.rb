#!/usr/bin/env ruby

# If running this from the command line, make sure your working directory is the demo directory,
# then run: ruby -I ../lib demo.rb

$: << File.expand_path(File.dirname(__FILE__) + '../../lib')

require 'cg_role_client'

# A mock work
module CgDocument
  class Work
    def id
      5
    end
  end
end

# Demonstrates how to use the role service client with a single endpoint.
# For this demo to work, you must first start up an instance of the lookup
# service on port 5000 as well as an instance of the role service
# on port 5200. Also, make sure rake db:seed has been run on the role service.
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

  puts "\nFinding an actor..."
  actor = CgRoleClient::Actor.find_by_actor_type_and_actor_id(actor.actor_type, actor.actor_id)
  puts "Actor " + actor.actor_type + " " + actor.actor_id.to_s + " found."

  puts "\nCreating another actor..."
  actor2 = CgRoleClient::Actor.create({:actor_type => "CgUser::User", :actor_id => Time.now.to_i+1})
  puts "Actor " + actor2.actor_type + " " + actor2.actor_id.to_s + " created."

  puts "\nCreating a group..."
  group = CgRoleClient::Group.create({:code => "test_group" + Time.now.to_i.to_s, :name => "Test group"})
  puts "Group " + group.code + " " + group.id.to_s + " created."
=begin
  puts "\nAdding actors to the group..."
  group = CgRoleClient::Group.create({:code => "test_group" + Time.now.to_i.to_s, :name => "Test group"})
  puts "Group " + group.code + " " + group.id.to_s + " created."
=end
  puts "\nCreating a target..."
  target = CgDocument::Work.new
  puts "Target " + target.class.to_s + " " + target.id.to_s + " created."

  puts "\nGranting a reviewer role to the actor for target " + target.class.to_s + " " + target.id.to_s + "..."
  role_type = CgRoleClient::RoleType.reviewer("CgDocument::Work")
  role = CgRoleClient::Role.grant(role_type,actor,target)
  puts "Granted role ID is " + role.id.to_s

  puts "\nFinding role for the actor on the previous target..."
  role = CgRoleClient::Role.aggregate_role(actor,target)
  puts "Aggregate role contains " + role.roles.size.to_s + " roles"
  puts "Testing if the role allows for read activity..."
  puts role.allows?(CgRoleClient::Activity.read)

end

if __FILE__ == $0
  main
end

