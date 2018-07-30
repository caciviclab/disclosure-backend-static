# This is jank.
def import_test_case(path)
  raise "Directory does not exist: #{path}" unless File.directory?(path)

  database_name = 'disclosure-backend-test'

  # reset db
  `env DATABASE_NAME=#{database_name} make dropdb createdb`

  # copy over schema
  puts 'Copying over schema...'
  `pg_dump --clean --if-exists --no-owner --schema-only disclosure-backend | psql #{database_name}`

  # import tables
  puts "Importing test case in #{path}..."
  `env CSV_PATH=#{path} DATABASE_NAME=#{database_name} make import-data`

  ActiveRecord::Base.establish_connection "postgresql:///#{database_name}"
end
