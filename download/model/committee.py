""" This is the Committee model """
from typing import List
import polars as pl
from sqlalchemy.types import String
from . import base

class Committees(base.BaseModel):
    """ A collection of committees """
    def __init__(self, filers:List[dict], elections:pl.DataFrame):
        empty_election_influence = {
            'electionDate': None,
            'measure': None,
            'candidate': None,
            'doesSupport': None,
            'startDate': None,
            'endDate': None
        }

        super().__init__([
            {
                'filer_nid': int(f['filerNid']),
                # 'Ballot_Measure_Election': [ *elections[elections['date'] == infl['electionDate']]['name'].array, None ][0],
                'Ballot_Measure_Election': self._get_possibly_empty_ballot_measure_election(
                    elections,
                    infl
                ),
                'Filer_ID': f['registrations'].get('CA SOS'),
                'Filer_NamL': infl.get('committeeName', f['filerName']),
                '_Status': 'INACTIVE' if f['isTerminated'] else 'ACTIVE',
                '_Committee_Type': (f['committeeTypes'][0]
                                    if len(f['committeeTypes']) == 1
                                    else 'Multiple Types'),
                'Ballot_Measure': infl['measure'].get('measureNumber') if infl['measure'] else None,
                'Support_Or_Oppose': self.support_or_oppose(infl),
                'candidate_controlled_id': None, # TODO: link to candidates if candidate committee
                'Start_Date': infl['startDate'],
                'End_Date': infl['endDate'],
                'data_warning': None,
                'Make_Active': None
            } for f in filers
            for infl in (
                # TODO: This is slightly effed because some filers have duplicate electionInfluences
                # See: filer with filerName "Families in Action For Justice Fund"
                # I guess we have to dedupe electionInfluences blurg
                f['electionInfluences']
                if f['electionInfluences']
                else [ empty_election_influence ]
            )
            if f['registrations'].get('CA SOS')
        ])
        self._dtypes = {
            'filer_nid': int,
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
        self._pl_dtypes = {
            'filer_nid': pl.UInt64,
            'Ballot_Measure_Election': pl.Utf8,
            'Filer_ID': pl.Utf8,
            'Filer_NamL': pl.Utf8,
            '_Status': pl.Utf8,
            '_Committee_Type': pl.Utf8,
            'Ballot_Measure': pl.Utf8,
            'Support_Or_Oppose': pl.Utf8,
            'candidate_controlled_id': pl.Utf8,
            'Start_Date': pl.Utf8,
            'End_Date': pl.Utf8,
            'data_warning': pl.Utf8,
            'Make_Active': pl.Utf8
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

    @staticmethod
    def _get_possibly_empty_ballot_measure_election(elections: pl.DataFrame, influence: dict):
        '''
        The Ballot Measure Election is the election's slugified `name` like "oakland-march-2020".
        To get the BME for a committee, we match the `electionDate` of an `influence` object
        of the committee against election `date`. Then we unpack the results into a list,
        appending None in case no matches were found. Finally we return the first index of the
        list, which will contain either the matched election slug or None.
        '''
        return [
            *elections.lazy().filter(
                pl.col('date') == influence['electionDate']
            ).first().collect().get_column('name'),
            None
        ][0]
