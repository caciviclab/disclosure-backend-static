""" main, to run everything """
from collections import Counter
from datetime import datetime
import json
import pandas as pd
from sqlalchemy import create_engine
from model.a_contributions import A_Contributions
from model.committee import Committees
from model.election import Elections
from model.filing import Filings
from model.transaction import Transactions

from gdrive_datastore.gdrive import pull_data

DATA_DIR_PATH = '.local/downloads'
OUTPUT_DIR = '.local'

def unique_statuses(filers):
    """ What are the unique values for status? """
    return set(
        s['status'] for f in filers
        for s in f['statusList']
    )

def main():
    """ Do everyting """
    # pull data from gdrive and put it in .local/downloads
    pull_data(subfolder='main', default_folder='OpenDisclosure')

    with open(f'{DATA_DIR_PATH}/elections.json', encoding='utf8') as f:
        elections_json = json.loads(f.read())

    elections = Elections(elections_json)

    with open(f'{DATA_DIR_PATH}/filers.json', encoding='utf8') as f:
        filers = json.loads(f.read())

    committees = Committees(filers, elections.df)

    # A-Contribs:
    # join filers + filings + elections + transactions
    # transactions.filing_nid -> filings.filing_nid
    #   filings.filer_nid -> committees.filer_nid
    #     committees.Ballot_Measure_Election -> elections.Ballot_Measure_Election
    # where trans['transaction']['calTransactionType'] == 'F460A'
    with open(f'{DATA_DIR_PATH}/filings.json', encoding='utf8') as f:
        filings = Filings(json.loads(f.read())).pl

    with open(f'{DATA_DIR_PATH}/transactions.json', encoding='utf8') as f:
        records = json.loads(f.read())
        transactions = Transactions(records).pl

    a_contributions = A_Contributions(transactions, filings, committees.pl)
    a_contribs_df = a_contributions.df
    if not a_contribs_df.is_empty:
        print(a_contribs_df.drop(columns=[
            'BakRef_TID',
            'Bal_Name',
            'Bal_Juris',
            'Bal_Num',
            'Dist_No',
            'Form_Type',
            'Int_CmteId',
            'Juris_Cd',
            'Juris_Dscr',
            'Loan_Rate',
            'Memo_Code',
            'Memo_RefNo',
            'Off_S_H_Cd',
            'tblCover_Offic_Dscr',
            'tblCover_Office_Cd',
            'tblDetlTran_Office_Cd',
            'tblDetlTran_Offic_Dscr',
            'XRef_SchNm',
            'XRef_Match',
        ]).sample(n=20))

    elections.pl.write_csv(f'{OUTPUT_DIR}/elections.csv')
    committees.pl.write_csv(f'{OUTPUT_DIR}/committees.csv')
    a_contributions.df.write_csv(f'{OUTPUT_DIR}/a_contributions.csv')

if __name__ == '__main__':
    main()
