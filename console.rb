require 'active_record'
Dir.glob('models/*.rb').each { |f| load f }

ActiveRecord::Base.establish_connection 'postgresql:///disclosure-backend'

require 'pry'
binding.pry
