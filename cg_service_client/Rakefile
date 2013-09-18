require 'rubygems'
require 'rspec/core/rake_task'

$: << File.expand_path(File.dirname(__FILE__) + '../../lib')

require 'cg_service_client'

desc 'Default: run specs.'
task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "./spec/**/*_spec.rb"
end
