psql disclosure-backend << SQL
/*
** View to capture all expenditures for ballot measures.
** Some committees formed to support/oppose a measure do
** do not report their expenditures ass supporting/opposing
** The measure
*/
CREATE OR REPLACE VIEW "Measure_Expenditures" AS
  -- Map names to numbers as ballot numbers are often missing
  SELECT "Filer_ID"::varchar, "Filer_NamL",
    "Bal_Name", "Measure_Number", "Sup_Opp_Cd", "Amount"
  FROM
    "E-Expenditure", oakland_name_to_number
  WHERE LOWER("Bal_Name") = LOWER("Measure_Name")
  UNION ALL

  -- Get IE 
  SELECT "Filer_ID"::varchar, "Filer_NamL",
    "Bal_Name", "Measure_Number", "Sup_Opp_Cd", "Amount"
  FROM
    "496", oakland_name_to_number
  WHERE LOWER("Bal_Name") = LOWER("Measure_Name")
  AND "Sup_Opp_Cd" IS NOT NULL
  UNION ALL

  -- Get support/oppose information from committee
  SELECT expend."Filer_ID"::varchar, expend."Filer_NamL",
    "Bal_Name",
    "Ballot_Measure" as "Measure_Number",
    "Support_Or_Oppose" as "Sup_Opp_Cd", "Amount"
  FROM
    "E-Expenditure" expend,
    oakland_committees committee
  WHERE "Bal_Name" IS NULL
    AND expend."Filer_ID" = committee."Filer_ID"
    AND "Ballot_Measure" IS NOT NULL
  UNION ALL

  -- Get 24hr report expenditures. There is no S/O information!
  SELECT "Filer_ID"::varchar, "Filer_NamL",
    "Bal_Name", "Measure_Number", 'Unknown' as "Sup_Opp_Cd", "Amount"
  FROM "497" LEFT OUTER JOIN "oakland_name_to_number"
  ON LOWER("Bal_Name") = LOWER("Measure_Name")
  WHERE "Bal_Name" IS NOT NULL
  AND "Form_Type" = 'F497P2';
SQL
