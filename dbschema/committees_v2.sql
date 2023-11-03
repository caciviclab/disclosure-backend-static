CREATE TABLE committees_v2 (
	filer_nid DECIMAL NOT NULL, 
	"Ballot_Measure_Election" VARCHAR, 
	"Filer_ID" VARCHAR, 
	"Filer_NamL" VARCHAR NOT NULL, 
	"_Status" VARCHAR NOT NULL, 
	"_Committee_Type" VARCHAR NOT NULL, 
	"Ballot_Measure" VARCHAR, 
	"Support_Or_Oppose" VARCHAR, 
	candidate_controlled_id BOOLEAN, 
	"Start_Date" DATE, 
	"End_Date" BOOLEAN, 
	data_warning BOOLEAN, 
	"Make_Active" BOOLEAN
);
