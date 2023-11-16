"""
Test that A_Contributions model is complete
"""
import json
from pathlib import Path
from pprint import PrettyPrinter
import pandas as pd
import polars as pl
import pytest
from model.a_contributions import A_Contributions
from model.committee import Committees
from model.election import Elections
from model.filing import Filings
from model.transaction import Transactions

@pytest.fixture(name='data_dir')
def define_data_dir():
    """ Set data dir """
    return '.local/downloads'

@pytest.fixture(name='transactions')
def load_transactions(data_dir):
    """ load transactions from json """
    with open(f'{data_dir}/transactions.json', encoding='utf8') as f:
        return pl.from_pandas(Transactions(json.loads(f.read())).df)

@pytest.fixture(name='filings')
def load_filings(data_dir):
    """ load filings from json """
    with open(f'{data_dir}/filings.json', encoding='utf8') as f:
        return pl.from_pandas(Filings(json.loads(f.read())).df)

@pytest.fixture(name='elections')
def load_elections(data_dir):
    """ load elections from json """
    with open(f'{data_dir}/elections.json', encoding='utf8') as f:
        return Elections(json.loads(f.read())).df

@pytest.fixture(name='committees')
def load_committees(data_dir, elections):
    """ load committees from json """
    with open(f'{data_dir}/filers.json', encoding='utf8') as f:
        return pl.from_pandas(Committees.from_filers(json.loads(f.read()), elections).df)

def test_a_contributions_has_expected_fields(
    transactions,
    filings,
    committees
):
    """
    Test that A_Contributions has expect fields
    based on "\d A-Contributions" dumped from Postgres database disclosure-backend
    """
    a_contributions = A_Contributions(transactions, filings, committees).df

    expect_columns = pd.read_table(str(Path(__file__).parent / 'A-Contributions.schema.txt'),
        sep='|', header=1, skipinitialspace=True
    )
    expect_columns = expect_columns.rename(columns={
        expect_columns.columns[1]: 'column'
    })['column'].apply(lambda x: x.strip()).loc[1:].to_list()

    pp = PrettyPrinter()
    print('LEFT')
    pp.pprint(sorted(a_contributions.columns))
    print('RIGHT')
    pp.pprint(sorted(expect_columns))
    assert sorted(a_contributions.columns) == sorted(expect_columns)
