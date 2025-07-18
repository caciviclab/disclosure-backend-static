CREATE TABLE "I-Contributions" (
	"Filer_ID" VARCHAR(7) NOT NULL, 
	"Filer_NamL" VARCHAR(183) NOT NULL, 
	"Report_Num" VARCHAR(3) NOT NULL, 
	"Committee_Type" VARCHAR(3) NOT NULL, 
	"Rpt_Date" DATE NOT NULL, 
	"From_Date" DATE NOT NULL, 
	"Thru_Date" DATE NOT NULL, 
	"Elect_Date" DATE, 
	"tblCover_Office_Cd" VARCHAR(32), 
	"tblCover_Offic_Dscr" VARCHAR(32), 
	"Rec_Type" VARCHAR(4) NOT NULL, 
	"Form_Type" VARCHAR(1) NOT NULL, 
	"Tran_ID" VARCHAR(12) NOT NULL, 
	"Entity_Cd" VARCHAR(3) NOT NULL, 
	"Tran_NamL" VARCHAR(99) NOT NULL, 
	"Tran_NamF" VARCHAR(16), 
	"Tran_NamT" VARCHAR(4), 
	"Tran_NamS" VARCHAR(32), 
	"Tran_Adr1" VARCHAR(32), 
	"Tran_Adr2" VARCHAR(32), 
	"Tran_City" VARCHAR(16), 
	"Tran_State" VARCHAR(4), 
	"Tran_Zip4" VARCHAR(10), 
	"Tran_Emp" VARCHAR(53), 
	"Tran_Occ" VARCHAR(41), 
	"Tran_Self" BOOLEAN NOT NULL, 
	"Tran_Type" VARCHAR(32), 
	"Tran_Date" DATE NOT NULL, 
	"Tran_Date1" VARCHAR(32), 
	"Tran_Amt1" FLOAT NOT NULL, 
	"Tran_Amt2" FLOAT, 
	"Tran_Dscr" VARCHAR(87), 
	"Cmte_ID" INTEGER, 
	"Tres_NamL" VARCHAR(32), 
	"Tres_NamF" VARCHAR(32), 
	"Tres_NamT" VARCHAR(32), 
	"Tres_NamS" VARCHAR(32), 
	"Tres_Adr1" VARCHAR(32), 
	"Tres_Adr2" VARCHAR(32), 
	"Tres_City" VARCHAR(32), 
	"Tres_State" VARCHAR(4), 
	"Tres_Zip" VARCHAR(10), 
	"Intr_NamL" VARCHAR(32), 
	"Intr_NamF" VARCHAR(32), 
	"Intr_NamT" VARCHAR(32), 
	"Intr_NamS" VARCHAR(32), 
	"Intr_Adr1" VARCHAR(32), 
	"Intr_Adr2" VARCHAR(32), 
	"Intr_City" VARCHAR(32), 
	"Intr_State" VARCHAR(32), 
	"Intr_Zip4" VARCHAR(32), 
	"Intr_Emp" VARCHAR(32), 
	"Intr_Occ" VARCHAR(32), 
	"Intr_Self" BOOLEAN NOT NULL, 
	"Cand_NamL" VARCHAR(32), 
	"Cand_NamF" VARCHAR(32), 
	"Cand_NamT" VARCHAR(32), 
	"Cand_NamS" VARCHAR(32), 
	"tblDetlTran_Office_Cd" VARCHAR(32), 
	"tblDetlTran_Offic_Dscr" VARCHAR(32), 
	"Juris_Cd" VARCHAR(32), 
	"Juris_Dscr" VARCHAR(32), 
	"Dist_No" VARCHAR(32), 
	"Off_S_H_Cd" VARCHAR(32), 
	"Bal_Name" VARCHAR(32), 
	"Bal_Num" VARCHAR(32), 
	"Bal_Juris" VARCHAR(32), 
	"Sup_Opp_Cd" VARCHAR(32), 
	"Memo_Code" VARCHAR(32), 
	"Memo_RefNo" VARCHAR(11), 
	"BakRef_TID" VARCHAR(32), 
	"XRef_SchNm" VARCHAR(32), 
	"XRef_Match" VARCHAR(32), 
	"Loan_Rate" VARCHAR(32), 
	"Int_CmteId" VARCHAR(16)
);
