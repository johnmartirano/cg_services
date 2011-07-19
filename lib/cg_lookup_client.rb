# This first block is required for Ruby 1.8.7. Once we've upgraded to 1.9.x,
# it can be removed.
require 'rubygems'
gem 'rest-client', '=1.6.3'
gem 'activemodel', '=3.0.6'
gem 'activesupport', '=3.0.6'
gem 'activerecord', '=3.0.6'
#changed from 3.0.6
require 'cg_lookup_client/entry'
require 'cg_lookup_client/rest_endpoint'


