"""
This is the Election model
"""
import os
from datetime import datetime
from sqlalchemy.types import String
from .base import BaseModel

class Elections(BaseModel):
    """ A collection of elections """
    def __init__(self, election_records):
        election_years = {}
        elections = []
        for el in election_records:
            caption = el['electionCaption'].split(' - ')
            election_year = caption[0][-4:]

            if election_year in election_years:
                election_years[election_year] += 1
            else:
                election_years[election_year] = 1

            elections.append({
                'location': 'Oakland',
                'date': el['electionDate'],
                'election_type': caption[1]
            })

        # Compose election slugs
        for el in elections:
            election_date = datetime.strptime(el['date'], '%Y-%m-%d')
            if os.name == 'nt':
                day_format_str = '%#d'
            else:
                day_format_str = '%-d'
            ordinal_day = self.ordinal(int(election_date.strftime(day_format_str)))
            election_year = el['date'][:4]
            long_date = datetime.strftime(election_date, f'%B {ordinal_day}, %Y')

            election_type = el.pop('election_type')

            namef = f'oakland-%s{election_year}'
            titlef = f'Oakland {long_date} %sElection'

            if election_years[election_year] > 1 and election_date.month != 11:
                name = (namef % (f'{datetime.strftime(election_date, "%B")}-')).lower()
            else:
                name = namef % ''
            title = titlef % (f'{election_type} ')

            el['name'] = name
            el['title'] = title

        super().__init__(elections)
        self._dtypes = {
            'title': 'string',
            'name': 'string',
            'location': 'string',
            'date': 'string'
        }
        self._sql_dtypes = {
            'title': String,
            'name': String,
            'location': String,
            'date': String
        }
        self._sql_cols = self._sql_dtypes.keys()
        self._sql_table_name = 'elections'

    @staticmethod
    def ordinal(n):
        """
        Swiped from SO
        https://stackoverflow.com/questions/9647202/ordinal-numbers-replacement#20007730
        """
        suffixes = 'tsnrhtdd'
        return f'{n}{suffixes[(n/10%10!=1)*(n%10<4)*n%10::4]}'
