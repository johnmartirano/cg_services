source 'http://rubygems.org'
source 'http://build.commongroundpublishing.com/gems'

gemspec

group :development, :test do
  gem 'rake', '= 0.8.7'         # for compatibility with other cg
                                # stuff and to avoid bundler
                                # NP-forever
  gem 'tux'
  gem 'sqlite3', :require => 'sqlite3'
end

group :test do
  gem 'rspec', '>=2.6.0'
  gem 'rack-test', '=0.5.6'
  gem 'ruby-debug-base19x'
  gem 'ruby-debug-ide'
end

