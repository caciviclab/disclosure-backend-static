import json
from pathlib import Path
from typing import List
import polars as pl
import pytest
from model import committee, election, filing, transaction

def load_data(filename) -> List[dict]:
    ''' Load data by filename from JSON in test_data dir '''
    return json.loads(
        (Path(__file__).parent.parent / f'test_data/{filename}.json').read_text()
    )

@pytest.fixture(name='elections_df')
def load_elections_df() -> pl.DataFrame:
    ''' Get elections dataframe '''
    return election.Elections(load_data('elections')).pl

@pytest.fixture(name='committees_df')
def load_committees_df(elections_df) -> pl.DataFrame:
    ''' Get committees dataframe '''
    return committee.Committees(
        load_data('filers'),
        elections_df
    ).pl

@pytest.fixture(name='filings_df')
def load_filings_df() -> pl.DataFrame:
    ''' Get filings dataframe '''
    return filing.Filings(load_data('filings')).pl

@pytest.fixture(name='transactions_df')
def load_transactions_df() -> pl.DataFrame:
    ''' Get transactions dataframe '''
    return transaction.Transactions(load_data('transactions')).pl
