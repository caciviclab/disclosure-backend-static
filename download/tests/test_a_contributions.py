"""
Test that A_Contributions model is complete
"""
import json
from pathlib import Path
import pandas as pd
import pytest
from model.a_contributions import A_Contributions
from model.committee import Committees
from model.election import Elections
from model.filing import Filings
from model.transaction import Transactions

@pytest.fixture(name='transactions')
def load_transactions():
    """ load transactions from json """
    with open('data/transactions.json', encoding='utf8') as f:
        yield Transactions(json.loads(f.read())).df

@pytest.fixture(name='filings')
def load_filings():
    """ load filings from json """
    with open('data/filings.json', encoding='utf8') as f:
        yield Filings(json.loads(f.read())).df

@pytest.fixture(name='elections')
def load_elections():
    """ load elections from json """
    with open('data/elections.json', encoding='utf8') as f:
        yield Elections(json.loads(f.read())).df

@pytest.fixture(name='committees')
def load_committees(elections):
    """ load committees from json """
    with open('data/filers.json', encoding='utf8') as f:
        yield Committees.from_filers(json.loads(f.read()), elections).df

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

    assert sorted(a_contributions.columns.to_list()) == sorted(expect_columns)
