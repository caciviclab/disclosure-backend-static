class Committee < ActiveRecord::Base
  include HasCalculations

  def self.from_candidate(candidate)
    new(
      Filer_ID: candidate.FPPC,
      Filer_NamL: candidate.Committee_Name,
      candidate_controlled_id: '',
      data_warning: candidate.data_warning,
    )
  end

  def metadata
    {
      'filer_id' => self[:Filer_ID].to_s,
      'name' => self[:Filer_NamL],
      'candidate_controlled_id' => candidate_controlled_id.to_s,
      'data_warning' => data_warning,
      'title' => self[:Filer_NamL],
    }
  end

  # Keep this method in-sync with the `committe_data` method in Candidate model.
  def data
    {
      iec: true,
      total_contributions: calculation(:contribution_list_total),
      contributions: calculation(:contribution_list) || [],
    }
  end
end
