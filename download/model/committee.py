""" This is the Committee model """
from typing import List
import polars as pl
from sqlalchemy.types import String
# Next line ingored because Pylint reports cannot find election in model
from . import base, election # pylint: disable=no-name-in-module

class Committees(base.BaseModel):
    """ A collection of committees """
    def __init__(self, filers:List[dict], elections:election.Elections):
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
            *elections.lazy.filter(
                pl.col('date') == influence['electionDate']
            ).first().collect().get_column('name'),
            None
        ][0]
