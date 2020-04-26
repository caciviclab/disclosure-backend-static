# frozen_string_literal: true

require 'active_support/concern'
require 'active_record'
require 'json'

Dir.glob('lib/**/*.rb').each { |f| load f }
Dir.glob('models/*.rb').each { |f| load f }
Dir.glob('calculators/*/*.rb').each { |f| load f }

ActiveRecord::Base.establish_connection 'postgresql:///disclosure-backend'

# Output JSON in a human readable format, since we're not trying to save on
# bytes on the wire.
class PrettyJSONEncoder < ActiveSupport::JSON::Encoding::JSONGemEncoder
  def stringify(jsonified)
    ::JSON.pretty_generate(jsonified, quirks_mode: true, max_nesting: false)
  end
end
ActiveSupport.json_encoder = PrettyJSONEncoder
