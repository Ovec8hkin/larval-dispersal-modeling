import numpy as np
import math
from datetime import datetime, timedelta

import sys
sys.path.append('../')
from src import data

def get_month(dayofyear):
    return (datetime(1984, 1, 1) + timedelta(dayofyear+1)).month

def place_particles(x, y, n):
    r = 1000
    # random angle
    alpha = 2 * math.pi * np.random.random(n)
    # random radius
    rad = r * np.sqrt(np.random.random(n))
    # calculating coordinates
    px = rad * np.cos(alpha) + x
    py = rad * np.sin(alpha) + y
    return px, py

def seed_particles(pos, N, month_props, month_dates):
    #print(pos)
    x, y, m, p = pos[0], pos[1], pos[2], pos[3]
    n = N*p*month_props[m.astype(int)-1]
    n = np.round(n).astype(int)
    px, py = place_particles(x, y, n)
    #mask = month_masks[int(m)]
    date=month_dates[int(m)]
    ds=np.random.choice(date, size=px.size)
    
    max_depth = 130
    depths = np.random.uniform(0, max_depth, size=px.size)
    
    inter = np.ravel(np.column_stack((px, py, depths, ds)))
    return inter

def initialize_particles(df, N, spawn_start, spawn_end):
    #N = 1000000
    #spawn_start = 60
    #spawn_end = 151

    # Generate spawning dates for each particles
    spawn_mean = (spawn_start+spawn_end)/2  # Assume mean is halfway through season
    spawn_std = (spawn_end - spawn_start)/6 # 99% of particle spawned in season
    dates = np.random.normal(spawn_mean, spawn_std, N)
    dates = np.round(dates) # Round to nearest whole number day

    # Convert days of year into months
    to_months = np.vectorize(get_month)
    spawning_months = to_months(dates)

    # Compute proportion of dates in each month
    month_props = np.zeros(shape=(12,))
    unique = np.unique(spawning_months)
    for u in unique:
        mask = spawning_months == u
        total = mask.sum()
        month_props[u-1] = total/len(spawning_months)

    # Precompute the dates that fall in each month
    month_dates = {}
    for i in range(1, 13):
        mask = spawning_months == i
        month_dates[i] = dates[mask]

    # Pull relevant data from dataframe
    xs = df['lon'].to_numpy()
    ys = df['lat'].to_numpy()
    #xs, ys = data.project(lons, lats) # Project lat/lon into northing/easting coords
    months = df['month'].to_numpy()
    pred = df['pred_std'].to_numpy()
    d = np.hstack((xs.reshape(-1, 1), ys.reshape(-1, 1), months.reshape(-1, 1), pred.reshape(-1, 1)))

    # Seed particles at each position x, y for each month
    pos = np.array([seed_particles(x, N, month_props, month_dates) for x in d], dtype=object)
    pos = pos[np.array([y.size>0 for y in pos])] # Remove positions at which no particles were seeded
    pos = np.concatenate(pos) # Join position arrays into single 1D array
    pos = pos.reshape(-1, 4) # Reshape position array into 4 columns (x, y, h, date)

    return pos, dates, spawning_months

def save_particles_to_file(monthly_particles, s, y, m, output_dir):
    sp = s.lower().replace(" ", "_")
    fname = "../data/initial_positions/{}_{}{}.txt".format(sp, y, str(m).zfill(2))
    nums = np.arange(1, len(monthly_particles)+1)
    
    print(fname)
    np.savetxt(fname, monthly_particles, delimiter="\t", fmt=['%d', '%01.9f', '%01.9f', '%01.9f', '%01.2f'])

    with open(fname, "r+") as f:
        content = f.read()
        f.seek(0, 0)
        f.write(str(len(nums)-1).rstrip('\r\n') + '\n' + content)

    print("Finished initial save.")
    return fname