import os
import json
import hashlib
import logging

logging.basicConfig(level=logging.INFO)

def round_floats(data):
    if type(data) == list:
        for i in range(len(data)):
            round_floats(data[i])
    else:
        for key in data:
            the_type = type(data[key])
            if the_type == dict:
                round_floats(data[key])
            elif the_type == list:
                round_floats(data[key])
            elif the_type == float:
                data[key] = round(data[key],2)

def sort_arrays(data):
    if type(data) == list:
        if len(data) > 0:
            if type(data[0]) == dict:
                data.sort(key=lambda x: tuple([str(x[key]) for key in x.keys()]))
            else:
                data.sort()
    else:
        for key in data:
            the_type = type(data[key])
            if the_type == dict:
                sort_arrays(data[key])
            elif the_type == list:
                sort_arrays(data[key])

def redact(data):
    if type(data) == dict:
        if 'date_processed' in data:
            # redact timestamps
            data['date_processed'] = '***'
        else:
            for key in data.keys():
                if key.startswith('top_') :
                    # For top contributors or top spenders lists, items with
                    # the same amount can be the same except for the name.  The ordering of these items
                    # with the same amount are undefined.  By ignoring the name when comparing
                    # these lists, we hide the differences caused by the undefined ordering for
                    # items with the same amount.  We ignore the name in this special case
                    # by redacting the name for items with duplicate amounts.
                    # Because the last item in the list has the potential to be a duplicate 
                    # of the next item that did not make the list, we also always redact the name
                    # of the last item.
                    last_item = None
                    for item in data[key]:
                        if 'name' in item:
                            # potentially redact the name of there's a name for an item
                            if 'total_contributions' in item:
                                # for top contributors, this key is used for the amount
                                amount_key = 'total_contributions'
                            elif 'total_spending' in item:
                                # for top spenders, this key is used for the amount
                                amount_key = 'total_spending'
                            else:
                                continue

                            # If there's a previous item, compare its amount with the
                            # current item and if they are the same, redact the name
                            amount = item[amount_key]
                            if last_item is not None:
                                last_amount = last_item[amount_key]
                                if amount == last_amount:
                                    last_item['name'] = '***'
                                    item['name'] = '***'
                        last_item = item
                    # always redact the name for the last item
                    if (last_item is not None) and ('name' in last_item):
                        last_item['name'] = '***'
                elif type(data[key]) == list:
                    for item in data[key]:
                        redact(item)
                else:
                    redact(data[key])
                        
def clean_data(data):
    redact(data)
    round_floats(data)
    sort_arrays(data)

def collect_digests(digests, subdir, exclude=[]):
    filenames = os.listdir(subdir)
    for filename in filenames:
        filepath = f'{subdir}/{filename}'
        if filepath in exclude:
            logging.info(f'Skipping {filepath}')
        elif os.path.isdir(filepath):
            collect_digests(digests,filepath)
        elif filename.endswith('.json'):
            with open(filepath, 'r', encoding='utf-8') as fp:
                #logging.info(filepath)
                data = json.load(fp)
                # clean data before generating digests
                clean_data(data)
                # generate digests
                if type(data) == dict:
                    for key in data:
                        sub_data = data[key]
                        datastr = json.dumps(sub_data, sort_keys=True).encode('utf-8') 

                        digest = hashlib.md5(datastr).hexdigest()
                        digests[f'{filepath}:{key}'] = digest
                else:
                    datastr = json.dumps(data, sort_keys=True).encode('utf-8') 

                    digest = hashlib.md5(datastr).hexdigest()
                    if filepath not in digests:
                        digests[filepath] = {}
                    digests[filepath] = digest.hexdigest()

def add_totals(digests, total_key='total_contributions', total_group_key=None, total_subkey=None, filepath='build/_data/totals.json'):
    ''' Sum totals from build/_data/totals.json and add to build/digests.json
    
    This method will look for values for the key specified by `total_key` in the
    totals.json file, which contains totals for all elections, and add them
    all together to get an overall total and save it to build/digests.json.  The
    totals for each election are also saved.  All the numbers are grouped in
    build/digests.json under the `total_group_key` key if specified.  Otherwise,
    the numbers are groupd in build/digests.json under the `total_key` key.
    '''

    # prepare location to save totals
    if total_subkey is None:
        full_total_key = f'_{total_key}_from_totals'
    else:
        full_total_key = f'_{total_key}_{total_subkey}_from_totals'
    if total_group_key is None:
        total_group_key = total_key
    if not f'_{total_group_key}' in digests:
        digests[f'_{total_group_key}'] = {}
    # sum totals and save to digests
    with open(filepath, 'r', encoding='utf-8') as fp:
        #logging.info(filepath)
        data = json.load(fp)
        total = 0
        for election_name in data.keys():
            election = data[election_name]
            if not election_name in digests[f'_{total_group_key}']:
                digests[f'_{total_group_key}'][election_name] = {}
            election_info = election[total_key]
            election_total = 0
            if type(election_info) == dict:
                if total_subkey is None:
                    for key in election_info:
                        election_total += election_info[key]
                else:
                    election_total += election_info.get(total_subkey,0) or 0
            else:
                election_total = election_info
            digests[f'_{total_group_key}'][election_name][full_total_key] = round(election_total,2)
            total += election_total
        digests[f'_{total_group_key}'][full_total_key] = round(total,2)

