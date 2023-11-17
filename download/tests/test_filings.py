''' Test Filings model '''
import json
from pathlib import Path
import pytest
from model.filing import Filings

@pytest.fixture(name='test_data_dir')
def declare_test_data_dir():
    ''' Return default test data path '''
    return str(Path(__file__).parent / 'test_data')

@pytest.fixture(name='filings_json')
def load_filings_json(test_data_dir):
    ''' Return filing records JSON '''
    with open(f'{test_data_dir}/filings.json', encoding='utf8') as f:
        return json.load(f)

def test_filing_does_not_raise(filings_json):
    ''' Just test that it does not error '''
    Filings(filings_json)

def test_filing_pl_does_not_riase(filings_json):
    ''' Just test that .pl method does not error '''
    Filings(filings_json).pl
