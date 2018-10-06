# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TotalContributionsCalculator do
  let(:cat_brooks) do
    OaklandCandidate.create(
      election_name: 'oakland-2018',
      Candidate: 'Cat Brooks',
      Committee_Name: 'Sheilagh Polk “Cat Brooks” for Mayor 2018',
      FPPC: '1405474',
      Office: 'Mayor',
      Incumbent: 'f',
    )
  end

  before do
    import_test_case('spec/fixtures/amendment_with_null_filer_id')

    described_class.new(candidates: [cat_brooks]).fetch
  end

  subject { cat_brooks.calculation(:total_contributions) }

  it 'deduplicates properly' do
    expect(subject).to eq(49_932.42)
  end
end