def add_tickets_total(digests, ticket_type='candidates', total_key='total_contributions', total_group_key=None, total_subkey=None):
    ''' Sum totals from JSON files under build/_data/<ticket_type> and add to build/digests.json
    
    This method will look for values for the key specified by `total_key` in the
    JSON files, which contain totals per instance (ie per candidate), and add them
    all together to get an overall total and save it to build/digests.json.  The
    totals for each election are also saved.  All the numbers are grouped in
    build/digests.json under the `total_group_key` key if specified.  Otherwise,
    the numbers are groupd in build/digests.json under the `total_key` key.
    '''

    # prepare location to save totals
    if total_subkey is None:
        full_total_key = f'_{total_key}_from_{ticket_type}'
    else:
        full_total_key = f'_{total_key}_{total_subkey}_from_{ticket_type}'
    if total_group_key is None:
        total_group_key = total_key
    if not f'_{total_group_key}' in digests:
        digests[f'_{total_group_key}'] = {}
    # sum totals and save to digests
    dirpath=f'build/_data/{ticket_type}'
    total = 0
    regions = os.listdir(dirpath)
    for region in regions:
        elections = os.listdir(f'{dirpath}/{region}')
        for election in elections:
            election_year = election.split('-')[0]
            election_name = f'{region}-{election_year}'
            if not election_name in digests[f'_{total_group_key}']:
                digests[f'_{total_group_key}'][election_name] = {}
            election_total = 0
            filenames = os.listdir(f'{dirpath}/{region}/{election}')
            for filename in filenames:
                if filename.endswith('.json'):
                    filepath = f'{dirpath}/{region}/{election}/{filename}'
                    with open(filepath, 'r', encoding='utf-8') as fp:
                        data = json.load(fp)
                        if ('supporting_money' in data) and (total_key in data['supporting_money']):
                            ticket_info = data['supporting_money'].get(total_key,0) or 0
                        elif ('opposing_money' in data) and (total_key in data['opposing_money']):
                            ticket_info = data['opposing_money'].get(total_key,0) or 0
                        else:
                            ticket_info = data.get(total_key,0) or 0
                        ticket_total = 0
                        if type(ticket_info) == dict:
                            # determine if we are pulling from one subkey or all subkeys
                            if total_subkey is None:
                                for key in ticket_info:
                                    ticket_total += ticket_info[key]
                            else:
                                ticket_total += ticket_info[total_subkey]
                        elif type(ticket_info) == list:
                            for item in ticket_info:
                                ticket_total += item.get('amount',0) or 0
                        else:
                            ticket_total = ticket_info
                        election_total += ticket_total
                        total += ticket_total
            digests[f'_{total_group_key}'][election_name][full_total_key] = round(election_total,2)
    digests[f'_{total_group_key}'][full_total_key] = round(total,2)

