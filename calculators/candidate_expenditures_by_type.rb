class CandidateExpendituresByType
  TYPE_DESCRIPTIONS = {
    'CMP' => 'campaign paraphernalia/misc.',
    'CNS' => 'campaign consultants',
    'CTB' => 'contribution',
    'CVC' => 'civic donations',
    'FIL' => 'candidate filing/ballot fees',
    'FND' => 'fundraising events',
    'IND' => 'independent expenditure supporting/opposing others',
    'LEG' => 'legal defense',
    'LIT' => 'campaign literature and mailings',
    'MBR' => 'member communications',
    'MTG' => 'meetings and appearances',
    'OFC' => 'office expenses',
    'PET' => 'petition circulating',
    'PHO' => 'phone banks',
    'POL' => 'polling and survey research',
    'POS' => 'postage, delivery and messenger services',
    'PRO' => 'professional services (legal, accounting)',
    'PRT' => 'print ads',
    'RAD' => 'radio airtime and production costs',
    'RFD' => 'returned contributions',
    'SAL' => 'campaign workers\' salaries',
    'TEL' => 't.v. or cable airtime and production costs',
    'TRC' => 'candidate travel, lodging, and meals',
    'TRS' => 'staff/spouse travel, lodging, and meals',
    'TSF' => 'transfer between committees of the same candidate/sponsor',
    'VOT' => 'voter registration',
    'WEB' => 'information technology costs (internet, e-mail)',
    '' => 'Not Stated'
  }

  def initialize(candidates: [], ballot_measures: [])
    @candidates_by_filer_id =
      candidates.where('"FPPC" IS NOT NULL').index_by { |c| c.FPPC }
  end

  def fetch
    # normalization: replace three-letter names with TYPE_DESCRIPTIONS
    TYPE_DESCRIPTIONS.each do |short_name, human_name|
      expenditures_by_candidate_by_type.each do |filer_id, expenditures_by_type|
        if value = expenditures_by_type.delete(short_name)
          expenditures_by_type[human_name] = value
        end
      end
    end

    # save!
    expenditures_by_candidate_by_type.each do |filer_id, expenditures_by_type|
      candidate = @candidates_by_filer_id[filer_id.to_i]
      candidate.save_calculation(:expenditures_by_type, expenditures_by_type)
    end
  end

  private

  def expenditures_by_candidate_by_type
    @_expenditures_by_candidate_by_type ||= {}.tap do |hash|
      results = ActiveRecord::Base.connection.execute <<-SQL
        SELECT "Filer_ID", "Expn_Code", SUM("Amount") AS "Total"
        FROM "efile_COAK_2016_E-Expenditure"
        WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "','"}')
        GROUP BY "Expn_Code", "Filer_ID";
      SQL

      results.each do |result|
        hash[result['Filer_ID']] ||= {}
        hash[result['Filer_ID']][result['Entity_Cd']] = result['Total']
      end
    end
  end

end
