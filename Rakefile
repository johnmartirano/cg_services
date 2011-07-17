require 'rubygems'
require 'rspec/core/rake_task'

require(File.dirname(__FILE__) +
                  '/lib/cg_ervice_client.rb')

desc 'Default: run specs.'
task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "./spec/**/*_spec.rb"
end