def add_elections_total(digests, total_key='total_contributions', total_group_key=None, total_subkey=None, dirpath='build/_data/elections'):
    ''' Sum totals from JSON files under build/_data/elections and add to build/digests.json
    
    This method will look for values for the key specified by `total_key` in the
    JSON files, which contain totals per election, and add them
    all together to get an overall total and save it to build/digests.json.  The
    totals for each election are also saved.  All the numbers are grouped in
    build/digests.json under the `total_group_key` key if specified.  Otherwise,
    the numbers are groupd in build/digests.json under the `total_key` key.
    '''

    # prepare location to save totals
    if total_subkey is None:
        full_total_key = f'_{total_key}_from_elections'
    else:
        full_total_key = f'_{total_key}_{total_subkey}_from_elections'
    if total_group_key is None:
        total_group_key = total_key
    if not f'_{total_group_key}' in digests:
        digests[f'_{total_group_key}'] = {}
    # sum totals and save to digests
    total = 0
    regions = os.listdir(dirpath)
    for region in regions:
        filenames = os.listdir(f'{dirpath}/{region}')
        for filename in filenames:
            if filename.endswith('.json'):
                election = filename.replace('.json','')
                election_year = election.split('-')[0]
                election_name = f'{region}-{election_year}'
                if not election_name in digests[f'_{total_group_key}']:
                    digests[f'_{total_group_key}'][election_name] = {}
                filepath = f'{dirpath}/{region}/{filename}'
                with open(filepath, 'r', encoding='utf-8') as fp:
                    data = json.load(fp)
                    election_info = data.get(total_key,0) or 0
                    election_total = 0
                    if type(election_info) == dict:
                        if total_subkey is None:
                            for key in election_info:
                                election_total += election_info[key]
                        else:
                            election_total += election_info.get(total_subkey,0) or 0
                    elif type(election_info) == list:
                        for item in election_info:
                            election_total += item.get('amount',0) or 0
                    else:
                        election_total = election_info
                    total += election_total
                    digests[f'_{total_group_key}'][election_name][full_total_key] = round(election_total,2)
    
    digests[f'_{total_group_key}'][full_total_key] = round(total,2)

def add_combined_tickets_total(digests, total_keys=['total_contributions'], total_group_key=None, total_subkey=None):
    ''' Combine the totals for candidates and referendums in build/digests.json as `ticket` totals
    
    This method will look for values for the keys specified by `total_keys` build/digests.json
    that were totaled from candidates and referendums.  Candidate and referendum totals are
    combined for a total from `tickets`, which can then be compared to the other totals coming from
    elections.  In other words, the totals from election JSON files include both candidates
    and referendums, so we are trying to match those numbers.
    '''

    # prepare location to save totals
    total_key = total_keys[0]
    if total_subkey is None:
        full_total_key = f'_{total_key}_from_tickets'
    else:
        full_total_key = f'_{total_key}_{total_subkey}_from_tickets'
    if total_group_key is None:
        total_group_key = total_key
    digest_totals = digests[f'_{total_group_key}']
    # sum totals and save to digests
    total_from_tickets = 0
    for ticket_type in ['candidates','referendum_opposing','referendum_supporting']:
        for alt_total_key in total_keys:
            if total_subkey is None:
                full_alt_total_key = f'_{alt_total_key}_from_{ticket_type}'
            else:
                full_alt_total_key = f'_{alt_total_key}_{total_subkey}_from_{ticket_type}'
            total_from_ticket = digest_totals.get(full_alt_total_key,0) or 0
            total_from_tickets += total_from_ticket
    digest_totals[full_total_key] = round(total_from_tickets,2)

    for election_name in digest_totals.keys():
        if not election_name.startswith('_'):
            election_total_from_tickets = 0
            for ticket_type in ['candidates','referendum_opposing','referendum_supporting']:
                for alt_total_key in total_keys:
                    if total_subkey is None:
                        full_alt_total_key = f'_{alt_total_key}_from_{ticket_type}'
                    else:
                        full_alt_total_key = f'_{alt_total_key}_{total_subkey}_from_{ticket_type}'
                    election_total_from_ticket = digest_totals[election_name].get(full_alt_total_key,0) or 0
                    election_total_from_tickets += election_total_from_ticket
            digest_totals[election_name][full_total_key] = round(election_total_from_tickets,2)

def add_combined_total(digests, full_total_keys=['_total_contributions_from_totals'], total_group_key=None, total_final_key=None):
    ''' Combine the totals in build/digests.json as new totals
    
    This method will look for values for the keys specified by `full_total_keys` in build/digests.json
    that were totaled earlier.  The totals are combined for a new total, which can then be compared 
    to the other totals that are expected to match.
    '''

    # prepare location to save totals
    if total_final_key is None:
        total_final_key = full_total_keys[0]
    if total_group_key is None:
        total_group_key = total_final_key
    digest_totals = digests[f'_{total_group_key}']

    # sum totals and save to digests
    combined_total = 0
    for full_alt_total_key in full_total_keys:
        one_total = digest_totals.get(full_alt_total_key,0) or 0
        combined_total += one_total
    digest_totals[f'_{total_final_key}'] = round(combined_total,2)

    # sum totals for elections and save to digests
    for election_name in digest_totals.keys():
        if not election_name.startswith('_'):
            combined_election_total = 0
            for full_alt_total_key in full_total_keys:
                one_election_total = digest_totals[election_name].get(full_alt_total_key,0) or 0
                combined_election_total += one_election_total
            digest_totals[election_name][f'_{total_final_key}'] = round(combined_election_total,2)

