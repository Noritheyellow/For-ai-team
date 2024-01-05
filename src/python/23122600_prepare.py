import sys
sys.path.append('../Dataset-Management-Library/mimic3wfdb')
import json
import argparse
import numpy as np
import pandas as pd
import psycopg2 as pg
import wfdb_util as wu
from itertools import starmap


with open('../Dataset-Management-Library/pgconf.json') as f:
    pg_conf = json.load(f)

conn = pg.connect(
    host=pg_conf['host'], 
    port=pg_conf['port'], 
    dbname=pg_conf['dbname'], 
    user=pg_conf['user'], 
    password=pg_conf['password']
)

with conn.cursor() as cursor:
    cursor.execute(
        "SELECT *                   \
            FROM view_raw_demographic\
        ")
    result = cursor.fetchall()
cursor.close() # confirm

mimic_table = pd.DataFrame(result, columns=['subject_id', 'gender', 'age', 'admittime', 'dischtime', 'weight_kg', 'height_inches', 'height_cm', 'bmi'])
mimic_table = mimic_table.astype({'subject_id':'uint16', 'age':'uint8', 'weight_kg':'float32', 'height_inches':'float32', 'height_cm':'float32', 'bmi':'float32'})

record_list = wu.get_record_df('../DataLake/mimic-iii_wfdb/')
record_list = record_list.query('record_name.str.contains("n")!=True').reset_index(drop=True)
record_list['recordtime'] = [pd.to_datetime(dt, format='%Y-%m-%d-%H-%M') for dt in map(lambda rec: rec[-1][8:-4], record_list.values)]
record_list['subject_id'] = record_list['subject_id'].astype(np.uint16)

mimic_join = pd.merge(left=mimic_table, right=record_list, how='inner', on=['subject_id'])
mimic_join = mimic_join.loc[(mimic_join['recordtime'] >= mimic_join['admittime'])&(mimic_join['recordtime'] < mimic_join['dischtime'])].sort_values(by=['subject_id', 'recordtime']).reset_index(drop=True)
mimic_join.sort_values(by='subject_id')

mimic_join.to_parquet(path='/root/Workspace/For-ai-team/data/intersectDemoWave.parquet.gzip', engine='pyarrow', compression='gzip')