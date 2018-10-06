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
      expect(calculation['amount']).to eq(145_418.42)
    end
  end

  describe 'including committees that have raised, but not spent, money' do
    before do
      import_test_case('spec/fixtures/referendum_supporters_without_expenditures_are_included')

      OaklandCommittee.create(
        Filer_ID: '1410941',
        Filer_NamL: 'Committee for Better Choices, No on Measure AA',
        Ballot_Measure: 'AA',
        Ballot_Measure_Election: 'oakland-2018',
        Support_Or_Oppose: 'O'
      )

      described_class.new(ballot_measures: [ballot_measure]).fetch
    end

    let(:ballot_measure) do
      OaklandReferendum.create(
        election_name: 'oakland-2018',
        Measure_number: 'AA',
        Short_Title: "Oakland Children's Initiative",
      )
    end

    subject { ballot_measure.calculation(:opposing_organizations) }

    it 'includes the committee in the supporters list' do
      expect(subject).to_not be_empty
      expect(subject).to include(hash_including('name' => 'Committee for Better Choices, No on Measure AA'))
    end
  end
end
