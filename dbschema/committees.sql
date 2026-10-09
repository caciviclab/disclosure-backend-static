CREATE TABLE committees (
	"Ballot_Measure_Election" VARCHAR, 
	"Filer_ID" VARCHAR NOT NULL, 
	"Filer_NamL" VARCHAR NOT NULL, 
	"_Status" VARCHAR, 
	"_Committee_Type" VARCHAR(11), 
	"Ballot_Measure" VARCHAR(10), 
	"Support_Or_Oppose" VARCHAR(4), 
  "Cand_ID" INTEGER,
	candidate_controlled_id INTEGER, 
	"Start_Date" DATE, 
	"End_Date" DATE, 
	data_warning VARCHAR,
	"Make_Active" BOOLEAN
);
