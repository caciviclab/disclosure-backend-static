# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CandidateOpposingExpenditure do
  describe 'For 2016 candidate Dan Kalb' do
    let(:dan_kalb) do
      Candidate.create(
        election_name: 'oakland-2016',
        Candidate: 'Dan Kalb',
        Committee_Name: 'Re-Elect Dan Kalb Oakland City Council 2016',
        FPPC: '1382408',
        Office: 'City Council District 1',
        Incumbent: 't',
      )
    end

    let(:candidates) { [dan_kalb] }

    before do
      import_test_case('spec/fixtures/candidate_independent_supporting_kalb')
      CandidateOpposingExpenditure.new(candidates: candidates).fetch
    end

    subject { dan_kalb.calculation(:total_opposing) }

    it 'calculates the correct value' do
      # Note that this should include only IND expenditures, not IKD or MON.
      expect(subject).to eq(13_241.65)
    end
  end
end
