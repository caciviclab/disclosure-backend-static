#!/bin/bash
set -euo pipefail

if [[ "$1" == "efile_COAK_2016_497" || "$1" == "efile_COAK_2016_496" ]]; then
  cat <<-QUERY | psql disclosure-backend
  DELETE FROM "$1" "outer"
  WHERE "Report_Num" < (
    SELECT MAX("Report_Num") FROM "$1" "inner"
      GROUP BY "Filer_ID", "Rpt_ID_Num"
      HAVING "outer"."Filer_ID" = "inner"."Filer_ID"
        AND "outer"."Rpt_ID_Num" = "inner"."Rpt_ID_Num"
    );
QUERY
else
  cat <<-QUERY | psql disclosure-backend
  DELETE FROM "$1" "outer"
  WHERE "Report_Num" < (
    SELECT MAX("Report_Num") FROM "$1" "inner"
      GROUP BY "Filer_ID", "From_Date"
      HAVING "outer"."Filer_ID" = "inner"."Filer_ID"
        AND "outer"."From_Date" = "inner"."From_Date"
    );
QUERY
fi
