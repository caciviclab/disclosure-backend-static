""" This is the Committee model """
from typing import List
import pandas as pd
from sqlalchemy.types import String
from . import base

class Committees(base.BaseModel):
    """ A collection of committees """
    def __init__(self, data:List[dict]):
        super().__init__(data)
        self._dtypes = {
            'filer_nid': 'string',
            'Ballot_Measure_Election': 'string',
            'Filer_ID': 'string',
            'Filer_NamL': 'string',
            '_Status': 'string',
            '_Committee_Type': 'string',
            'Ballot_Measure': 'string',
            'Support_Or_Oppose': 'string',
            'candidate_controlled_id': 'string',
            'Start_Date': 'string',
            'End_Date': 'string',
            'data_warning': 'string',
            'Make_Active': 'string'
        }
        self._sql_dtypes = {
            'Ballot_Measure_Election': String,
            'Filer_ID': String,
            'Filer_NamL': String,
            '_Status': String,
            '_Committee_Type': String,
            'Ballot_Measure': String,
            'Support_Or_Oppose': String,
            'candidate_controlled_id': String,
            'Start_Date': String,
            'End_Date': String,
            'data_warning': String,
            'Make_Active': String
        }
        self._sql_cols = self._sql_dtypes.keys()
        self._sql_table_name = 'committees'

    @staticmethod
    def support_or_oppose(influence):
        """
        Return 'S' or 'O' code only for committees that support or oppose measures,
        or committees that oppose candidates
        """
        sup_opp_cd = 'S' if influence['doesSupport'] else 'O'

        if (influence['measure'] is not None or influence['candidate'] and sup_opp_cd == 'O'):
            return sup_opp_cd

    @classmethod
    def from_filers(cls, filer_records:List[dict], elections:pd.DataFrame):
        """ Reshape NetFile filer records """
        empty_election_influence = {
            'electionDate': None,
            'measure': None,
            'candidate': None,
            'doesSupport': None,
            'startDate': None,
            'endDate': None
        }
        return cls([
            {
                'filer_nid': f['filerNid'],
                'Ballot_Measure_Election': [
                    *elections[
                        elections['date'] == infl['electionDate']
                    ]['name'].array
                ][0],
                'Filer_ID': f['registrations'].get('CA SOS'),
                'Filer_NamL': infl.get('committeeName', f['filerName']),
                '_Status': 'INACTIVE' if f['isTerminated'] else 'ACTIVE',
                '_Committee_Type': (f['committeeTypes'][0]
                                    if len(f['committeeTypes']) == 1
                                    else 'Multiple Types'),
                'Ballot_Measure': infl['measure'].get('measureNumber') if infl['measure'] else None,
                'Support_Or_Oppose': cls.support_or_oppose(infl),
                'candidate_controlled_id': None, # TODO: link to candidates if candidate committee
                'Start_Date': infl['startDate'],
                'End_Date': infl['endDate'],
                'data_warning': None,
                'Make_Active': None
            } for f in filer_records
            for infl in (
                f['electionInfluences']
                if f['electionInfluences']
                else [ empty_election_influence ]
            )
            if f['registrations'].get('CA SOS')
        ])
