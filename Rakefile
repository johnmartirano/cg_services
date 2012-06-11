require 'rubygems'

# Allows you to run rake tasks without bundle exec, we do it here instead
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'cg_service'

CgService::RakeLoader.load_tasks!

load 'cg_tasks/deploy_jruby.rake'

