require 'rubygems'
require './lookup_service.rb'

CgLookupService::App.set :run, false   # disable built-in sinatra web server
CgLookupService::App.set :environment, :development

run CgLookupService::App
