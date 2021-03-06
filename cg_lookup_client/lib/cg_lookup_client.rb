# This first block is required for Ruby 1.8.7. Once we've upgraded to 1.9.x,
# it can be removed.
require 'rubygems'
require 'cg_lookup_client/caching_endpoint_set'
require 'cg_lookup_client/entry'
require 'cg_lookup_client/rest_endpoint'
require 'cg_lookup_client/uri_with_version'

# Setup a globally shared CachingEndpointSet.
module CgLookupClient
  ENDPOINTS = CachingEndpointSet.new
end
