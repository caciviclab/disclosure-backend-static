# This is jank.
def import_test_case(path)
  raise "Directory does not exist: #{path}" unless File.directory?(path)

  database_name = 'disclosure-backend-test'

  # reset db
  `env DATABASE_NAME=#{database_name} make recreatedb`
  raise "Test setup failed. You might need to install the `build-essential` package." unless $?.success?

  # copy over schema
  puts 'Copying over schema...'
  `pg_dump --clean --if-exists --no-owner --schema-only disclosure-backend | psql #{database_name}`
  raise "Test setup failed. You might need to install Postgresql command line binaries." unless $?.success?

  # import tables
  puts "Importing test case in #{path}..."
  `env CSV_PATH=#{path} DATABASE_NAME=#{database_name} make import-data`
  raise "Test setup failed. You might need to install python dependencies." unless $?.success?

  ActiveRecord::Base.establish_connection "postgresql:///#{database_name}"
end
