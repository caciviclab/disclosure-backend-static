require 'spec_helper'

RSpec.describe CandidateSupportingExpenditure do
  describe 'for Huber Trenado' do
    let(:huber_trenado) do
      OaklandCandidate.create(
        election_name: 'oakland-2016',
        Candidate: 'Huber Trenado',
        Committee_Name: 'Huber Trenado for OUSD School Board 2016',
        Accepted_expenditure_ceiling: 't',
        FPPC: '1386749',
        Office: 'School Board District 5',
        Incumbent: false
      )
    end

    let(:candidates) { [huber_trenado] }

    before do
      import_test_case('spec/fixtures/candidate_independent_supporting_trenado')
      described_class.new(candidates: candidates).fetch
    end

    subject { huber_trenado.calculation(:total_supporting_independent) }

    it 'calculates the correct value' do
      expect(subject).to eq(99_288.96)
    end
  end

  describe 'deduplicating 496 expenditures with 460 within a day of the deadline' do
    before do
      import_test_case('spec/fixtures/deduplicate_460_497_within_1_day_of_deadline')

      OaklandCommittee.create(
        Filer_ID: '1331137',
        Filer_NamL: 'FAMILIES AND EDUCATORS FOR PUBLIC EDUCATION, SPONSORED BY GREAT OAKLAND PUBLIC SCHOOLS',
      )

      described_class.new(candidates: [candidate]).fetch
    end

    let(:candidate) do
      OaklandCandidate.create(
        election_name: 'oakland-2018',
        Office: 'OUSD District 4',
        Candidate: 'Gary Yee',
        FPPC: '1409088',
        Incumbent: false,
        Accepted_expenditure_ceiling: false,
        Committee_Name: 'Gary Yee for Oakland School Board 2018',
        Aliases: 'Gary D Yee',
      )
    end

    subject { candidate.calculation(:support_list).first }

    it 'does not duplicate between 460 and 496' do
      expect(subject['Total']).to eq(56_394.73)
    end
  end
end
