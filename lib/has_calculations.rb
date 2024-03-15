module HasCalculations
  extend ActiveSupport::Concern

  def calculation(name)
    @_calculations_cache ||= calculations.index_by(&:name)
    @_calculations_cache[name.to_s].try(:value)
  end

  def save_calculation(name, value)
    self.class.processed_calculations << name

    calculations
      .where(name: name)
      .first_or_create
      .update(value: value)
  end

  included do
    has_many :calculations, as: :subject

    cattr_accessor :processed_calculations do Set.new end
  end

  def round_numbers(obj)
    case obj
    when Hash
      obj.transform_values { |v| round_numbers(v) }
    when Array
      obj.map { |v| round_numbers(v) }
    when Float
      obj.round(2)
    else
      obj
    end
  end
end
