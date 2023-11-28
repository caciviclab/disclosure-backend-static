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

def add_totals(digests, total_key='total_contributions', total_group_key=None, filepath='build/_data/totals.json'):
    if total_group_key is None:
        total_group_key = total_key
    if not f'_{total_group_key}' in digests:
        digests[f'_{total_group_key}'] = {}
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
                for key in election_info:
                    election_total += election_info[key]
            else:
                election_total = election_info
            digests[f'_{total_group_key}'][election_name][f'_{total_key}_from_totals'] = round(election_total,2)
            total += election_total
        digests[f'_{total_group_key}'][f'_{total_key}_from_totals'] = round(total,2)

def add_tickets_total(digests, ticket_type='candidates', total_key='total_contributions', total_group_key=None):
    if total_group_key is None:
        total_group_key = total_key
    if not f'_{total_group_key}' in digests:
        digests[f'_{total_group_key}'] = {}
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
                            for key in ticket_info:
                                ticket_total += ticket_info[key]
                        elif type(ticket_info) == list:
                            for item in ticket_info:
                                ticket_total += item.get('amount',0) or 0
                        else:
                            ticket_total = ticket_info
                        election_total += ticket_total
                        total += ticket_total
            digests[f'_{total_group_key}'][election_name][f'_{total_key}_from_{ticket_type}'] = round(election_total,2)
    digests[f'_{total_group_key}'][f'_{total_key}_from_{ticket_type}'] = round(total,2)

def add_elections_total(digests, total_key='total_contributions', total_group_key=None, dirpath='build/_data/elections'):
    if total_group_key is None:
        total_group_key = total_key
    if not f'_{total_group_key}' in digests:
        digests[f'_{total_group_key}'] = {}
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
                        for key in election_info:
                            election_total += election_info[key]
                    elif type(election_info) == list:
                        for item in election_info:
                            election_total += item.get('amount',0) or 0
                    else:
                        election_total = election_info
                    total += election_total
                    digests[f'_{total_group_key}'][election_name][f'_{total_key}_from_elections'] = round(election_total,2)
    
    digests[f'_{total_group_key}'][f'_{total_key}_from_elections'] = round(total,2)

def add_combined_tickets_total(digests, total_keys=['total_contributions'], total_group_key=None):
    total_key = total_keys[0]
    if total_group_key is None:
        total_group_key = total_key
    total = 0
    digest_totals = digests[f'_{total_group_key}']
    total_from_tickets = 0
    for ticket_type in ['candidates','referendum_opposing','referendum_supporting']:
        for alt_total_key in total_keys:
            total_from_ticket = digest_totals.get(f'_{alt_total_key}_from_{ticket_type}',0) or 0
            total_from_tickets += total_from_ticket
    digest_totals[f'_{total_key}_from_tickets'] = round(total_from_tickets,2)

    for election_name in digest_totals.keys():
        if not election_name.startswith('_'):
            election_total_from_tickets = 0
            for ticket_type in ['candidates','referendum_opposing','referendum_supporting']:
                for alt_total_key in total_keys:
                    full_total_key = f'_{alt_total_key}_from_{ticket_type}'
                    election_total_from_ticket = digest_totals[election_name].get(full_total_key,0) or 0
                    election_total_from_tickets += election_total_from_ticket
            digest_totals[election_name][f'_{total_key}_from_tickets'] = round(election_total_from_tickets,2)

def main():
    digests = {}
    build_dir = 'build'
    filepath = f'{build_dir}/digests.json'
    collect_digests(digests, build_dir, exclude=[filepath])

    # contribution totals
    add_totals(digests, total_key='total_contributions')
    add_tickets_total(digests, ticket_type='candidates', total_key='total_contributions')
    add_tickets_total(digests, ticket_type='referendum_opposing', total_key='total_contributions')
    add_tickets_total(digests, ticket_type='referendum_supporting', total_key='total_contributions')
    add_combined_tickets_total(digests, total_keys=['total_contributions'])
    add_elections_total(digests, total_key='total_contributions')

    # contributions by type totals
    add_totals(digests, total_key='contributions_by_type', total_group_key='total_contributions')
    add_tickets_total(digests, ticket_type='candidates', total_key='contributions_by_type', total_group_key='total_contributions')
    add_tickets_total(digests, ticket_type='referendum_opposing', total_key='contributions_by_type', total_group_key='total_contributions')
    add_tickets_total(digests, ticket_type='referendum_supporting', total_key='contributions_by_type', total_group_key='total_contributions')
    add_combined_tickets_total(digests, total_keys=['contributions_by_type'], total_group_key='total_contributions')
    add_elections_total(digests, total_key='contributions_by_type', total_group_key='total_contributions')

    # small contributions totals
    add_tickets_total(digests, ticket_type='candidates', total_key='total_small_contributions', total_group_key='total_contributions')
    
    # contributions by source totals
    add_totals(digests, total_key='total_contributions_by_source', total_group_key='total_contributions')
    add_tickets_total(digests, ticket_type='candidates', total_key='contributions_by_origin', total_group_key='total_contributions')
    add_tickets_total(digests, ticket_type='referendum_opposing', total_key='contributions_by_region', total_group_key='total_contributions')
    add_tickets_total(digests, ticket_type='referendum_supporting', total_key='contributions_by_region', total_group_key='total_contributions')
    add_combined_tickets_total(digests, total_keys=['total_contributions_by_source','contributions_by_origin','contributions_by_region'], total_group_key='total_contributions')
    add_elections_total(digests, total_key='total_contributions_by_source', total_group_key='total_contributions')

    # expenditure totals
    add_tickets_total(digests, ticket_type='candidates', total_key='total_expenditures')

    # expenditures by type totals
    add_tickets_total(digests, ticket_type='candidates', total_key='expenditures_by_type', total_group_key='total_expenditures')

    # some totals that seems to have nothing
    add_tickets_total(digests, ticket_type='candidates',total_key='total_opposing', total_group_key='total_expenditures')
    add_tickets_total(digests, ticket_type='candidates',total_key='total_supporting', total_group_key='total_expenditures')

    # loans received totals
    add_tickets_total(digests, ticket_type='candidates', total_key='total_loans_received')

    print(f'Saving {filepath}')
    with open(filepath, 'w') as fp:
        json.dump(digests, fp, indent=1, sort_keys=True)

if __name__ == '__main__':
    main()
