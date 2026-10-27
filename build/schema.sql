--
-- PostgreSQL database dump
--

\restrict ZCaRcQhWRhOcim2tJyvcyJ59rLcLvq4ArqH850yBu1L1YrKAhPbZzYB6Oxn9aEy

-- Dumped from database version 14.19 (Ubuntu 14.19-1.pgdg22.04+1)
-- Dumped by pg_dump version 14.19 (Ubuntu 14.19-1.pgdg22.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: 496; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public."496" (
    "Filer_ID" character varying(9) NOT NULL,
    "Filer_NamL" character varying,
    "Report_Num" character varying(3) NOT NULL,
    "Committee_Type" character varying(4),
    "Rpt_Date" date NOT NULL,
    "From_Date" date,
    "Thru_Date" date,
    "Elect_Date" date,
    "Rec_Type" character varying(4),
    "Form_Type" character varying(4) NOT NULL,
    "Tran_ID" character varying NOT NULL,
    "Amount" double precision NOT NULL,
    "Exp_Date" date NOT NULL,
    "Date_Thru" character varying,
    "Expn_Dscr" character varying,
    "Memo_Code" character varying,
    "Memo_RefNo" character varying,
    "Bal_Name" character varying,
    "Bal_Num" character varying(4),
    "Bal_Juris" character varying,
    "Sup_Opp_Cd" character varying(1) NOT NULL,
    "Cand_NamL" character varying,
    "Cand_NamF" character varying,
    "Cand_NamT" character varying,
    "Cand_NamS" character varying,
    "Office_Cd" character varying(4),
    "Offic_Dscr" character varying,
    "Juris_Cd" character varying(4),
    "Juris_Dscr" character varying,
    "Dist_No" character varying(4),
    "Rpt_ID_Num" character varying
);


ALTER TABLE public."496" OWNER TO travis;

--
-- Name: 497; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public."497" (
    "Filer_ID" character varying(9),
    "Filer_NamL" character varying,
    "Report_Num" character varying(3) NOT NULL,
    "Committee_Type" character varying(4),
    "Rpt_Date" date NOT NULL,
    "From_Date" date,
    "Thru_Date" date,
    "Elect_Date" date,
    "Rec_Type" character varying(4),
    "Form_Type" character varying(6) NOT NULL,
    "Tran_ID" character varying NOT NULL,
    "Entity_Cd" character varying(3) NOT NULL,
    "Enty_NamL" character varying,
    "Enty_NamF" character varying,
    "Enty_NamT" character varying,
    "Enty_NamS" character varying,
    "Enty_Adr1" character varying,
    "Enty_Adr2" character varying,
    "Enty_City" character varying,
    "Enty_ST" character varying(4),
    "Enty_Zip4" character varying(10),
    "Ctrib_Emp" character varying,
    "Ctrib_Occ" character varying,
    "Ctrib_Self" character varying,
    "Elec_Date" date,
    "Ctrib_Date" date NOT NULL,
    "Date_Thru" character varying,
    "Amount" double precision NOT NULL,
    "Cmte_ID" character varying(9),
    "Cand_NamL" character varying,
    "Cand_NamF" character varying,
    "Cand_NamT" character varying,
    "Cand_NamS" character varying,
    "Office_Cd" character varying(4),
    "Offic_Dscr" character varying,
    "Juris_Cd" character varying(4),
    "Juris_Dscr" character varying,
    "Dist_No" character varying(4),
    "Off_S_H_Cd" character varying(4),
    "Bal_Name" character varying,
    "Bal_Num" character varying(4),
    "Bal_Juris" character varying,
    "Memo_Code" character varying,
    "Memo_RefNo" character varying,
    "Rpt_ID_Num" character varying
);


ALTER TABLE public."497" OWNER TO travis;

--
-- Name: A-Contributions; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public."A-Contributions" (
    "Filer_ID" character varying(9) NOT NULL,
    "Filer_NamL" character varying,
    "Report_Num" character varying(3) NOT NULL,
    "Committee_Type" character varying(3) NOT NULL,
    "Rpt_Date" date NOT NULL,
    "From_Date" date NOT NULL,
    "Thru_Date" date NOT NULL,
    "Elect_Date" date,
    "tblCover_Office_Cd" character varying,
    "tblCover_Offic_Dscr" character varying,
    "Rec_Type" character varying(4),
    "Form_Type" character varying(1) NOT NULL,
    "Tran_ID" character varying NOT NULL,
    "Entity_Cd" character varying(3) NOT NULL,
    "Tran_NamL" character varying,
    "Tran_NamF" character varying,
    "Tran_NamT" character varying,
    "Tran_NamS" character varying,
    "Tran_Adr1" character varying,
    "Tran_Adr2" character varying,
    "Tran_City" character varying,
    "Tran_State" character varying(4),
    "Tran_Zip4" character varying(10),
    "Tran_Emp" character varying,
    "Tran_Occ" character varying,
    "Tran_Self" boolean NOT NULL,
    "Tran_Type" character varying(4),
    "Tran_Date" date NOT NULL,
    "Tran_Date1" date,
    "Tran_Amt1" double precision NOT NULL,
    "Tran_Amt2" double precision NOT NULL,
    "Tran_Dscr" character varying,
    "Cmte_ID" character varying(9),
    "Tres_NamL" character varying,
    "Tres_NamF" character varying,
    "Tres_NamT" character varying,
    "Tres_NamS" character varying,
    "Tres_Adr1" character varying,
    "Tres_Adr2" character varying,
    "Tres_City" character varying,
    "Tres_State" character varying(4),
    "Tres_Zip" integer,
    "Intr_NamL" character varying,
    "Intr_NamF" character varying,
    "Intr_NamT" character varying,
    "Intr_NamS" character varying,
    "Intr_Adr1" character varying,
    "Intr_Adr2" character varying,
    "Intr_City" character varying,
    "Intr_State" character varying(4),
    "Intr_Zip4" character varying(10),
    "Intr_Emp" character varying,
    "Intr_Occ" character varying,
    "Intr_Self" boolean NOT NULL,
    "Cand_NamL" character varying,
    "Cand_NamF" character varying,
    "Cand_NamT" character varying,
    "Cand_NamS" character varying,
    "tblDetlTran_Office_Cd" character varying(4),
    "tblDetlTran_Offic_Dscr" character varying,
    "Juris_Cd" character varying(4),
    "Juris_Dscr" character varying,
    "Dist_No" character varying,
    "Off_S_H_Cd" character varying,
    "Bal_Name" character varying,
    "Bal_Num" character varying(4),
    "Bal_Juris" character varying,
    "Sup_Opp_Cd" character varying,
    "Memo_Code" character varying,
    "Memo_RefNo" character varying,
    "BakRef_TID" character varying,
    "XRef_SchNm" character varying,
    "XRef_Match" character varying,
    "Loan_Rate" character varying,
    "Int_CmteId" character varying
);


ALTER TABLE public."A-Contributions" OWNER TO travis;

--
-- Name: B1-Loans; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public."B1-Loans" (
    "Filer_ID" character varying(9) NOT NULL,
    "Filer_NamL" character varying,
    "Report_Num" character varying(3) NOT NULL,
    "Committee_Type" character varying(3) NOT NULL,
    "Rpt_Date" date NOT NULL,
    "From_Date" date NOT NULL,
    "Thru_Date" date NOT NULL,
    "Elect_Date" date,
    "tblCover_Office_Cd" character varying,
    "tblCover_Offic_Dscr" character varying,
    "Rec_Type" character varying(4),
    "Form_Type" character varying(2) NOT NULL,
    "Tran_ID" character varying NOT NULL,
    "Entity_Cd" character varying(3) NOT NULL,
    "Lndr_NamL" character varying,
    "Lndr_NamF" character varying,
    "Lndr_NamT" character varying,
    "Lndr_NamS" character varying,
    "Loan_Adr1" character varying,
    "Loan_Adr2" character varying,
    "Loan_City" character varying,
    "Loan_ST" character varying(4),
    "Loan_Zip4" character varying(10),
    "Loan_Date1" date NOT NULL,
    "Loan_Date2" date,
    "Loan_Amt1" double precision NOT NULL,
    "Loan_Amt2" double precision NOT NULL,
    "Loan_Amt3" double precision NOT NULL,
    "Loan_Amt4" double precision NOT NULL,
    "Loan_Rate" character varying,
    "Loan_EMP" character varying,
    "Loan_OCC" character varying,
    "Loan_Self" boolean NOT NULL,
    "Cmte_ID" integer,
    "Tres_NamL" character varying,
    "Tres_NamF" character varying,
    "Tres_NamT" character varying,
    "Tres_NamS" character varying,
    "Tres_Adr1" character varying,
    "Tres_Adr2" character varying,
    "Tres_City" character varying,
    "Tres_ST" character varying,
    "Tres_ZIP4" character varying,
    "B2Lender_Name-Inter_name" character varying,
    "Intr_NamF" character varying,
    "Intr_NamT" character varying,
    "Intr_NamS" character varying,
    "Intr_Adr1" character varying,
    "Intr_Adr2" character varying,
    "Intr_City" character varying,
    "Intr_ST" character varying,
    "Intr_ZIP4" character varying,
    "Memo_Code" character varying(6),
    "Memo_RefNo" character varying,
    "BakRef_TID" character varying,
    "XRef_SchNm" character varying,
    "XRef_Match" character varying,
    "Loan_Amt5" double precision NOT NULL,
    "Loan_Amt6" double precision NOT NULL,
    "Loan_Amt7" double precision NOT NULL,
    "Loan_Amt8" double precision NOT NULL
);


ALTER TABLE public."B1-Loans" OWNER TO travis;

--
-- Name: B2-Loans; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public."B2-Loans" (
    "Filer_ID" character varying NOT NULL,
    "Filer_NamL" character varying,
    "Report_Num" character varying NOT NULL,
    "Committee_Type" character varying NOT NULL,
    "Rpt_Date" character varying,
    "From_Date" character varying,
    "Thru_Date" character varying,
    "Elect_Date" character varying,
    "tblCover_Office_Cd" character varying,
    "tblCover_Offic_Dscr" character varying,
    "Rec_Type" character varying,
    "Form_Type" character varying NOT NULL,
    "Tran_ID" character varying NOT NULL,
    "Entity_Cd" character varying NOT NULL,
    "Lndr_NamL" character varying,
    "Lndr_NamF" character varying,
    "Lndr_NamT" character varying,
    "Lndr_NamS" character varying,
    "Loan_Adr1" character varying,
    "Loan_Adr2" character varying,
    "Loan_City" character varying,
    "Loan_ST" character varying,
    "Loan_Zip4" character varying,
    "Loan_Date1" character varying,
    "Loan_Date2" character varying,
    "Loan_Amt1" character varying,
    "Loan_Amt2" character varying,
    "Loan_Amt3" character varying,
    "Loan_Amt4" character varying,
    "Loan_Rate" character varying,
    "Loan_EMP" character varying,
    "Loan_OCC" character varying,
    "Loan_Self" character varying,
    "Cmte_ID" character varying,
    "Tres_NamL" character varying,
    "Tres_NamF" character varying,
    "Tres_NamT" character varying,
    "Tres_NamS" character varying,
    "Tres_Adr1" character varying,
    "Tres_Adr2" character varying,
    "Tres_City" character varying,
    "Tres_ST" character varying,
    "Tres_ZIP4" character varying,
    "B2Lender_Name-Inter_name" character varying,
    "Intr_NamF" character varying,
    "Intr_NamT" character varying,
    "Intr_NamS" character varying,
    "Intr_Adr1" character varying,
    "Intr_Adr2" character varying,
    "Intr_City" character varying,
    "Intr_ST" character varying,
    "Intr_ZIP4" character varying,
    "Memo_Code" character varying,
    "Memo_RefNo" character varying,
    "BakRef_TID" character varying,
    "XRef_SchNm" character varying,
    "XRef_Match" character varying,
    "Loan_Amt5" character varying,
    "Loan_Amt6" character varying,
    "Loan_Amt7" character varying,
    "Loan_Amt8" character varying
);


ALTER TABLE public."B2-Loans" OWNER TO travis;

--
-- Name: C-Contributions; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public."C-Contributions" (
    "Filer_ID" integer NOT NULL,
    "Filer_NamL" character varying,
    "Report_Num" character varying(3) NOT NULL,
    "Committee_Type" character varying(3) NOT NULL,
    "Rpt_Date" date NOT NULL,
    "From_Date" date NOT NULL,
    "Thru_Date" date NOT NULL,
    "Elect_Date" date,
    "tblCover_Office_Cd" character varying,
    "tblCover_Offic_Dscr" character varying,
    "Rec_Type" character varying(4),
    "Form_Type" character varying(1) NOT NULL,
    "Tran_ID" character varying NOT NULL,
    "Entity_Cd" character varying(3) NOT NULL,
    "Tran_NamL" character varying,
    "Tran_NamF" character varying,
    "Tran_NamT" character varying,
    "Tran_NamS" character varying,
    "Tran_Adr1" character varying,
    "Tran_Adr2" character varying,
    "Tran_City" character varying,
    "Tran_State" character varying(2),
    "Tran_Zip4" character varying(10),
    "Tran_Emp" character varying,
    "Tran_Occ" character varying,
    "Tran_Self" boolean NOT NULL,
    "Tran_Type" boolean,
    "Tran_Date" date NOT NULL,
    "Tran_Date1" date,
    "Tran_Amt1" double precision NOT NULL,
    "Tran_Amt2" double precision NOT NULL,
    "Tran_Dscr" character varying,
    "Cmte_ID" character varying(9),
    "Tres_NamL" character varying,
    "Tres_NamF" character varying,
    "Tres_NamT" character varying,
    "Tres_NamS" character varying,
    "Tres_Adr1" character varying,
    "Tres_Adr2" character varying,
    "Tres_City" character varying,
    "Tres_State" character varying,
    "Tres_Zip" character varying,
    "Intr_NamL" character varying,
    "Intr_NamF" character varying,
    "Intr_NamT" character varying,
    "Intr_NamS" character varying,
    "Intr_Adr1" character varying,
    "Intr_Adr2" character varying,
    "Intr_City" character varying,
    "Intr_State" character varying,
    "Intr_Zip4" character varying,
    "Intr_Emp" character varying,
    "Intr_Occ" character varying,
    "Intr_Self" boolean NOT NULL,
    "Cand_NamL" character varying,
    "Cand_NamF" character varying,
    "Cand_NamT" character varying,
    "Cand_NamS" character varying,
    "tblDetlTran_Office_Cd" character varying,
    "tblDetlTran_Offic_Dscr" character varying,
    "Juris_Cd" character varying,
    "Juris_Dscr" character varying,
    "Dist_No" character varying,
    "Off_S_H_Cd" character varying,
    "Bal_Name" character varying,
    "Bal_Num" character varying,
    "Bal_Juris" character varying,
    "Sup_Opp_Cd" character varying,
    "Memo_Code" character varying(4),
    "Memo_RefNo" character varying,
    "BakRef_TID" character varying,
    "XRef_SchNm" character varying,
    "XRef_Match" character varying,
    "Loan_Rate" character varying,
    "Int_CmteId" character varying
);


ALTER TABLE public."C-Contributions" OWNER TO travis;

--
-- Name: D-Expenditure; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public."D-Expenditure" (
    "Filer_ID" character varying(9) NOT NULL,
    "Filer_NamL" character varying,
    "Report_Num" character varying(3) NOT NULL,
    "Committee_Type" character varying(3) NOT NULL,
    "Rpt_Date" date NOT NULL,
    "From_Date" date NOT NULL,
    "Thru_Date" date NOT NULL,
    "Elect_Date" date,
    "tblCover_Office_Cd" character varying,
    "tblCover_Offic_Dscr" character varying,
    "Rec_Type" character varying(4),
    "Form_Type" character varying(1) NOT NULL,
    "Tran_ID" character varying NOT NULL,
    "Entity_Cd" character varying(4),
    "Payee_NamL" character varying,
    "Payee_NamF" character varying,
    "Payee_NamT" character varying,
    "Payee_NamS" character varying,
    "Payee_Adr1" character varying,
    "Payee_Adr2" character varying,
    "Payee_City" character varying,
    "Payee_State" character varying(4),
    "Payee_Zip4" character varying(10),
    "Expn_Date" date NOT NULL,
    "Amount" double precision NOT NULL,
    "Cum_YTD" double precision NOT NULL,
    "Expn_ChkNo" integer,
    "Expn_Code" character varying(3),
    "Expn_Dscr" character varying,
    "Agent_NamL" character varying,
    "Agent_NamF" character varying,
    "Agent_NamT" character varying,
    "Agent_NamS" character varying,
    "Cmte_ID" character varying(7),
    "Tres_NamL" character varying,
    "Tres_NamF" character varying,
    "Tres_NamT" character varying,
    "Tres_NamS" character varying,
    "Tres_Adr1" character varying,
    "Tres_Adr2" character varying,
    "Tres_City" character varying,
    "Tres_ST" character varying(4),
    "Tres_ZIP4" integer,
    "Cand_NamL" character varying,
    "Cand_NamF" character varying,
    "Cand_NamT" character varying,
    "Cand_NamS" character varying,
    "Office_Cd" character varying(4),
    "Offic_Dscr" character varying,
    "Juris_Cd" character varying(4),
    "Juris_Dscr" character varying,
    "Dist_No" character varying(4),
    "Off_S_H_Cd" character varying(4),
    "Bal_Name" character varying,
    "Bal_Num" character varying(4),
    "Bal_Juris" character varying,
    "Sup_Opp_Cd" character varying(4),
    "Memo_Code" character varying(4),
    "Memo_RefNo" character varying,
    "BakRef_TID" character varying,
    "G_From_E_F" character varying,
    "XRef_SchNm" character varying,
    "XRef_Match" character varying
);


ALTER TABLE public."D-Expenditure" OWNER TO travis;

--
-- Name: E-Expenditure; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public."E-Expenditure" (
    "Filer_ID" character varying(9) NOT NULL,
    "Filer_NamL" character varying,
    "Report_Num" character varying(3) NOT NULL,
    "Committee_Type" character varying(3) NOT NULL,
    "Rpt_Date" date NOT NULL,
    "From_Date" date NOT NULL,
    "Thru_Date" date NOT NULL,
    "Elect_Date" date,
    "tblCover_Office_Cd" character varying,
    "tblCover_Offic_Dscr" character varying,
    "Rec_Type" character varying(4),
    "Form_Type" character varying(1) NOT NULL,
    "Tran_ID" character varying NOT NULL,
    "Entity_Cd" character varying(4),
    "Payee_NamL" character varying,
    "Payee_NamF" character varying,
    "Payee_NamT" character varying,
    "Payee_NamS" character varying,
    "Payee_Adr1" character varying,
    "Payee_Adr2" character varying,
    "Payee_City" character varying,
    "Payee_State" character varying(4),
    "Payee_Zip4" character varying(10),
    "Expn_Date" date,
    "Amount" double precision NOT NULL,
    "Cum_YTD" double precision,
    "Expn_ChkNo" character varying,
    "Expn_Code" character varying(4),
    "Expn_Dscr" character varying,
    "Agent_NamL" character varying,
    "Agent_NamF" character varying,
    "Agent_NamT" character varying,
    "Agent_NamS" character varying,
    "Cmte_ID" character varying(9),
    "Tres_NamL" character varying,
    "Tres_NamF" character varying,
    "Tres_NamT" character varying,
    "Tres_NamS" character varying,
    "Tres_Adr1" character varying,
    "Tres_Adr2" character varying,
    "Tres_City" character varying,
    "Tres_ST" character varying(4),
    "Tres_ZIP4" integer,
    "Cand_NamL" character varying,
    "Cand_NamF" character varying,
    "Cand_NamT" character varying,
    "Cand_NamS" character varying,
    "Office_Cd" character varying(4),
    "Offic_Dscr" character varying,
    "Juris_Cd" character varying(4),
    "Juris_Dscr" character varying,
    "Dist_No" character varying(4),
    "Off_S_H_Cd" character varying,
    "Bal_Name" character varying,
    "Bal_Num" character varying(4),
    "Bal_Juris" character varying,
    "Sup_Opp_Cd" character varying(4),
    "Memo_Code" character varying,
    "Memo_RefNo" character varying,
    "BakRef_TID" character varying,
    "G_From_E_F" character varying,
    "XRef_SchNm" character varying,
    "XRef_Match" character varying
);


ALTER TABLE public."E-Expenditure" OWNER TO travis;

--
-- Name: F-Expenses; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public."F-Expenses" (
    "Filer_ID" character varying(7) NOT NULL,
    "Filer_NamL" character varying,
    "Report_Num" character varying(3) NOT NULL,
    "Committee_Type" character varying(3) NOT NULL,
    "Rpt_Date" date NOT NULL,
    "From_Date" date NOT NULL,
    "Thru_Date" date NOT NULL,
    "Elect_Date" date,
    "tblCover_Office_Cd" character varying,
    "tblCover_Offic_Dscr" character varying,
    "Rec_Type" character varying(4),
    "Form_Type" boolean NOT NULL,
    "Tran_ID" character varying NOT NULL,
    "Entity_Cd" character varying(3) NOT NULL,
    "Payee_NamL" character varying,
    "Payee_NamF" character varying,
    "Payee_NamT" character varying,
    "Payee_NamS" character varying,
    "Payee_Adr1" character varying,
    "Payee_Adr2" character varying,
    "Payee_City" character varying,
    "Payee_State" character varying(2),
    "Payee_Zip4" character varying(10),
    "Beg_Bal" double precision NOT NULL,
    "Amt_Incur" double precision NOT NULL,
    "Amt_Paid" double precision NOT NULL,
    "End_Bal" double precision NOT NULL,
    "Expn_Code" character varying(4),
    "Expn_Dscr" character varying,
    "Cmte_ID" character varying(7),
    "Tres_NamL" character varying,
    "Tres_NamF" character varying,
    "Tres_NamT" character varying,
    "Tres_NamS" character varying,
    "Tres_Adr1" character varying,
    "Tres_Adr2" character varying,
    "Tres_City" character varying,
    "Tres_ST" character varying,
    "Tres_ZIP4" character varying,
    "Memo_Code" character varying,
    "Memo_RefNo" character varying,
    "BakRef_TID" character varying,
    "XRef_SchNm" character varying,
    "XRef_Match" character varying
);


ALTER TABLE public."F-Expenses" OWNER TO travis;

--
-- Name: F461P5-Expenditure; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public."F461P5-Expenditure" (
    "Filer_ID" character varying(9),
    "Filer_NamL" character varying,
    "Report_Num" character varying(3) NOT NULL,
    "Committee_Type" character varying(3) NOT NULL,
    "Rpt_Date" date NOT NULL,
    "From_Date" date NOT NULL,
    "Thru_Date" date NOT NULL,
    "Elect_Date" date,
    "tblCover_Office_Cd" character varying,
    "tblCover_Offic_Dscr" character varying,
    "Rec_Type" character varying(4),
    "Form_Type" character varying(6) NOT NULL,
    "Tran_ID" character varying NOT NULL,
    "Entity_Cd" character varying(4),
    "Payee_NamL" character varying,
    "Payee_NamF" character varying,
    "Payee_NamT" character varying,
    "Payee_NamS" character varying,
    "Payee_Adr1" character varying,
    "Payee_Adr2" character varying,
    "Payee_City" character varying,
    "Payee_State" character varying(4),
    "Payee_Zip4" character varying(10),
    "Expn_Date" date NOT NULL,
    "Amount" double precision NOT NULL,
    "Cum_YTD" double precision NOT NULL,
    "Expn_ChkNo" character varying,
    "Expn_Code" character varying(3),
    "Expn_Dscr" character varying,
    "Agent_NamL" character varying,
    "Agent_NamF" character varying,
    "Agent_NamT" character varying,
    "Agent_NamS" character varying,
    "Cmte_ID" character varying(7),
    "Tres_NamL" character varying,
    "Tres_NamF" character varying,
    "Tres_NamT" character varying,
    "Tres_NamS" character varying,
    "Tres_Adr1" character varying,
    "Tres_Adr2" character varying,
    "Tres_City" character varying,
    "Tres_ST" character varying(4),
    "Tres_ZIP4" integer,
    "Cand_NamL" character varying,
    "Cand_NamF" character varying,
    "Cand_NamT" character varying,
    "Cand_NamS" character varying,
    "Office_Cd" character varying(4),
    "Offic_Dscr" character varying,
    "Juris_Cd" character varying(4),
    "Juris_Dscr" character varying,
    "Dist_No" character varying(4),
    "Off_S_H_Cd" character varying(4),
    "Bal_Name" character varying,
    "Bal_Num" character varying(4),
    "Bal_Juris" character varying,
    "Sup_Opp_Cd" character varying(4),
    "Memo_Code" character varying(4),
    "Memo_RefNo" character varying,
    "BakRef_TID" character varying,
    "G_From_E_F" character varying,
    "XRef_SchNm" character varying,
    "XRef_Match" character varying,
    "EmplBus_CB" character varying,
    "Bus_Name" character varying,
    "Bus_Adr1" character varying,
    "Bus_Adr2" character varying,
    "Bus_City" character varying,
    "Bus_ST" character varying(4),
    "Bus_ZIP4" integer,
    "Bus_Inter" character varying,
    "BusAct_CB" character varying,
    "BusActvity" character varying,
    "Assoc_CB" character varying,
    "Assoc_Int" character varying,
    "Other_CB" character varying,
    "Other_Int" character varying
);


ALTER TABLE public."F461P5-Expenditure" OWNER TO travis;

--
-- Name: F465P3-Expenditure; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public."F465P3-Expenditure" (
    "Filer_ID" integer NOT NULL,
    "Filer_NamL" character varying,
    "Report_Num" integer NOT NULL,
    "Committee_Type" character varying(3) NOT NULL,
    "Rpt_Date" date NOT NULL,
    "From_Date" date NOT NULL,
    "Thru_Date" date NOT NULL,
    "Elect_Date" date NOT NULL,
    "tblCover_Office_Cd" character varying,
    "tblCover_Offic_Dscr" character varying,
    "Rec_Type" character varying(4),
    "Form_Type" character varying(6) NOT NULL,
    "Tran_ID" character varying NOT NULL,
    "Entity_Cd" character varying(3) NOT NULL,
    "Payee_NamL" character varying,
    "Payee_NamF" character varying,
    "Payee_NamT" character varying,
    "Payee_NamS" character varying,
    "Payee_Adr1" character varying,
    "Payee_Adr2" character varying,
    "Payee_City" character varying,
    "Payee_State" character varying(2),
    "Payee_Zip4" integer NOT NULL,
    "Expn_Date" date NOT NULL,
    "Amount" double precision NOT NULL,
    "Cum_YTD" double precision,
    "Expn_ChkNo" character varying,
    "Expn_Code" character varying(4),
    "Expn_Dscr" character varying,
    "Agent_NamL" character varying,
    "Agent_NamF" character varying,
    "Agent_NamT" character varying,
    "Agent_NamS" character varying,
    "Cmte_ID" character varying,
    "Tres_NamL" character varying,
    "Tres_NamF" character varying,
    "Tres_NamT" character varying,
    "Tres_NamS" character varying,
    "Tres_Adr1" character varying,
    "Tres_Adr2" character varying,
    "Tres_City" character varying,
    "Tres_ST" character varying,
    "Tres_ZIP4" character varying,
    "Cand_NamL" character varying,
    "Cand_NamF" character varying,
    "Cand_NamT" character varying,
    "Cand_NamS" character varying,
    "Office_Cd" character varying(4),
    "Offic_Dscr" character varying,
    "Juris_Cd" character varying(4),
    "Juris_Dscr" character varying,
    "Dist_No" character varying(4),
    "Off_S_H_Cd" character varying,
    "Bal_Name" character varying,
    "Bal_Num" character varying(4),
    "Bal_Juris" character varying,
    "Sup_Opp_Cd" character varying(1) NOT NULL,
    "Memo_Code" character varying,
    "Memo_RefNo" character varying,
    "BakRef_TID" character varying,
    "G_From_E_F" character varying,
    "XRef_SchNm" character varying,
    "XRef_Match" character varying
);


ALTER TABLE public."F465P3-Expenditure" OWNER TO travis;

--
-- Name: F496P3-Contributions; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public."F496P3-Contributions" (
    "Filer_ID" character varying(7) NOT NULL,
    "Filer_NamL" character varying,
    "Report_Num" character varying(3) NOT NULL,
    "Committee_Type" character varying(4),
    "Rpt_Date" date NOT NULL,
    "From_Date" date,
    "Thru_Date" date,
    "Elect_Date" date,
    "tblCover_Office_Cd" character varying,
    "tblCover_Offic_Dscr" character varying,
    "Rec_Type" character varying(4),
    "Form_Type" character varying(6) NOT NULL,
    "Tran_ID" character varying NOT NULL,
    "Entity_Cd" character varying(3) NOT NULL,
    "Tran_NamL" character varying,
    "Tran_NamF" character varying,
    "Tran_NamT" character varying,
    "Tran_NamS" character varying,
    "Tran_Adr1" character varying,
    "Tran_Adr2" character varying,
    "Tran_City" character varying,
    "Tran_State" character varying(2),
    "Tran_Zip4" character varying(10),
    "Tran_Emp" character varying,
    "Tran_Occ" character varying,
    "Tran_Self" boolean NOT NULL,
    "Tran_Type" character varying(4),
    "Tran_Date" date NOT NULL,
    "Tran_Date1" character varying,
    "Tran_Amt1" double precision NOT NULL,
    "Tran_Amt2" double precision,
    "Tran_Dscr" character varying,
    "Cmte_ID" character varying(9),
    "Tres_NamL" character varying,
    "Tres_NamF" character varying,
    "Tres_NamT" character varying,
    "Tres_NamS" character varying,
    "Tres_Adr1" character varying,
    "Tres_Adr2" character varying,
    "Tres_City" character varying,
    "Tres_State" character varying,
    "Tres_Zip" character varying,
    "Intr_NamL" character varying,
    "Intr_NamF" character varying,
    "Intr_NamT" character varying,
    "Intr_NamS" character varying,
    "Intr_Adr1" character varying,
    "Intr_Adr2" character varying,
    "Intr_City" character varying,
    "Intr_State" character varying(4),
    "Intr_Zip4" character varying(10),
    "Intr_Emp" character varying,
    "Intr_Occ" character varying,
    "Intr_Self" boolean NOT NULL,
    "Cand_NamL" character varying,
    "Cand_NamF" character varying,
    "Cand_NamT" character varying,
    "Cand_NamS" character varying,
    "tblDetlTran_Office_Cd" character varying(4),
    "tblDetlTran_Offic_Dscr" character varying,
    "Juris_Cd" character varying(4),
    "Juris_Dscr" character varying,
    "Dist_No" character varying(4),
    "Off_S_H_Cd" character varying,
    "Bal_Name" character varying,
    "Bal_Num" character varying,
    "Bal_Juris" character varying,
    "Sup_Opp_Cd" character varying,
    "Memo_Code" character varying,
    "Memo_RefNo" character varying,
    "BakRef_TID" character varying,
    "XRef_SchNm" character varying,
    "XRef_Match" character varying,
    "Loan_Rate" double precision,
    "Int_CmteId" character varying
);


ALTER TABLE public."F496P3-Contributions" OWNER TO travis;

--
-- Name: G-Expenditure; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public."G-Expenditure" (
    "Filer_ID" integer NOT NULL,
    "Filer_NamL" character varying,
    "Report_Num" character varying(3) NOT NULL,
    "Committee_Type" character varying(3) NOT NULL,
    "Rpt_Date" date NOT NULL,
    "From_Date" date NOT NULL,
    "Thru_Date" date NOT NULL,
    "Elect_Date" date,
    "tblCover_Office_Cd" character varying,
    "tblCover_Offic_Dscr" character varying,
    "Rec_Type" character varying(4),
    "Form_Type" character varying(1) NOT NULL,
    "Tran_ID" character varying NOT NULL,
    "Entity_Cd" character varying(3) NOT NULL,
    "Payee_NamL" character varying,
    "Payee_NamF" character varying,
    "Payee_NamT" character varying,
    "Payee_NamS" character varying,
    "Payee_Adr1" character varying,
    "Payee_Adr2" character varying,
    "Payee_City" character varying,
    "Payee_State" character varying(4),
    "Payee_Zip4" character varying(10),
    "Expn_Date" date,
    "Amount" double precision NOT NULL,
    "Cum_YTD" double precision,
    "Expn_ChkNo" character varying,
    "Expn_Code" character varying(4),
    "Expn_Dscr" character varying,
    "Agent_NamL" character varying,
    "Agent_NamF" character varying,
    "Agent_NamT" character varying,
    "Agent_NamS" character varying,
    "Cmte_ID" integer,
    "Tres_NamL" character varying,
    "Tres_NamF" character varying,
    "Tres_NamT" character varying,
    "Tres_NamS" character varying,
    "Tres_Adr1" character varying,
    "Tres_Adr2" character varying,
    "Tres_City" character varying,
    "Tres_ST" character varying,
    "Tres_ZIP4" character varying,
    "Cand_NamL" character varying,
    "Cand_NamF" character varying,
    "Cand_NamT" character varying,
    "Cand_NamS" character varying,
    "Office_Cd" character varying(4),
    "Offic_Dscr" character varying,
    "Juris_Cd" character varying(4),
    "Juris_Dscr" character varying,
    "Dist_No" character varying(4),
    "Off_S_H_Cd" character varying,
    "Bal_Name" character varying,
    "Bal_Num" character varying(4),
    "Bal_Juris" character varying,
    "Sup_Opp_Cd" character varying(4),
    "Memo_Code" character varying,
    "Memo_RefNo" character varying,
    "BakRef_TID" character varying,
    "G_From_E_F" character varying,
    "XRef_SchNm" character varying,
    "XRef_Match" character varying
);


ALTER TABLE public."G-Expenditure" OWNER TO travis;

--
-- Name: H-Loans; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public."H-Loans" (
    "Filer_ID" integer NOT NULL,
    "Filer_NamL" character varying,
    "Report_Num" character varying(3) NOT NULL,
    "Committee_Type" character varying(3) NOT NULL,
    "Rpt_Date" date NOT NULL,
    "From_Date" date NOT NULL,
    "Thru_Date" date NOT NULL,
    "Elect_Date" date,
    "tblCover_Office_Cd" character varying,
    "tblCover_Offic_Dscr" character varying,
    "Rec_Type" character varying(4),
    "Form_Type" character varying(1) NOT NULL,
    "Tran_ID" character varying NOT NULL,
    "Entity_Cd" character varying(3) NOT NULL,
    "Lndr_NamL" character varying,
    "Lndr_NamF" character varying,
    "Lndr_NamT" character varying,
    "Lndr_NamS" character varying,
    "Loan_Adr1" character varying,
    "Loan_Adr2" character varying,
    "Loan_City" character varying,
    "Loan_ST" character varying(2),
    "Loan_Zip4" integer NOT NULL,
    "Loan_Date1" date NOT NULL,
    "Loan_Date2" date,
    "Loan_Amt1" double precision NOT NULL,
    "Loan_Amt2" double precision NOT NULL,
    "Loan_Amt3" double precision NOT NULL,
    "Loan_Amt4" double precision NOT NULL,
    "Loan_Rate" double precision,
    "Loan_EMP" character varying,
    "Loan_OCC" character varying,
    "Loan_Self" boolean NOT NULL,
    "Cmte_ID" integer,
    "Tres_NamL" character varying,
    "Tres_NamF" character varying,
    "Tres_NamT" character varying,
    "Tres_NamS" character varying,
    "Tres_Adr1" character varying,
    "Tres_Adr2" character varying,
    "Tres_City" character varying,
    "Tres_ST" character varying,
    "Tres_ZIP4" character varying,
    "B2Lender_Name-Inter_name" character varying,
    "Intr_NamF" character varying,
    "Intr_NamT" character varying,
    "Intr_NamS" character varying,
    "Intr_Adr1" character varying,
    "Intr_Adr2" character varying,
    "Intr_City" character varying,
    "Intr_ST" character varying,
    "Intr_ZIP4" character varying,
    "Memo_Code" character varying(5),
    "Memo_RefNo" character varying,
    "BakRef_TID" character varying,
    "XRef_SchNm" character varying,
    "XRef_Match" character varying,
    "Loan_Amt5" double precision NOT NULL,
    "Loan_Amt6" double precision NOT NULL,
    "Loan_Amt7" double precision NOT NULL,
    "Loan_Amt8" double precision NOT NULL
);


ALTER TABLE public."H-Loans" OWNER TO travis;

--
-- Name: I-Contributions; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public."I-Contributions" (
    "Filer_ID" character varying(7) NOT NULL,
    "Filer_NamL" character varying,
    "Report_Num" character varying(3) NOT NULL,
    "Committee_Type" character varying(3) NOT NULL,
    "Rpt_Date" date NOT NULL,
    "From_Date" date NOT NULL,
    "Thru_Date" date NOT NULL,
    "Elect_Date" date,
    "tblCover_Office_Cd" character varying,
    "tblCover_Offic_Dscr" character varying,
    "Rec_Type" character varying(4),
    "Form_Type" character varying(1) NOT NULL,
    "Tran_ID" character varying NOT NULL,
    "Entity_Cd" character varying(3) NOT NULL,
    "Tran_NamL" character varying,
    "Tran_NamF" character varying,
    "Tran_NamT" character varying,
    "Tran_NamS" character varying,
    "Tran_Adr1" character varying,
    "Tran_Adr2" character varying,
    "Tran_City" character varying,
    "Tran_State" character varying(4),
    "Tran_Zip4" character varying(10),
    "Tran_Emp" character varying,
    "Tran_Occ" character varying,
    "Tran_Self" boolean NOT NULL,
    "Tran_Type" character varying,
    "Tran_Date" date NOT NULL,
    "Tran_Date1" character varying,
    "Tran_Amt1" double precision NOT NULL,
    "Tran_Amt2" double precision,
    "Tran_Dscr" character varying,
    "Cmte_ID" integer,
    "Tres_NamL" character varying,
    "Tres_NamF" character varying,
    "Tres_NamT" character varying,
    "Tres_NamS" character varying,
    "Tres_Adr1" character varying,
    "Tres_Adr2" character varying,
    "Tres_City" character varying,
    "Tres_State" character varying(4),
    "Tres_Zip" character varying(10),
    "Intr_NamL" character varying,
    "Intr_NamF" character varying,
    "Intr_NamT" character varying,
    "Intr_NamS" character varying,
    "Intr_Adr1" character varying,
    "Intr_Adr2" character varying,
    "Intr_City" character varying,
    "Intr_State" character varying,
    "Intr_Zip4" character varying,
    "Intr_Emp" character varying,
    "Intr_Occ" character varying,
    "Intr_Self" boolean NOT NULL,
    "Cand_NamL" character varying,
    "Cand_NamF" character varying,
    "Cand_NamT" character varying,
    "Cand_NamS" character varying,
    "tblDetlTran_Office_Cd" character varying,
    "tblDetlTran_Offic_Dscr" character varying,
    "Juris_Cd" character varying,
    "Juris_Dscr" character varying,
    "Dist_No" character varying,
    "Off_S_H_Cd" character varying,
    "Bal_Name" character varying,
    "Bal_Num" character varying,
    "Bal_Juris" character varying,
    "Sup_Opp_Cd" character varying,
    "Memo_Code" character varying,
    "Memo_RefNo" character varying,
    "BakRef_TID" character varying,
    "XRef_SchNm" character varying,
    "XRef_Match" character varying,
    "Loan_Rate" character varying,
    "Int_CmteId" character varying
);


ALTER TABLE public."I-Contributions" OWNER TO travis;

--
-- Name: committees; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public.committees (
    "Ballot_Measure_Election" character varying,
    "Filer_ID" character varying NOT NULL,
    "Filer_NamL" character varying NOT NULL,
    "_Status" character varying,
    "_Committee_Type" character varying(11),
    "Ballot_Measure" character varying(10),
    "Support_Or_Oppose" character varying(4),
    "Cand_ID" integer,
    candidate_controlled_id integer,
    "Start_Date" date,
    "End_Date" date,
    data_warning character varying,
    "Make_Active" boolean,
    id integer NOT NULL
);


ALTER TABLE public.committees OWNER TO travis;

--
-- Name: name_to_number; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public.name_to_number (
    election_name character varying,
    "Measure_Number" character varying(10) NOT NULL,
    "Measure_Name" character varying NOT NULL
);


ALTER TABLE public.name_to_number OWNER TO travis;

--
-- Name: Measure_Expenditures; Type: VIEW; Schema: public; Owner: travis
--

CREATE VIEW public."Measure_Expenditures" AS
 WITH all_expend AS (
         SELECT "E-Expenditure"."Filer_ID",
            "E-Expenditure"."Filer_NamL",
            "E-Expenditure"."Bal_Name",
            "E-Expenditure"."Bal_Num",
            "E-Expenditure"."Sup_Opp_Cd",
            "E-Expenditure"."Amount",
            "E-Expenditure"."Expn_Code",
            "E-Expenditure"."Expn_Date",
            "E-Expenditure"."Payee_NamL" AS "Recipient_Or_Description",
            'E name'::text AS "Form",
            "E-Expenditure"."Tran_ID"
           FROM public."E-Expenditure"
        UNION
         SELECT "496"."Filer_ID",
            "496"."Filer_NamL",
            "496"."Bal_Name",
            "496"."Bal_Num",
            "496"."Sup_Opp_Cd",
            "496"."Amount",
            'IND'::character varying AS "Expn_Code",
            "496"."Exp_Date" AS "Expn_Date",
            "496"."Expn_Dscr" AS "Recipient_Or_Description",
            '496'::text AS "Form",
            "496"."Tran_ID"
           FROM public."496"
        )
 SELECT (expend."Filer_ID")::character varying AS "Filer_ID",
    expend."Filer_NamL",
    name_to_number.election_name,
    expend."Bal_Name",
    name_to_number."Measure_Number",
    expend."Sup_Opp_Cd",
    expend."Amount",
    expend."Expn_Code",
    expend."Expn_Date",
    expend."Recipient_Or_Description",
    expend."Form",
    expend."Tran_ID"
   FROM ((all_expend expend
     JOIN public.committees committee ON (((((expend."Filer_ID")::character varying)::text = (committee."Filer_ID")::text) AND ((committee."Start_Date" IS NULL) OR (expend."Expn_Date" >= committee."Start_Date")) AND ((committee."End_Date" IS NULL) OR (expend."Expn_Date" <= committee."End_Date")))))
     JOIN public.name_to_number ON (((lower((expend."Bal_Name")::text) = lower((name_to_number."Measure_Name")::text)) AND ((name_to_number.election_name)::text = (committee."Ballot_Measure_Election")::text))))
  WHERE (expend."Bal_Num" IS NULL)
UNION ALL
 SELECT (expend."Filer_ID")::character varying AS "Filer_ID",
    expend."Filer_NamL",
    measure.election_name,
        CASE
            WHEN (expend."Bal_Name" IS NULL) THEN (measure."Measure_Name")::character varying
            ELSE expend."Bal_Name"
        END AS "Bal_Name",
    measure."Measure_Number",
    expend."Sup_Opp_Cd",
    expend."Amount",
    expend."Expn_Code",
    expend."Expn_Date",
    expend."Recipient_Or_Description",
    expend."Form",
    expend."Tran_ID"
   FROM ((all_expend expend
     JOIN public.committees committee ON (((((expend."Filer_ID")::character varying)::text = (committee."Filer_ID")::text) AND ((committee."Start_Date" IS NULL) OR (expend."Expn_Date" >= committee."Start_Date")) AND ((committee."End_Date" IS NULL) OR (expend."Expn_Date" <= committee."End_Date")))))
     JOIN ( SELECT name_to_number.election_name,
            name_to_number."Measure_Number",
            max((name_to_number."Measure_Name")::text) AS "Measure_Name"
           FROM public.name_to_number
          GROUP BY name_to_number.election_name, name_to_number."Measure_Number") measure ON ((((committee."Ballot_Measure_Election")::text = (measure.election_name)::text) AND ((expend."Bal_Num")::text = (measure."Measure_Number")::text))))
  WHERE (expend."Bal_Num" IS NOT NULL);


ALTER TABLE public."Measure_Expenditures" OWNER TO travis;

--
-- Name: Summary; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public."Summary" (
    "Filer_ID" character varying(9),
    "Filer_NamL" character varying,
    "Report_Num" character varying(3) NOT NULL,
    "Committee_Type" character varying(3) NOT NULL,
    "Rpt_Date" date NOT NULL,
    "From_Date" date NOT NULL,
    "Thru_Date" date NOT NULL,
    "Elect_Date" date,
    "tblCover_Office_Cd" character varying,
    "tblCover_Offic_Dscr" character varying,
    "Rec_Type" character varying(4),
    "Form_Type" character varying(4) NOT NULL,
    "Line_Item" character varying(3) NOT NULL,
    "Amount_A" double precision,
    "Amount_B" double precision,
    "Amount_C" double precision
);


ALTER TABLE public."Summary" OWNER TO travis;

--
-- Name: all_contributions; Type: VIEW; Schema: public; Owner: travis
--

CREATE VIEW public.all_contributions AS
 SELECT ("A-Contributions"."Filer_ID")::character varying AS "Filer_ID",
    "A-Contributions"."Entity_Cd",
    "A-Contributions"."Tran_Amt1",
    "A-Contributions"."Tran_NamF",
    "A-Contributions"."Tran_NamL",
    "A-Contributions"."Tran_Date",
    "A-Contributions"."Tran_City",
    "A-Contributions"."Tran_State",
    "A-Contributions"."Tran_Zip4",
    "A-Contributions"."Tran_Occ",
    "A-Contributions"."Tran_Emp",
    "A-Contributions"."Committee_Type",
    "A-Contributions"."Cmte_ID",
    "A-Contributions"."Tran_ID"
   FROM public."A-Contributions"
UNION
 SELECT ("C-Contributions"."Filer_ID")::character varying AS "Filer_ID",
    "C-Contributions"."Entity_Cd",
    "C-Contributions"."Tran_Amt1",
    "C-Contributions"."Tran_NamF",
    "C-Contributions"."Tran_NamL",
    "C-Contributions"."Tran_Date",
    "C-Contributions"."Tran_City",
    "C-Contributions"."Tran_State",
    "C-Contributions"."Tran_Zip4",
    "C-Contributions"."Tran_Occ",
    "C-Contributions"."Tran_Emp",
    "C-Contributions"."Committee_Type",
    "C-Contributions"."Cmte_ID",
    "C-Contributions"."Tran_ID"
   FROM public."C-Contributions"
UNION
 SELECT ("497"."Filer_ID")::character varying AS "Filer_ID",
    "497"."Entity_Cd",
    "497"."Amount" AS "Tran_Amt1",
    "497"."Enty_NamF" AS "Tran_NamF",
    "497"."Enty_NamL" AS "Tran_NamL",
    "497"."Ctrib_Date" AS "Tran_Date",
    "497"."Enty_City" AS "Tran_City",
    "497"."Enty_ST" AS "Tran_State",
    "497"."Enty_Zip4" AS "Tran_Zip4",
    "497"."Ctrib_Occ" AS "Tran_Occ",
    "497"."Ctrib_Emp" AS "Tran_Emp",
    "497"."Committee_Type",
    "497"."Cmte_ID",
    "497"."Tran_ID"
   FROM public."497"
  WHERE (("497"."Form_Type")::text = 'F497P1'::text);


ALTER TABLE public.all_contributions OWNER TO travis;

--
-- Name: calculations; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public.calculations (
    id integer NOT NULL,
    subject_id integer,
    subject_type character varying(30),
    name character varying(40),
    value jsonb
);


ALTER TABLE public.calculations OWNER TO travis;

--
-- Name: calculations_id_seq; Type: SEQUENCE; Schema: public; Owner: travis
--

CREATE SEQUENCE public.calculations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.calculations_id_seq OWNER TO travis;

--
-- Name: calculations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: travis
--

ALTER SEQUENCE public.calculations_id_seq OWNED BY public.calculations.id;


--
-- Name: candidates; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public.candidates (
    election_name character varying NOT NULL,
    "Candidate" character varying NOT NULL,
    "FPPC" integer,
    "Committee_Name" character varying,
    "Aliases" character varying,
    "Office" character varying NOT NULL,
    "Incumbent" boolean,
    "Accepted_expenditure_ceiling" boolean,
    "Public_Funding_Received" character varying,
    "Contact_Email" character varying,
    "Website" character varying,
    "Twitter" character varying,
    "Facebook" character varying,
    "Instagram" character varying,
    "Party_Affiliation" character varying,
    "Occupation" character varying,
    "Bio" character varying,
    "Photo" character varying,
    "VotersEdge" character varying,
    "Start_Date" date,
    "End_Date" date,
    "Internal_Notes" character varying,
    data_warning character varying,
    is_winner boolean,
    ballot_status character varying,
    map_app character varying,
    has_pending boolean,
    id integer NOT NULL
);


ALTER TABLE public.candidates OWNER TO travis;

--
-- Name: candidate_496; Type: VIEW; Schema: public; Owner: travis
--

CREATE VIEW public.candidate_496 AS
 SELECT c.election_name,
    c."FPPC",
    expend."Filer_ID",
    expend."Filer_NamL",
    expend."Report_Num",
    expend."Committee_Type",
    expend."Rpt_Date",
    expend."From_Date",
    expend."Thru_Date",
    expend."Elect_Date",
    expend."Rec_Type",
    expend."Form_Type",
    expend."Tran_ID",
    expend."Amount",
    expend."Exp_Date",
    expend."Date_Thru",
    expend."Expn_Dscr",
    expend."Memo_Code",
    expend."Memo_RefNo",
    expend."Bal_Name",
    expend."Bal_Num",
    expend."Bal_Juris",
    expend."Sup_Opp_Cd",
    expend."Cand_NamL",
    expend."Cand_NamF",
    expend."Cand_NamT",
    expend."Cand_NamS",
    expend."Office_Cd",
    expend."Offic_Dscr",
    expend."Juris_Cd",
    expend."Juris_Dscr",
    expend."Dist_No",
    expend."Rpt_ID_Num"
   FROM public."496" expend,
    public.candidates c
  WHERE ((lower((c."Candidate")::text) = lower(TRIM(BOTH FROM concat(expend."Cand_NamF", ' ', expend."Cand_NamL")))) AND ((c."Start_Date" IS NULL) OR (expend."Exp_Date" >= c."Start_Date")) AND ((c."End_Date" IS NULL) OR (expend."Exp_Date" <= c."End_Date")));


ALTER TABLE public.candidate_496 OWNER TO travis;

--
-- Name: candidate_497; Type: VIEW; Schema: public; Owner: travis
--

CREATE VIEW public.candidate_497 AS
 SELECT c.election_name,
    c."Candidate",
    l."Filer_ID",
    l."Filer_NamL",
    l."Report_Num",
    l."Committee_Type",
    l."Rpt_Date",
    l."From_Date",
    l."Thru_Date",
    l."Elect_Date",
    l."Rec_Type",
    l."Form_Type",
    l."Tran_ID",
    l."Entity_Cd",
    l."Enty_NamL",
    l."Enty_NamF",
    l."Enty_NamT",
    l."Enty_NamS",
    l."Enty_Adr1",
    l."Enty_Adr2",
    l."Enty_City",
    l."Enty_ST",
    l."Enty_Zip4",
    l."Ctrib_Emp",
    l."Ctrib_Occ",
    l."Ctrib_Self",
    l."Elec_Date",
    l."Ctrib_Date",
    l."Date_Thru",
    l."Amount",
    l."Cmte_ID",
    l."Cand_NamL",
    l."Cand_NamF",
    l."Cand_NamT",
    l."Cand_NamS",
    l."Office_Cd",
    l."Offic_Dscr",
    l."Juris_Cd",
    l."Juris_Dscr",
    l."Dist_No",
    l."Off_S_H_Cd",
    l."Bal_Name",
    l."Bal_Num",
    l."Bal_Juris",
    l."Memo_Code",
    l."Memo_RefNo",
    l."Rpt_ID_Num"
   FROM public."497" l,
    public.candidates c
  WHERE ((((c."FPPC")::character varying)::text = (l."Filer_ID")::text) AND ((c."Start_Date" IS NULL) OR (l."Ctrib_Date" >= c."Start_Date")) AND ((c."End_Date" IS NULL) OR (l."Ctrib_Date" <= c."End_Date")));


ALTER TABLE public.candidate_497 OWNER TO travis;

--
-- Name: elections; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public.elections (
    name character varying NOT NULL,
    location character varying NOT NULL,
    date date NOT NULL,
    title character varying NOT NULL,
    "Start_Date" date NOT NULL,
    "End_Date" date NOT NULL,
    display integer,
    id integer NOT NULL
);


ALTER TABLE public.elections OWNER TO travis;

--
-- Name: candidate_contributions; Type: VIEW; Schema: public; Owner: travis
--

CREATE VIEW public.candidate_contributions AS
 SELECT all_contributions."Filer_ID",
    all_contributions."Entity_Cd",
    all_contributions."Tran_Amt1",
    all_contributions."Tran_NamF",
    all_contributions."Tran_NamL",
    all_contributions."Tran_Date",
    all_contributions."Tran_City",
    all_contributions."Tran_State",
    all_contributions."Tran_Zip4",
    all_contributions."Tran_Occ",
    all_contributions."Tran_Emp",
    elections.location,
    candidates.election_name,
    'Office'::character varying AS "Type",
    all_contributions."Committee_Type"
   FROM ((public.all_contributions
     JOIN public.candidates ON (((((candidates."FPPC")::character varying)::text = (all_contributions."Filer_ID")::text) AND ((candidates."Start_Date" IS NULL) OR (all_contributions."Tran_Date" >= candidates."Start_Date")) AND ((candidates."End_Date" IS NULL) OR (all_contributions."Tran_Date" <= candidates."End_Date")))))
     JOIN public.elections ON (((candidates.election_name)::text = (elections.name)::text)));


ALTER TABLE public.candidate_contributions OWNER TO travis;

--
-- Name: candidate_d_expenditure; Type: VIEW; Schema: public; Owner: travis
--

CREATE VIEW public.candidate_d_expenditure AS
 SELECT c.election_name,
    c."FPPC",
    expend."Filer_ID",
    expend."Filer_NamL",
    expend."Report_Num",
    expend."Committee_Type",
    expend."Rpt_Date",
    expend."From_Date",
    expend."Thru_Date",
    expend."Elect_Date",
    expend."tblCover_Office_Cd",
    expend."tblCover_Offic_Dscr",
    expend."Rec_Type",
    expend."Form_Type",
    expend."Tran_ID",
    expend."Entity_Cd",
    expend."Payee_NamL",
    expend."Payee_NamF",
    expend."Payee_NamT",
    expend."Payee_NamS",
    expend."Payee_Adr1",
    expend."Payee_Adr2",
    expend."Payee_City",
    expend."Payee_State",
    expend."Payee_Zip4",
    expend."Expn_Date",
    expend."Amount",
    expend."Cum_YTD",
    expend."Expn_ChkNo",
    expend."Expn_Code",
    expend."Expn_Dscr",
    expend."Agent_NamL",
    expend."Agent_NamF",
    expend."Agent_NamT",
    expend."Agent_NamS",
    expend."Cmte_ID",
    expend."Tres_NamL",
    expend."Tres_NamF",
    expend."Tres_NamT",
    expend."Tres_NamS",
    expend."Tres_Adr1",
    expend."Tres_Adr2",
    expend."Tres_City",
    expend."Tres_ST",
    expend."Tres_ZIP4",
    expend."Cand_NamL",
    expend."Cand_NamF",
    expend."Cand_NamT",
    expend."Cand_NamS",
    expend."Office_Cd",
    expend."Offic_Dscr",
    expend."Juris_Cd",
    expend."Juris_Dscr",
    expend."Dist_No",
    expend."Off_S_H_Cd",
    expend."Bal_Name",
    expend."Bal_Num",
    expend."Bal_Juris",
    expend."Sup_Opp_Cd",
    expend."Memo_Code",
    expend."Memo_RefNo",
    expend."BakRef_TID",
    expend."G_From_E_F",
    expend."XRef_SchNm",
    expend."XRef_Match"
   FROM public."D-Expenditure" expend,
    public.candidates c
  WHERE ((lower((c."Candidate")::text) = lower(TRIM(BOTH FROM concat(expend."Cand_NamF", ' ', expend."Cand_NamL")))) AND ((c."Start_Date" IS NULL) OR (expend."Expn_Date" >= c."Start_Date")) AND ((c."End_Date" IS NULL) OR (expend."Expn_Date" <= c."End_Date")));


ALTER TABLE public.candidate_d_expenditure OWNER TO travis;

--
-- Name: candidate_e_expenditure; Type: VIEW; Schema: public; Owner: travis
--

CREATE VIEW public.candidate_e_expenditure AS
 SELECT c.election_name,
    expend."Filer_ID",
    expend."Filer_NamL",
    expend."Report_Num",
    expend."Committee_Type",
    expend."Rpt_Date",
    expend."From_Date",
    expend."Thru_Date",
    expend."Elect_Date",
    expend."tblCover_Office_Cd",
    expend."tblCover_Offic_Dscr",
    expend."Rec_Type",
    expend."Form_Type",
    expend."Tran_ID",
    expend."Entity_Cd",
    expend."Payee_NamL",
    expend."Payee_NamF",
    expend."Payee_NamT",
    expend."Payee_NamS",
    expend."Payee_Adr1",
    expend."Payee_Adr2",
    expend."Payee_City",
    expend."Payee_State",
    expend."Payee_Zip4",
    expend."Expn_Date",
    expend."Amount",
    expend."Cum_YTD",
    expend."Expn_ChkNo",
    expend."Expn_Code",
    expend."Expn_Dscr",
    expend."Agent_NamL",
    expend."Agent_NamF",
    expend."Agent_NamT",
    expend."Agent_NamS",
    expend."Cmte_ID",
    expend."Tres_NamL",
    expend."Tres_NamF",
    expend."Tres_NamT",
    expend."Tres_NamS",
    expend."Tres_Adr1",
    expend."Tres_Adr2",
    expend."Tres_City",
    expend."Tres_ST",
    expend."Tres_ZIP4",
    expend."Cand_NamL",
    expend."Cand_NamF",
    expend."Cand_NamT",
    expend."Cand_NamS",
    expend."Office_Cd",
    expend."Offic_Dscr",
    expend."Juris_Cd",
    expend."Juris_Dscr",
    expend."Dist_No",
    expend."Off_S_H_Cd",
    expend."Bal_Name",
    expend."Bal_Num",
    expend."Bal_Juris",
    expend."Sup_Opp_Cd",
    expend."Memo_Code",
    expend."Memo_RefNo",
    expend."BakRef_TID",
    expend."G_From_E_F",
    expend."XRef_SchNm",
    expend."XRef_Match"
   FROM public."E-Expenditure" expend,
    public.candidates c
  WHERE ((((expend."Filer_ID")::character varying)::text = ((c."FPPC")::character varying)::text) AND ((c."Start_Date" IS NULL) OR (expend."Expn_Date" >= c."Start_Date")) AND ((c."End_Date" IS NULL) OR (expend."Expn_Date" <= c."End_Date")));


ALTER TABLE public.candidate_e_expenditure OWNER TO travis;

--
-- Name: clean_summary; Type: VIEW; Schema: public; Owner: travis
--

CREATE VIEW public.clean_summary AS
 SELECT s."Filer_ID",
    s."Filer_NamL",
    s."Report_Num",
    s."Committee_Type",
    s."Rpt_Date",
    s."From_Date",
    s."Thru_Date",
    s."Elect_Date",
    s."tblCover_Office_Cd",
    s."tblCover_Offic_Dscr",
    s."Rec_Type",
    s."Form_Type",
    s."Line_Item",
    s."Amount_A",
    s."Amount_B",
    s."Amount_C"
   FROM public."Summary" s
  WHERE (NOT (EXISTS ( SELECT t."Rpt_Date"
           FROM public."Summary" t
          WHERE (((s."Filer_ID")::text = (t."Filer_ID")::text) AND (t."From_Date" <= s."From_Date") AND (s."Thru_Date" <= t."Thru_Date") AND ((t."From_Date" <> s."From_Date") OR (s."Thru_Date" <> t."Thru_Date"))))));


ALTER TABLE public.clean_summary OWNER TO travis;

--
-- Name: candidate_summary; Type: VIEW; Schema: public; Owner: travis
--

CREATE VIEW public.candidate_summary AS
 SELECT c.election_name,
    c."Candidate",
    s."Filer_ID",
    s."Filer_NamL",
    s."Report_Num",
    s."Committee_Type",
    s."Rpt_Date",
    s."From_Date",
    s."Thru_Date",
    s."Elect_Date",
    s."tblCover_Office_Cd",
    s."tblCover_Offic_Dscr",
    s."Rec_Type",
    s."Form_Type",
    s."Line_Item",
    s."Amount_A",
    s."Amount_B",
    s."Amount_C"
   FROM public.clean_summary s,
    public.candidates c
  WHERE ((((c."FPPC")::character varying)::text = (s."Filer_ID")::text) AND ((c."Start_Date" IS NULL) OR (s."From_Date" >= c."Start_Date")) AND ((c."End_Date" IS NULL) OR (s."Thru_Date" <= c."End_Date")));


ALTER TABLE public.candidate_summary OWNER TO travis;

--
-- Name: candidates_id_seq; Type: SEQUENCE; Schema: public; Owner: travis
--

CREATE SEQUENCE public.candidates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.candidates_id_seq OWNER TO travis;

--
-- Name: candidates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: travis
--

ALTER SEQUENCE public.candidates_id_seq OWNED BY public.candidates.id;


--
-- Name: measure_contributions; Type: VIEW; Schema: public; Owner: travis
--

CREATE VIEW public.measure_contributions AS
 SELECT all_contributions."Filer_ID",
    all_contributions."Entity_Cd",
    all_contributions."Tran_Amt1",
    all_contributions."Tran_NamF",
    all_contributions."Tran_NamL",
    all_contributions."Tran_Date",
    all_contributions."Tran_City",
    all_contributions."Tran_State",
    all_contributions."Tran_Zip4",
    all_contributions."Tran_Occ",
    all_contributions."Tran_Emp",
    elections.location,
    elections.name AS election_name,
    'Measure'::character varying AS "Type",
    all_contributions."Committee_Type"
   FROM ((public.all_contributions
     JOIN ( SELECT DISTINCT committees_1."Filer_ID",
            committees_1."Start_Date",
            committees_1."End_Date",
            committees_1."Ballot_Measure_Election"
           FROM public.committees committees_1
          WHERE (committees_1."Ballot_Measure_Election" IS NOT NULL)) committees ON ((((committees."Filer_ID")::text = (all_contributions."Filer_ID")::text) AND ((committees."Start_Date" IS NULL) OR (all_contributions."Tran_Date" >= committees."Start_Date")) AND ((committees."End_Date" IS NULL) OR (all_contributions."Tran_Date" <= committees."End_Date")))))
     JOIN public.elections ON (((committees."Ballot_Measure_Election")::text = (elections.name)::text)));


ALTER TABLE public.measure_contributions OWNER TO travis;

--
-- Name: combined_contributions; Type: VIEW; Schema: public; Owner: travis
--

CREATE VIEW public.combined_contributions AS
 SELECT candidate_contributions."Filer_ID",
    candidate_contributions."Entity_Cd",
    candidate_contributions."Tran_Amt1",
    candidate_contributions."Tran_NamF",
    candidate_contributions."Tran_NamL",
    candidate_contributions."Tran_Date",
    candidate_contributions."Tran_City",
    candidate_contributions."Tran_State",
    candidate_contributions."Tran_Zip4",
    candidate_contributions."Tran_Occ",
    candidate_contributions."Tran_Emp",
    candidate_contributions.location,
    candidate_contributions.election_name,
    candidate_contributions."Type",
    candidate_contributions."Committee_Type"
   FROM public.candidate_contributions
UNION ALL
 SELECT measure_contributions."Filer_ID",
    measure_contributions."Entity_Cd",
    measure_contributions."Tran_Amt1",
    measure_contributions."Tran_NamF",
    measure_contributions."Tran_NamL",
    measure_contributions."Tran_Date",
    measure_contributions."Tran_City",
    measure_contributions."Tran_State",
    measure_contributions."Tran_Zip4",
    measure_contributions."Tran_Occ",
    measure_contributions."Tran_Emp",
    measure_contributions.location,
    measure_contributions.election_name,
    measure_contributions."Type",
    measure_contributions."Committee_Type"
   FROM public.measure_contributions;


ALTER TABLE public.combined_contributions OWNER TO travis;

--
-- Name: committees_id_seq; Type: SEQUENCE; Schema: public; Owner: travis
--

CREATE SEQUENCE public.committees_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.committees_id_seq OWNER TO travis;

--
-- Name: committees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: travis
--

ALTER SEQUENCE public.committees_id_seq OWNED BY public.committees.id;


--
-- Name: elections_id_seq; Type: SEQUENCE; Schema: public; Owner: travis
--

CREATE SEQUENCE public.elections_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.elections_id_seq OWNER TO travis;

--
-- Name: elections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: travis
--

ALTER SEQUENCE public.elections_id_seq OWNED BY public.elections.id;


--
-- Name: independent_candidate_expenditures; Type: VIEW; Schema: public; Owner: travis
--

CREATE VIEW public.independent_candidate_expenditures AS
 SELECT c.election_name,
    c."FPPC" AS "Cand_ID",
    all_data."Filer_ID",
    committee."Filer_NamL",
    all_data."Exp_Date" AS "Expn_Date",
    all_data."Sup_Opp_Cd",
    all_data."Amount"
   FROM (((( SELECT ("496"."Filer_ID")::character varying AS "Filer_ID",
            "496"."Filer_NamL",
            "496"."Exp_Date",
            "496"."Cand_NamF",
            "496"."Cand_NamL",
            "496"."Amount",
            "496"."Sup_Opp_Cd",
            "496"."Tran_ID"
           FROM public."496"
        UNION
         SELECT "D-Expenditure"."Filer_ID",
            "D-Expenditure"."Filer_NamL",
            "D-Expenditure"."Expn_Date" AS "Exp_Date",
            "D-Expenditure"."Cand_NamF",
            "D-Expenditure"."Cand_NamL",
            "D-Expenditure"."Amount",
            "D-Expenditure"."Sup_Opp_Cd",
            "D-Expenditure"."Tran_ID"
           FROM public."D-Expenditure"
          WHERE (("D-Expenditure"."Expn_Code")::text = 'IND'::text)) all_data
     JOIN public.candidates c ON (((lower(TRIM(BOTH FROM concat(all_data."Cand_NamF", ' ', all_data."Cand_NamL"))) = lower((c."Candidate")::text)) OR (lower((c."Aliases")::text) ~~ lower(concat('%', TRIM(BOTH FROM concat(all_data."Cand_NamF", ' ', all_data."Cand_NamL")), '%'))))))
     JOIN public.elections e ON (((c.election_name)::text = (e.name)::text)))
     JOIN ( SELECT c_1."Filer_ID",
            c_1."Filer_NamL"
           FROM ( SELECT committees."Filer_ID",
                    committees."Filer_NamL",
                    row_number() OVER (PARTITION BY committees."Filer_ID" ORDER BY committees."Ballot_Measure_Election" DESC NULLS LAST) AS rn
                   FROM public.committees) c_1
          WHERE (c_1.rn = 1)) committee ON (((committee."Filer_ID")::text = (all_data."Filer_ID")::text)))
  WHERE (((e."Start_Date" IS NULL) OR (all_data."Exp_Date" >= e."Start_Date")) AND ((e."End_Date" IS NULL) OR (all_data."Exp_Date" <= e."End_Date")) AND (c."FPPC" IS NOT NULL) AND (all_data."Cand_NamL" IS NOT NULL));


ALTER TABLE public.independent_candidate_expenditures OWNER TO travis;

--
-- Name: office_elections; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public.office_elections (
    election_name character varying NOT NULL,
    title character varying(50) NOT NULL,
    label character varying NOT NULL,
    id integer NOT NULL
);


ALTER TABLE public.office_elections OWNER TO travis;

--
-- Name: office_elections_id_seq; Type: SEQUENCE; Schema: public; Owner: travis
--

CREATE SEQUENCE public.office_elections_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.office_elections_id_seq OWNER TO travis;

--
-- Name: office_elections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: travis
--

ALTER SEQUENCE public.office_elections_id_seq OWNED BY public.office_elections.id;


--
-- Name: referendums; Type: TABLE; Schema: public; Owner: travis
--

CREATE TABLE public.referendums (
    election_name character varying NOT NULL,
    "Measure_number" character varying(4) NOT NULL,
    "Short_Title" character varying NOT NULL,
    "Full_Title" character varying,
    "Summary" character varying,
    "VotersEdge" character varying,
    "Internal_notes" character varying,
    data_warning character varying,
    is_approved boolean,
    id integer NOT NULL
);


ALTER TABLE public.referendums OWNER TO travis;

--
-- Name: referendums_id_seq; Type: SEQUENCE; Schema: public; Owner: travis
--

CREATE SEQUENCE public.referendums_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.referendums_id_seq OWNER TO travis;

--
-- Name: referendums_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: travis
--

ALTER SEQUENCE public.referendums_id_seq OWNED BY public.referendums.id;


--
-- Name: calculations id; Type: DEFAULT; Schema: public; Owner: travis
--

ALTER TABLE ONLY public.calculations ALTER COLUMN id SET DEFAULT nextval('public.calculations_id_seq'::regclass);


--
-- Name: candidates id; Type: DEFAULT; Schema: public; Owner: travis
--

ALTER TABLE ONLY public.candidates ALTER COLUMN id SET DEFAULT nextval('public.candidates_id_seq'::regclass);


--
-- Name: committees id; Type: DEFAULT; Schema: public; Owner: travis
--

ALTER TABLE ONLY public.committees ALTER COLUMN id SET DEFAULT nextval('public.committees_id_seq'::regclass);


--
-- Name: elections id; Type: DEFAULT; Schema: public; Owner: travis
--

ALTER TABLE ONLY public.elections ALTER COLUMN id SET DEFAULT nextval('public.elections_id_seq'::regclass);


--
-- Name: office_elections id; Type: DEFAULT; Schema: public; Owner: travis
--

ALTER TABLE ONLY public.office_elections ALTER COLUMN id SET DEFAULT nextval('public.office_elections_id_seq'::regclass);


--
-- Name: referendums id; Type: DEFAULT; Schema: public; Owner: travis
--

ALTER TABLE ONLY public.referendums ALTER COLUMN id SET DEFAULT nextval('public.referendums_id_seq'::regclass);


--
-- Name: calculations calculations_pkey; Type: CONSTRAINT; Schema: public; Owner: travis
--

ALTER TABLE ONLY public.calculations
    ADD CONSTRAINT calculations_pkey PRIMARY KEY (id);


--
-- Name: candidates candidates_pkey; Type: CONSTRAINT; Schema: public; Owner: travis
--

ALTER TABLE ONLY public.candidates
    ADD CONSTRAINT candidates_pkey PRIMARY KEY (id);


--
-- Name: committees committees_pkey; Type: CONSTRAINT; Schema: public; Owner: travis
--

ALTER TABLE ONLY public.committees
    ADD CONSTRAINT committees_pkey PRIMARY KEY (id);


--
-- Name: elections elections_pkey; Type: CONSTRAINT; Schema: public; Owner: travis
--

ALTER TABLE ONLY public.elections
    ADD CONSTRAINT elections_pkey PRIMARY KEY (id);


--
-- Name: office_elections office_elections_pkey; Type: CONSTRAINT; Schema: public; Owner: travis
--

ALTER TABLE ONLY public.office_elections
    ADD CONSTRAINT office_elections_pkey PRIMARY KEY (id);


--
-- Name: referendums referendums_pkey; Type: CONSTRAINT; Schema: public; Owner: travis
--

ALTER TABLE ONLY public.referendums
    ADD CONSTRAINT referendums_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--

\unrestrict ZCaRcQhWRhOcim2tJyvcyJ59rLcLvq4ArqH850yBu1L1YrKAhPbZzYB6Oxn9aEy