def remove_total(digests, full_total_keys=['_total_contributions_from_totals'], total_group_key=None):
    ''' Remove the totals in build/digests.json that were only used to combine totals
    
    This method will look for the keys specified by `full_total_keys` in build/digests.json.  
    These totals are removed since they are not used for comparison.
    '''

    # prepare location to remove totals
    total_final_key = full_total_keys[0]
    if total_group_key is None:
        total_group_key = total_final_key
    digest_totals = digests[f'_{total_group_key}']

    # remove totals from digests
    combined_total = 0
    for full_alt_total_key in full_total_keys:
        digest_totals.pop(full_alt_total_key,None)

    # remove totals from elections in digests
    for election_name in digest_totals.keys():
        if not election_name.startswith('_'):
            for full_alt_total_key in full_total_keys:
                digest_totals[election_name].pop(full_alt_total_key,None)

def remove_election_totals(digests, election_keys=['_total_contributions_from_totals'], total_group_key=None):
    ''' Remove the election totals in build/digests.json for a group
    
    This method will look for the keys specified by `election_keys` in build/digests.json.  
    These election totals are removed to reduce noise.
    '''

    # prepare location to remove totals
    digest_totals = digests[f'_{total_group_key}']

    # remove election totals from digests
    for election_key in election_keys:
        digest_totals.pop(election_key,None)

