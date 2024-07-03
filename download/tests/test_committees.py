''' test Committees model '''
import json
from pathlib import Path
import pytest
from model.committee import Committees

def test_committees_does_not_raise(filers_json, elections):
    ''' Just test that Committees model does not error '''
    Committees(filers_json, elections)

def test_committees_pl_does_not_raise(filers_json, elections):
    ''' Just test that .pl method does not error '''
    df = Committees(filers_json, elections).df
    assert len(df)

def test_committees_pl_contains_expected_filers_names(filers_json, elections):
    ''' Check that it has the 24 names in filers test data '''
    df = Committees(filers_json, elections).df

    filer_names = sorted(df.select([ 'Filer_NamL' ]).to_series().to_list())
    expect_names = sorted([
        influence.get('committeeName', f['filerName']) for f in filers_json
        for influence in (
            f['electionInfluences'] or [{}]
        )    
    ])

    assert filer_names == expect_names
