# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReferendumSupportersCalculator do
  describe 'calculating expenditures with duplicate transactions' do
    before do
      import_test_case('spec/fixtures/deduplicate_committee_expenses')

      OaklandCommittee.create(
        Filer_ID: '1400467',
        Filer_NamL: 'Protect Oakland Libraries - Yes on D 2018',
        Ballot_Measure: 'D',
        Support_Or_Oppose: 'S'
      )

      OaklandNameToNumber.create(
        election_name: 'oakland-june-2018',
        Measure_Name: 'Supporting a parcel tax measure for the Oakland Public Library on a 2018 ballot.',
        Measure_Number: 'D',
      )

      described_class.new(ballot_measures: [ballot_measure]).fetch
    end

    let(:ballot_measure) do
      OaklandReferendum.create(
        election_name: 'oakland-june-2018',
        Measure_number: 'D',
        Short_Title: 'Library Parcel Tax'
      )
    end

    subject { ballot_measure.calculation(:supporting_organizations) }

    it 'removes duplicate transactions but not non-duplicates' do
      expect(subject.length).to eq(1)

      calculation = subject[0]
      expect(calculation['amount']).to eq(136_952.89)
    end
  end
end
