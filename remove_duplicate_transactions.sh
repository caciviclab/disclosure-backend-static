#!/bin/bash
set -euo pipefail

# 1. delete duplicate A/497 contributions
cat <<-QUERY | psql disclosure-backend
DELETE FROM "efile_COAK_2016_497" late
WHERE EXISTS (
  SELECT * FROM "efile_COAK_2016_A-Contributions" contributions
      WHERE contributions."Filer_ID"::varchar = late."Filer_ID" AND late."Rpt_Date" < contributions."Rpt_Date");
QUERY
