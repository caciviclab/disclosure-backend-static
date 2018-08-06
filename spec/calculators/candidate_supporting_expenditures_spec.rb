require 'spec_helper'

RSpec.describe CandidateSupportingExpenditure do
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
    expect(subject).to eq(99_288.96) # Is this value right? It doesn't agree with Suzanne.
  end
end
