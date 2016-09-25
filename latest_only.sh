cat <<-QUERY | psql disclosure-backend
DELETE FROM "$1" "outer"
WHERE "Report_Num" < (
  SELECT MAX("Report_Num") FROM "$1" "inner"
    GROUP BY "Filer_ID", "From_Date"
    HAVING "outer"."Filer_ID" = "inner"."Filer_ID"
       AND "outer"."From_Date" = "inner"."From_Date"
  );
QUERY
