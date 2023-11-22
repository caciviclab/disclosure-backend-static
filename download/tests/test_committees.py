''' test Committees model '''
import json
from pathlib import Path
import pytest
from model.committee import Committees
from model.election import Elections

from pprint import PrettyPrinter

@pytest.fixture(name='test_data_dir')
def declare_test_dir():
    ''' Return default test data dir '''
    return str(Path(__file__).parent / 'test_data') # TODO: Make this a reusable fixture

@pytest.fixture(name='filers_json')
def load_filers_json(test_data_dir):
    ''' load filer records JSON '''
    with open(f'{test_data_dir}/filers.json', encoding='utf8') as f:
        return json.load(f)
    
@pytest.fixture(name='elections_df')
def load_elections_df(test_data_dir):
    ''' load elections as Pandas DataFrame '''
    with open(f'{test_data_dir}/elections.json', encoding='utf8') as f:
        return Elections(json.load(f)).df

def test_committees_does_not_raise(filers_json, elections_df):
    ''' Just test that Committees model does not error '''
    Committees(filers_json, elections_df)

def test_committees_pl_does_not_raise(filers_json, elections_df):
    ''' Just test that .pl method does not error '''
    df = Committees(filers_json, elections_df).pl
    assert len(df)

def test_committees_pl_contains_expected_filers_names(filers_json, elections_df):
    ''' Check that it has the 24 names in filers test data '''
    df = Committees(filers_json, elections_df).pl

    filer_names = sorted(df.select([ 'Filer_NamL' ]).to_series().to_list())
    expect_names = sorted([
        influence.get('committeeName', f['filerName']) for f in filers_json
        for influence in (
            f['electionInfluences'] or [{}]
        )    
    ])

    assert filer_names == expect_names
