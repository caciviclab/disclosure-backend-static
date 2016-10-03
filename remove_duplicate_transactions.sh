#!/bin/bash
set -euo pipefail

# 1. delete duplicate A/497 contributions
cat <<-QUERY | psql disclosure-backend
DELETE FROM "efile_COAK_2016_497"
USING "efile_COAK_2016_A-Contributions" contributions
WHERE contributions."Filer_ID"::varchar = "efile_COAK_2016_497"."Filer_ID"::varchar
AND contributions."Tran_ID" = "efile_COAK_2016_497"."Tran_ID"
AND "efile_COAK_2016_497"."Form_Type" = 'F497P1';
QUERY

# 2. delete duplicate E/497 expenditures
cat <<-QUERY | psql disclosure-backend
DELETE FROM "efile_COAK_2016_497"
USING "efile_COAK_2016_E-Expenditure" expenditures
WHERE expenditures."Filer_ID"::varchar = "efile_COAK_2016_497"."Filer_ID"::varchar
AND expenditures."Tran_ID" = "efile_COAK_2016_497"."Tran_ID"
AND "efile_COAK_2016_497"."Form_Type" = 'F497P2';
QUERY
