import os
import json
import hashlib
import logging

logging.basicConfig(encoding='utf-8', level=logging.INFO)

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
            data['date_processed'] = '***'
        else:
            for key in data.keys():
                if key.startswith('top_') :
                    # Redact names for items with duplicate amounts and last item in case the next
                    # was duplicated.  We have to do this now because the ordering for these lists
                    # are undefined by the amounts are the same
                    last_item = None
                    for item in data[key]:
                        if 'name' in item:
                            if 'total_contributions' in item:
                                amount_key = 'total_contributions'
                            elif 'total_spending' in item:
                                amount_key = 'total_spending'
                            else:
                                continue

                            amount = item[amount_key]
                            if last_item is not None:
                                last_amount = last_item[amount_key]
                                if amount == last_amount:
                                    last_item['name'] = '***'
                                    item['name'] = '***'
                        last_item = item
                    if (last_item is not None) and ('name' in last_item):
                        last_item['name'] = '***'
                elif type(data[key]) == list:
                    for item in data[key]:
                        redact(item)
                else:
                    redact(data[key])
                        
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
                logging.info(filepath)
                data = json.load(fp)
                # clean data before generating digests
                redact(data)
                round_floats(data)
                sort_arrays(data)
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

def main():
    digests = {}
    build_dir = 'build'
    filepath = f'{build_dir}/digests.json'
    collect_digests(digests, build_dir, exclude=[filepath])
    print(f'Saving {filepath}')
    with open(filepath, 'w') as fp:
        json.dump(digests, fp, indent=1, sort_keys=True)

if __name__ == '__main__':
    main()