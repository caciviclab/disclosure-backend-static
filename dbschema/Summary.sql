CREATE TABLE "Summary" (
	"Filer_ID" VARCHAR(9), 
	"Filer_NamL" VARCHAR, 
	"Report_Num" VARCHAR(3) NOT NULL, 
	"Committee_Type" VARCHAR(3) NOT NULL, 
	"Rpt_Date" DATE NOT NULL, 
	"From_Date" DATE NOT NULL, 
	"Thru_Date" DATE NOT NULL, 
	"Elect_Date" DATE, 
	"tblCover_Office_Cd" VARCHAR, 
	"tblCover_Offic_Dscr" VARCHAR, 
	"Rec_Type" VARCHAR(4), 
	"Form_Type" VARCHAR(4) NOT NULL, 
	"Line_Item" VARCHAR(3) NOT NULL, 
	"Amount_A" FLOAT, 
	"Amount_B" FLOAT, 
	"Amount_C" FLOAT
);
