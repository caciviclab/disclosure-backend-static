import json
from pathlib import Path
import pytest
from model.election import Elections

def test_election_does_not_raise(elections_json):
    ''' Just check that it does't error out '''
    Elections(elections_json)
