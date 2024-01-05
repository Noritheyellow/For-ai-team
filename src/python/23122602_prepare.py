import sys
path = '../Dataset-Management-Library'
sys.path.append(f'{path}/mimic3wfdb')
import asyncio
import argparse
import numpy as np
import pandas as pd
import wfdb_util as wu


async def get_record():
   futures = [asyncio.create_task(wu.async_get_field('/root/Workspace/DataLake/mimic-iii_wfdb/', rec)) for rec in dataset.record_name.values]
   results = await asyncio.gather(*futures)
   return results
    
parser = argparse.ArgumentParser()
parser.add_argument('files', nargs='*', help='file for processing')
args = parser.parse_args()

dataset = pd.read_parquet(args.files[0]) # ../data/intersectDemoWave.parquet.gzip

# PLETH, ABP 둘 다 가진 record만 가져오기
loop = asyncio.get_event_loop()
results = np.array(loop.run_until_complete(get_record()), dtype=object)
loop.close()

record_of_interest = np.array(list(map(lambda res: res[0], filter(lambda res: all(item in res[-1] for item in ['PLETH', 'ABP']), results))))

dataset = dataset.loc[dataset['record_name'].isin(list(record_of_interest))].reset_index(drop=True)

dataset.to_parquet('/root/Workspace/For-ai-team/data/interestDemoWave.parquet.gzip', engine='pyarrow', compression='gzip')