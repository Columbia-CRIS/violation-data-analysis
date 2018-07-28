import rpy2
from rpy2.robjects import r, pandas2ri
import pandas as pd
from sklearn.metrics import confusion_matrix
from sklearn.metrics import accuracy_score
import math
import numpy as np
from operator import mul

#exponential discount factor
def exp(s):
    e = math.e
    b = (1-e**-11)/(e-e*s)
    a = s + 1/(e*b)
    return a,b

def reset_correction(file_path):
    pandas2ri.activate()
    rf=r['load'](file_path)
    
    df = pd.DataFrame(data=r['in_sample_result'])
    df_bad = df.loc[df['SEVERE'] == 1]
    bad_mines = set(df_bad['MINE_ID'])
    all_mines = set(df['MINE_ID'])
    good_mines = all_mines - bad_mines
    
    dfs = []
    for mine in set(df_bad['MINE_ID']):
        df_mine = df.loc[df['MINE_ID'] == mine]
        
        real = list(df_mine['SEVERE'])
        pred = list(df_mine['PREDICTION'])
        prob = list(df_mine['PROBABILITY'])
        
        counts = [real[0]]
        for i in range(1,len(pred)):
            c = real[i] + counts[i-1]
            counts.append(c)

        #calculate time since accident
        time = [0]
        begin = 1
        for i in range(1,len(counts)):
            if counts[i] == 0:
                time.append(0)
            else:
                if counts[i-1] < counts[i]:
                    time.append(0)
                    begin = 1
                else:
                    if time[i-1] + 1 > 12:
                        time.append(0)
                        begin = 0
                    else:
                        if begin == 1:
                            time.append(time[i-1]+1)
                        else:
                            time.append(0)

        #calculate discount factor. becomes less generous with more accidents, and decays over 3 years
        e = math.e
        adj = [1]
        i = 1
        while i < len(counts):
            if counts[i] == 0:
                adj.append(1)
            else:
                if time[i] == 0:
                    if counts[i] > counts[i-1] and counts[i] > 1:
                        if adj[i-1] == 1:
                            adj.append(1)
                        else:
                            adj.append(a - e**(-1*(time[i-1]+1 + counts[i-1] -2))/b)        
                    else: 
                        adj.append(1)

                elif counts[i] == 1 and time[i] == 1:
                    adj.append(0)
                    s = prob[i]
                else:
                    a,b = exp(s)
                    adj.append(a - e**(-1*(time[i-1] + counts[i] -1))/b)
            i += 1

        df_mine = df_mine.assign(DISCOUNT=pd.Series(adj).values)
        new_prob = list(map(mul, df_mine['PROBABILITY'], df_mine['DISCOUNT']))
        
        df_mine = df_mine.assign(NEW_PROB=pd.Series(new_prob).values)
        df_mine['NEW_PRED'] = np.where(df_mine['NEW_PROB']>=.5, 1, 0)

        dfs.append(df_mine)

    for mine in good_mines:
        df_mine = df.loc[df['MINE_ID'] == mine]
        test = df_mine.rename(index=str, columns={"PREDICTION": "NEW_PRED"})
        dfs.append(test)

    result = pd.concat(dfs)
    df_tmp = result[['CURRENT_MINE_NAME',
                     'MINE_ID',
                     'YEAR',
                     'QUARTER',
                     'NUM_DEATH',
                     'NUM_DIS',
                     'SEVERE',
                     'NEW_PROB',
                     'NEW_PRED']]
    df_out = df_tmp.rename(index=str, columns={'NEW_PRED':'PREDICTION','NEW_PROB':'PROBABILITY'})
    
    #output new prediction results
    df_out.to_csv('outputResults.csv')
    

def main():
    reset_correction('./Result_clogit.RData')
    
    
main()
