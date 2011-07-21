# This first block is required for Ruby 1.8.7. Once we've upgraded to 1.9.x,
# it can be removed.
require 'rubygems'

gem 'typhoeus', '>=0.2.4'
gem 'cg_lookup_client', '>=0.5.0'

require 'cg_service_client/exceptions.rb'
require 'cg_service_client/rest_endpoint'