def collect_totals(digests, build_dir):
    ''' Add totals to digests object to check calculations

    This method adds overall totals calculated from elections and candidates output data
    as a way to watch that calculations aren't broken when code is changed.  There are a lot
    of intermediary calculations that are made and added to digests in order to reach
    the desired final calculations. These intermediary calculations are removed at the end
    so that only a few key overall totals remain to be recorded in digests.json.  If
    there is an intended change recorded in digests.json, it should be checked in so that
    differences can be captured.
    '''

    # contribution totals
    add_totals(digests, total_key='total_contributions')
    add_tickets_total(digests, ticket_type='candidates', total_key='total_contributions')
    add_tickets_total(digests, ticket_type='referendum_opposing', total_key='total_contributions')
    add_tickets_total(digests, ticket_type='referendum_supporting', total_key='total_contributions')
    add_elections_total(digests, total_key='total_contributions')
    add_combined_tickets_total(digests, total_keys=['total_contributions'])

    # loans received totals
    add_tickets_total(digests, ticket_type='candidates', total_key='total_loans_received', total_group_key='total_contributions')

    # contributions by type totals
    add_totals(digests, total_key='contributions_by_type', total_group_key='total_contributions')
    add_tickets_total(digests, ticket_type='candidates', total_key='contributions_by_type', total_group_key='total_contributions')
    add_tickets_total(digests, ticket_type='referendum_opposing', total_key='contributions_by_type', total_group_key='total_contributions')
    add_tickets_total(digests, ticket_type='referendum_supporting', total_key='contributions_by_type', total_group_key='total_contributions')
    add_elections_total(digests, total_key='contributions_by_type', total_group_key='total_contributions')
    add_combined_tickets_total(digests, total_keys=['contributions_by_type'], total_group_key='total_contributions')
    add_combined_total(digests, full_total_keys=['_contributions_by_type_from_tickets','_total_loans_received_from_candidates'], total_group_key='total_contributions', total_final_key='total_contributions_by_type_with_loans_from_tickets')
    add_combined_total(digests, full_total_keys=['_contributions_by_type_from_elections','_total_loans_received_from_candidates'], total_group_key='total_contributions', total_final_key='total_contributions_by_type_with_loans_from_elections')
    add_combined_total(digests, full_total_keys=['_contributions_by_type_from_totals','_total_loans_received_from_candidates'], total_group_key='total_contributions', total_final_key='total_contributions_by_type_with_loans_from_totals')

    # unitemized totals
    add_totals(digests, total_key='contributions_by_type', total_group_key='total_contributions', total_subkey='Unitemized')
    add_tickets_total(digests, ticket_type='candidates', total_key='contributions_by_type', total_group_key='total_contributions', total_subkey='Unitemized')
    add_tickets_total(digests, ticket_type='referendum_opposing', total_key='contributions_by_type', total_group_key='total_contributions', total_subkey='Unitemized')
    add_tickets_total(digests, ticket_type='referendum_supporting', total_key='contributions_by_type', total_group_key='total_contributions', total_subkey='Unitemized')
    add_elections_total(digests, total_key='contributions_by_type', total_group_key='total_contributions', total_subkey='Unitemized')
    add_combined_tickets_total(digests, total_keys=['contributions_by_type'], total_group_key='total_contributions', total_subkey='Unitemized')

    # small contributions totals
    add_tickets_total(digests, ticket_type='candidates', total_key='total_small_contributions', total_group_key='total_contributions')
    
    # contributions by source totals
    add_totals(digests, total_key='total_contributions_by_source', total_group_key='total_contributions')
    add_tickets_total(digests, ticket_type='candidates', total_key='contributions_by_origin', total_group_key='total_contributions')
    add_tickets_total(digests, ticket_type='referendum_opposing', total_key='contributions_by_region', total_group_key='total_contributions')
    add_tickets_total(digests, ticket_type='referendum_supporting', total_key='contributions_by_region', total_group_key='total_contributions')
    add_elections_total(digests, total_key='total_contributions_by_source', total_group_key='total_contributions')
    add_combined_tickets_total(digests, total_keys=['total_contributions_by_source','contributions_by_origin','contributions_by_region'], total_group_key='total_contributions')
    add_combined_total(digests, full_total_keys=['_total_contributions_by_source_from_tickets','_contributions_by_type_Unitemized_from_candidates','_total_loans_received_from_candidates'], total_group_key='total_contributions', total_final_key='total_contributions_by_source_with_unitemized_from_tickets')
    add_combined_total(digests, full_total_keys=['_total_contributions_by_source_from_elections','_contributions_by_type_Unitemized_from_elections','_total_loans_received_from_candidates'], total_group_key='total_contributions', total_final_key='total_contributions_by_source_with_unitemized_from_elections')
    add_combined_total(digests, full_total_keys=['_total_contributions_by_source_from_totals','_contributions_by_type_Unitemized_from_totals','_total_loans_received_from_candidates'], total_group_key='total_contributions', total_final_key='total_contributions_by_source_with_unitemized_from_totals')


    # expenditure totals
    add_tickets_total(digests, ticket_type='candidates', total_key='total_expenditures')

    # expenditures by type totals
    add_tickets_total(digests, ticket_type='candidates', total_key='expenditures_by_type', total_group_key='total_expenditures')

    # some totals that seems to have nothing
    add_tickets_total(digests, ticket_type='candidates',total_key='total_opposing', total_group_key='total_expenditures')
    add_tickets_total(digests, ticket_type='candidates',total_key='total_supporting', total_group_key='total_expenditures')

    # remove unused totals
    remove_total(digests, full_total_keys=[
        '_contributions_by_origin_from_candidates'
        ,'_contributions_by_region_from_referendum_opposing'
        ,'_contributions_by_region_from_referendum_supporting'
        ,'_contributions_by_type_Unitemized_from_candidates'
        ,'_contributions_by_type_Unitemized_from_referendum_opposing'
        ,'_contributions_by_type_Unitemized_from_referendum_supporting'
        ,'_contributions_by_type_from_candidates'
        ,'_contributions_by_type_from_referendum_opposing'
        ,'_contributions_by_type_from_referendum_supporting'
        ,'_contributions_by_type_from_tickets'
        ,'_contributions_by_type_from_elections'
        ,'_contributions_by_type_from_totals'
        ,'_total_contributions_from_candidates'
        ,'_total_contributions_from_referendum_opposing'
        ,'_total_contributions_from_referendum_supporting'
        ,'_total_small_contributions_from_candidates'
        ,'_total_loans_received_from_candidates'
        ], total_group_key='total_contributions')
    remove_total(digests, full_total_keys=['_total_contributions_by_source_from_tickets','_contributions_by_type_Unitemized_from_tickets'], total_group_key='total_contributions')
    remove_total(digests, full_total_keys=['_total_contributions_by_source_from_elections','_contributions_by_type_Unitemized_from_elections'], total_group_key='total_contributions')
    remove_total(digests, full_total_keys=['_total_contributions_by_source_from_totals','_contributions_by_type_Unitemized_from_totals'], total_group_key='total_contributions')

    # remove old election totals
    remove_election_totals(digests, election_keys=[
        'oakland-2014'
        ,'oakland-2016'
        ,'oakland-2018'
        ,'oakland-2020'
        ,'berkeley-2018'
        ,'sf-2016'
        ,'sf-2018'
        ,'sf-june-2018'
    ], total_group_key='total_contributions')


def main():
    digests = {}
    build_dir = 'build'
    filepath = f'{build_dir}/digests.json'
    collect_digests(digests, build_dir, exclude=[filepath])
    collect_totals(digests, build_dir)

    print(f'Saving {filepath}')
    with open(filepath, 'w') as fp:
        json.dump(digests, fp, indent=1, sort_keys=True)

if __name__ == '__main__':
    main()
