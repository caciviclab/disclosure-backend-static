require 'active_record'
require 'json'

Dir.glob('models/*.rb').each { |f| load f }
Dir.glob('calculators/*.rb').each { |f| load f }

ActiveRecord::Base.establish_connection 'postgresql:///disclosure-backend'

class PrettyJSONEncoder < ActiveSupport::JSON::Encoding::JSONGemEncoder
  def stringify(jsonified)
    ::JSON.pretty_generate(jsonified, quirks_mode: true, max_nesting: false)
  end
end
ActiveSupport.json_encoder = PrettyJSONEncoder
