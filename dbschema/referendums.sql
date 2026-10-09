CREATE TABLE referendums (
	election_name VARCHAR NOT NULL, 
	"Measure_number" VARCHAR(4) NOT NULL, 
	"Short_Title" VARCHAR NOT NULL, 
	"Full_Title" VARCHAR, 
	"Summary" VARCHAR, 
	"VotersEdge" VARCHAR, 
	"Internal_notes" VARCHAR, 
	data_warning VARCHAR, 
	is_approved BOOLEAN
);
