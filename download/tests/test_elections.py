import json
from pathlib import Path
import pytest
from model.election import Elections

@pytest.fixture(name='test_data_dir')
def declare_test_dir():
    ''' Return default test data dir '''
    return Path(__file__).parent / 'test_data' # TODO: Make this a reusable fixture

@pytest.fixture(name='elections_json')
def load_elections_json(test_data_dir):
    ''' Load elections JSON from disk '''
    return json.loads((test_data_dir / 'elections.json').read_text(encoding='utf8'))

def test_election_does_not_raise(elections_json):
    ''' Just check that it does't error out '''
    Elections(elections_json)
