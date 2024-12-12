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

@pytest.fixture(name='elections_json')
def load_elections_json() -> List[dict]:
    ''' Load elections JSON from disk '''
    return load_data('elections')

@pytest.fixture(name='filers_json')
def load_filers_json() -> List[dict]:
    ''' Load filers JSON from disk '''
    return load_data('filers')

@pytest.fixture(name='filings_json')
def load_filings_json() -> List[dict]:
    ''' Load filings JSON from disk '''
    return load_data('filings')

@pytest.fixture(name='transactions_json')
def load_transactions_json() -> List[dict]:
    ''' Load transactions JSON from disk '''
    return load_data('transactions')

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
def load_transactions_df(transactions_json) -> pl.DataFrame:
    ''' Get transactions dataframe '''
    return transaction.Transactions(transactions_json).pl
