# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReferendumContributionsByOrigin do
  before do
    import_test_case('spec/fixtures/referendum_contributions_by_origin')

    # these committees need to be created before the test is run, but after the
    # test case is imported
    OaklandCommittee.create(
      Filer_ID: '1385949',
      Filer_NamL: 'Causa Justa :: Just Cause (nonprofit 501(c)(3))',
      Ballot_Measure: 'JJ',
      Support_Or_Oppose: 'S'
    )
    OaklandCommittee.create(
      Filer_ID: '1364564',
      Filer_NamL: 'Committee to Protect Oakland Renters - Yes on Measure JJ, sponsored by labor and community organizations',
      Ballot_Measure: 'JJ',
      Support_Or_Oppose: 'S'
    )

    described_class.new(ballot_measures: [ballot_measure]).fetch
  end

  let(:ballot_measure) do
    OaklandReferendum.create(
      election_name: 'oakland-2016',
      Measure_number: 'JJ',
      Short_Title: 'Just Cause for Eviction and Rent Adjustment'
    )
  end

  describe 'total calculation' do
    subject { ballot_measure.calculation(:supporting_total) }

    it 'aggregates together multiple supporting committees' do
      expect(subject).to be_within(1).of(477_720)
    end
  end

  describe 'supporting_locales calculation' do
    subject { ballot_measure.calculation(:supporting_locales) }

    it 'aggregates together multiple supporting committees' do
      expect(subject).to include(hash_including('locale' => 'Out of State'))
      expect(subject).to include(hash_including('locale' => 'Within California'))
      expect(subject).to include(hash_including('locale' => 'Within Oakland'))

      amounts_by_locale = Hash[subject.map { |l| [l['locale'], l['amount']] }]

      expect(amounts_by_locale['Out of State'])
        .to be_within(1).of(29_200)

      expect(amounts_by_locale['Within California'])
        .to be_within(1).of(123_760.65)

      expect(amounts_by_locale['Within Oakland'])
        .to be_within(1).of(324_759.16)
    end
  end
end
