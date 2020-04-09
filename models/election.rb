class Election < ActiveRecord::Base
  has_many :calculations, as: :subject

  def calculation(name)
    @_calculations_cache ||= calculations.index_by(&:name)
    @_calculations_cache[name.to_s].try(:value)
  end

  def save_calculation(name, value)
    calculations
      .where(name: name)
      .first_or_create
      .update_attributes(value: value)
  end

  def as_json(options = nil)
    {
      'total_contributions_by_source' => {
        'From Within Oakland' => 0.55,
        'In-State' => 0.055,
        'Out of State' => 0.05,
      },
      'top_spenders' => [
        {
          'name' => 'Jeff Bezos',
          'total_contributions' => 555,
          'contribution_year' => 2017,
        },
        {
          'name' => 'Elon Musk',
          'total_contributions' => 55,
          'contribution_year' => 2017,
        },
        {
          'name' => 'Travis Kalanick',
          'total_contributions' => 5,
          'contribution_year' => 2017,
        },
      ],
      'candidates_with_most_small_contributions' => [
        {
          'name' => 'Zhao Liu',
          'office_title' => 'Mayor of Oakland',
          'small_contribution_percent' => 0.55,
        },
        {
          'name' => 'Sally Trotski',
          'office_title' => 'City Council District 1',
          'small_contribution_percent' => 0.55,
        },
        {
          'name' => 'Peter San Marco',
          'office_title' => 'City Council District 1',
          'small_contribution_percent' => 0.55,
        },
      ],
      'contributions_by_type' => {
        "Committee" => 55_555.55,
        "Individual" => 5_555.55,
        "Unitemized" => 5_550.55,
        "Self Funding" => 5_500.55,
        "Other (includes businesses)" => 5_000.55,
      }
    }
  end
end
