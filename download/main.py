""" main, to run everything """
from collections import Counter
from datetime import datetime
import json
import pandas as pd
import os
#from sqlalchemy import create_engine
from model.a_contributions import A_Contributions
from model.committee import Committees
from model.election import Elections
from model.filing import Filings
from model.transaction import Transactions

from gdrive_datastore.gdrive import pull_data

def get_last_status(status_list):
    """
    Return a tuple of index, status_item
    for max value of status_item['startDate']
    """

def unique_statuses(filers):
    """ What are the unique values for status? """
    return set(
        s['status'] for f in filers
        for s in f['statusList']
    )

def main():
    """ Do everyting """
    data_dir_path = '.local/downloads'

    # pull data from gdrive and put it in .local/downloads
    pull_data(subfolder='main', default_folder='OpenDisclosure')

    #engine = create_engine('postgresql+psycopg2://localhost/disclosure-backend-v2', echo=True)

    with open(f'{data_dir_path}/elections.json', encoding='utf8') as f:
        elections_json = json.loads(f.read())

    elections = Elections(elections_json)

    with open(f'{data_dir_path}/filers.json', encoding='utf8') as f:
        filers = json.loads(f.read())

    committees = Committees.from_filers(filers, elections.df)

    # A-Contribs:
    # join filers + filings + elections + transactions
    # transactions.filing_nid -> filings.filing_nid
    #   filings.filer_nid -> committees.filer_nid
    #     committees.Ballot_Measure_Election -> elections.Ballot_Measure_Election
    # where trans['transaction']['calTransactionType'] == 'F460A'
    with open(f'{data_dir_path}/filings.json', encoding='utf8') as f:
        filings = Filings(json.loads(f.read())).df

    with open(f'{data_dir_path}/transactions.json', encoding='utf8') as f:
        records = json.loads(f.read())
        transactions = Transactions(records).df

    a_contributions = A_Contributions(transactions, filings, committees.df)
    a_contribs_df = a_contributions.df
    if not a_contribs_df.empty:
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

    to_csv_dirpath = 'downloads/csv'
    os.makedirs(to_csv_dirpath, exist_ok=True)
    elections.df.to_csv(f'{to_csv_dirpath}/elections_v2.csv', index=False)
    committees.df.to_csv(f'{to_csv_dirpath}/committees_v2.csv', index=False)
    a_contributions.df.to_csv(f'{to_csv_dirpath}/a_contributions_v2.csv', index=False)

    '''
    with engine.connect() as conn:
        elections.to_sql(conn)
        committees.to_sql(conn)
        a_contributions.to_sql(conn)
    '''

if __name__ == '__main__':
    main()
