import json
from pathlib import Path
from typing import Dict, List
import polars
import pytest
from model.d_expenditures import DExpenditures
from model import election, transaction, filing, committee


def load_data(filename: str) -> List[dict]:
    ''' Load data filename from test_data dir '''
    return json.loads(
        (Path(__file__).parent / f'test_data/{filename}.json').read_text()
    )


@pytest.fixture(name='test_data')
def load_test_data() -> Dict[str, List[dict]]:
    '''
    Load test data from test_data dir specified by params list
    Return dict of str => list of dict where each inner dict is a record of datatype
    '''
    elections = election.Elections(load_data('elections')).df

    return {
        'transactions': polars.from_pandas(transaction.Transactions(load_data('transactions')).df),
        'filings': polars.from_pandas(filing.Filings(load_data('filings')).df),
        'committees': polars.from_pandas(
            committee.Committees(load_data('filers'), elections).df
        )
    }


def test_d_expenditures_does_not_raise(test_data):
    ''' Just test that it doesn't error out '''
    d_expends = DExpenditures(
        test_data['transactions'],
        test_data['filings'],
        test_data['committees']
    )

    df = d_expends.df

    assert df.shape[0] > 0
