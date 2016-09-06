require 'active_record'
Dir.glob('models/*.rb').each { |f| load f }
Dir.glob('calculators/*.rb').each { |f| load f }

ActiveRecord::Base.establish_connection 'postgresql:///disclosure-backend'
