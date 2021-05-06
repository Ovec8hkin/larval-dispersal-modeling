import glob
import argparse
import numpy as np
import os
import shutil
import pandas as pd
from datetime import datetime, timedelta

import data as data

import sys
sys.path.append('.')
import initialize_larvae as init
	
if __name__ == "__main__":
	
	parser = argparse.ArgumentParser()
	parser.add_argument("--years", dest="years", nargs=2, type=int)
	parser.add_argument("--out_dir", dest="out_dir", nargs=1, type=str)
	
	inps = parser.parse_args()

	
	species = ["Atlantic Cod", "Haddock", "Yellowtail Flounder", "Atlantic Mackerel", "American Butterfish"]
	year_range = range(inps.years[0], inps.years[1]+1)
	month_range = range(1, 13)

	depths = {
				"Atlantic Cod": 90,
				"Haddock": 130,
				"Yellowtail Flounder": 90,
				"Atlantic Mackerel": 70,
				"American Butterfish": 110
			}

	spawning_bounds = {
		"Atlantic Cod": (0, 151),
		"Haddock": (60, 151),
		"Yellowtail Flounder": (60, 180),
		"Atlantic Mackerel": (121, 212),
		"American Butterfish": (121, 243)
	}

	output_dir = "../data/initial_positions"
	
	fish_data = pd.read_csv("../auxdata/spawning-predictions-std-warm.csv")
	for s in species:

		sp = s.lower().replace(" ", "-")
		species_dir = "{}/{}".format(inps.out_dir[0], sp)
		os.makedirs(os.path.dirname(species_dir), exist_ok=True)

		init_dir = "{}/inits".format(species_dir)
		print(init_dir)
		print(os.path.exists(init_dir))
		os.makedirs(init_dir, exist_ok=True)

		bounds = spawning_bounds[s]
		depth = depths[s]
		for y in year_range:

			year_dir = "{}/{}".format(species_dir, str(y))
			os.makedirs(year_dir, exist_ok=True)

			data = fish_data[(fish_data.Species == s) & (fish_data.year == y)]
			particles, dates, months = init.initialize_particles(data, 1000000, y, bounds[0], bounds[1])
			
			min_month = (datetime(1984, 1, 1) + timedelta(bounds[0]+1)).month
			max_month = (datetime(1984, 1, 1) + timedelta(bounds[1]+1)).month
			
			for m in range(min_month, max_month+1):

				padded_month = str(m).zfill(2)
				month_dir = "{}/{}".format(year_dir, padded_month)
				os.makedirs(month_dir, exist_ok=True)

				print(y, m)
				try:
					mi, ma = np.min(dates[np.where(months == m)]), np.max(dates[np.where(months == m)])
					mask = np.logical_and(particles[:, -1] > mi-1, particles[:, -1] < ma+1)

					monthly_particles = particles[mask, :]
					nums = np.arange(1, len(monthly_particles)+1)
					monthly_particles = np.hstack((nums.reshape(-1, 1), 
										monthly_particles[:, 0].reshape(-1, 1), 
										monthly_particles[:, 1].reshape(-1, 1),
										monthly_particles[:, 2].reshape(-1, 1),
										(np.abs(monthly_particles[:, 3])*24).reshape(-1, 1)
                                                               ))

					fname = init.save_particles_to_file(monthly_particles, s, y, m, output_dir)
				
				except Exception as e:
					print(e)
					continue

				filename = "particle_init_{}{}.txt".format(y, padded_month)
					
				shutil.copy(fname, "{}/{}".format(init_dir, filename))
				shutil.copy(fname, "{}/{}".format(month_dir, filename))
				shutil.copy("../bin/job_submit.sh", month_dir)
				shutil.copy("../bin/sbatch_gom3.sh", month_dir)
				shutil.copy("../bin/preps/{}-prep.m".format(sp), "{}/prep.m".format(month_dir))
