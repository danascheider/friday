require 'cucumber/rake/task'
require 'rspec/core/rake_task'
require 'colorize'
require './tasks/database_task_helper'
require './canto'

Dir.glob('tasks/*.rake').each {|file| load file }

MIGRATION_PATH = File.expand_path('../db/migrate', __FILE__)
SCHEMA_PATH    = File.expand_path('../db/schema_migrations', __FILE__)
YAML_DATA      = DatabaseTaskHelper.get_yaml(File.expand_path('config/database.yml'))

Cucumber::Rake::Task.new
RSpec::Core::RakeTask.new

task 'suite:run' do 
  Rake::Task[:spec].invoke
  Rake::Task['db:test:prepare'].invoke
  Rake::Task[:cucumber].invoke
end

task :default => [:all]

desc "Run all tests."
task :all => [
  'suite:run'
]