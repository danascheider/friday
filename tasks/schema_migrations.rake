require 'mysql2'
require 'sequel'

DB ||= Sequel.connect(DatabaseTaskHelper.get_string(YAML_DATA['defaults'], 'defaults'))

namespace :db do 
  desc 'Create new migration, required arg NAME, default PATH /db/migrate'
  task :create_migration, [:NAME, :PATH] do |t, args|
    path = args[:path] || MIGRATION_PATH
    Dir.mkdir(path) unless Dir.exists?(path)

    File.open((name="#{path}/#{Time.now.getutc.to_s.gsub(/\D/, '')}_#{args[:NAME]}.rb"), 'w+') do |file|
      file.write <<-EOF
Sequel.migration do 
  up do
  end

  down do 
  end
end
EOF
    end
    puts "Migration created at #{path}/#{name}".green
  end

  namespace :schema do
    desc 'Load schema into database'
    task :load, :PATH do |t, args|
      DB.extension :schema_caching
      path = args[:path] || SCHEMA_PATH
      Rake::Task["db:migrate"].invoke(path)
      puts 'Success!'.green
    end

    desc 'Dump schema to a schema file'
    task :dump, [:PATH] => ['db:create'] do |t, args|
      timestamp = Time.now.getutc.to_s.gsub(/\D/, '')
      path      = args[:path] || SCHEMA_PATH

      DB.extension :schema_dumper
      schema = DB.dump_schema_migration
      bad    = /\s*create_table\(:schema(.*) do\s+\w+(.*)\s+(primary_key(.*))?\s+end/
      schema.gsub!(bad, '')

      File.open("#{path}/#{timestamp}_schema.rb", 'w+') {|file| file << schema }
    end
  end
end
