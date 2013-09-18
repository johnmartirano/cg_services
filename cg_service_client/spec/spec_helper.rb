ENV["RAILS_ENV"] = 'test'

# Add lib directory to load path
$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
 
require 'rspec'
