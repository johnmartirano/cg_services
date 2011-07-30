require 'rubygems'
require 'active_record'
require 'yaml'
require 'logger'
require 'rspec/core/rake_task'


def connect_to_db(config)
  ActiveRecord::Base.establish_connection config
  ActiveRecord::Base.logger = Logger.new STDOUT
end

def create_db(config)
  options = {:charset => 'utf8', :collation => 'utf8_unicode_ci'}

  connect_to_db(config.merge('database' => 'postgres', 'schema_search_path' => 'public'))
  ActiveRecord::Base.connection.create_database config['database'], options
  connect_to_db(config)
end

# Note: Not currently using the grant_privileges code, but it does work.
# Our documented privilege granting process may not be necessary anymore.
# Susan's comments indicate it was necessary for migrations via capistrano deployment.
# According to that process the DB would be created by postgres user, then the
# development user granted privileges, then the database dropped.  The privileges
# were then persisted in the user model.
def grant_privileges(config)
  print "Please provide the root password for your db installation\n>"
  postgres_password = $stdin.gets.strip

  create_db(config.merge('database' => config['database'], 'username' => 'postgres', 'password' => postgres_password))

  grant_statement = <<-SQL
GRANT ALL ON DATABASE #{config['database']}
TO "#{config['username']}" WITH GRANT OPTION;
SQL

  ActiveRecord::Base.connection.execute grant_statement
  #ActiveRecord::Base.connection.drop_database config['database']
end


def setup_db(config)
  begin
    create_db(config)
  rescue StandardError => err
    if defined? PGError && err.class == PGError
      print ">>PGError: #{err}.\n"
      #TODO: if we need to implement the privilege granting process
      #      then everything below will require another look.
      #grant_privileges(config)
      #create_db(config)
    else
      $stderr.puts err.inspect
      $stderr.puts "Couldn't create database for #{config.inspect}, charset: utf8, collation: utf8_unicode_ci"
      $stderr.puts "(if you set the charset manually, make sure you have a matching collation)" if config['charset']
    end
  end
end


namespace :db do

  task :environment do
    DATABASE_ENV = ENV['SINATRA_ENV'] || 'development'
    MIGRATIONS_DIR = 'db/migrate'
  end

  task :configuration => :environment do
    @config = YAML.load_file('config/database.yml')[DATABASE_ENV]
  end

  # Connect to the database indicated in the config file database.yml 
  task :configure_connection => :configuration do
	connect_to_db(@config)
  end

  # Connect to the postgres (ie root) database in order to drop another database.
  task :configure_connection_to_root_db => :configuration do
	connect_to_db(@config.merge('database' => 'postgres', 'schema_search_path' => 'public'))
  end

  desc 'Create the database from config/database.yml for the current DATABASE_ENV'
  task :create => :configure_connection do
    if @config['adapter'] == 'sqlite3'
      puts "db:create not supported by the active_record connection adapter for sqlite3.\n"
	  puts "Instead, database created at #{@config['database']}"
	else
      setup_db @config
	end
  end

  desc 'Drops the database for the current DATABASE_ENV'
  task :drop => :configure_connection_to_root_db do
    if @config['adapter'] == 'sqlite3'
      puts "db:drop not supported by the active_record connection adapter for sqlite3.\n" 
	  puts 'Deleting instead:  rm '+ @config['database']
      system 'rm '+ @config['database']
    else #Postgres and Mysql should be supported
      ActiveRecord::Base.connection.drop_database @config['database']
    end
  end

  desc 'Migrate the database (options: VERSION=x, VERBOSE=false).'
  task :migrate => :configure_connection do
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate MIGRATIONS_DIR, ENV['VERSION'] ? ENV['VERSION'].to_i : nil
  end

  desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n).'
  task :rollback => :configure_connection do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    ActiveRecord::Migrator.rollback MIGRATIONS_DIR, step
  end

  desc 'Load the seed data from db/seeds.rb'
  task :seed => :configure_connection do
    seed_file = File.join(File.dirname(@service_file), 'db', 'seeds.rb')
    load(seed_file) if File.exist?(seed_file)
  end

end


# Our test environment uses sqlite3 which does not support create_database 
# nor drop_database.  The database is created when you establish a connection
# with the adaptor.  It is dropped by removing the created file below.
desc 'Prepare to run spec tests.'
task :prepare_test do
  ENV['SINATRA_ENV'] = 'test' 
  Rake::Task['db:drop'].invoke
  Rake::Task['db:create'].invoke
  Rake::Task['db:migrate'].invoke
  Rake::Task['db:seed'].invoke
end

desc "Run specs"
task :spec => :prepare_test do
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
    # Put spec opts in a file named .rspec in root
  end
end

desc "Generate code coverage"
RSpec::Core::RakeTask.new(:coverage) do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end

