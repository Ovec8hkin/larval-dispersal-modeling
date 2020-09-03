import glob
import argparse
import numpy as np
import os
import shutil

import data as data
import initialize_larvae as init
	
if __name__ == "__main__":
	
	parser = argparse.ArgumentParser()
	parser.add_argument("--years",   dest="years",   nargs=2, type=int)
	parser.add_argument("--months",  dest="months",  nargs=2, type=int)
	parser.add_argument("--out_dir", dest="out_dir", nargs=1, type=str)
	parser.add_argument("--in_dir",  dest="in_dir",  nargs=1, type=str)
	
	inps = parser.parse_args()

	
	month_names = { "1": "jan",
					"2": "feb",
					"3": "mar",
					"4": "apr",
					"5": "may",
					"6": "jun",
					"7": "jul",
					"8": "aug",
					"9": "sep",
					"10": "oct",
					"11": "nov",
					"12": "dec"
	}
	
	for y in range(inps.years[0], inps.years[1]+1):
		for m in range(inps.months[0], inps.months[1]+1):
			files = glob.glob("{}/release_*{}*.txt".format(inps.in_dir[0], month_names[str(m)]))
			all_xs, all_ys, all_ds, all_ts = np.array([]), np.array([]), np.array([]), np.array([])

			for f in files:
				print(f)
				region = data.get_release_region_polygon(f)
				bounds = init.compute_bounding_envelope(region)

				npoints = int(1000000*region.area/2)

				xs, ys = init.generate_random_points(bounds, npoints)
				xs, ys, nparticles = init.mask_points(xs, ys, region)
				
				xs, ys = data.project(xs, ys)
				
				depths = init.generate_depths((0, 100), nparticles)
				
				beg_date, end_date = init.get_bounds_for_month(y, m)
				times = init.generate_times((beg_date, end_date), 0, nparticles)
				
				all_xs = np.append(all_xs, xs, axis=0)
				all_ys = np.append(all_ys, ys, axis=0)
				all_ds = np.append(all_ds, depths, axis=0)
				all_ts = np.append(all_ts, times, axis=0)
				
			padded_month = str(m).zfill(2)
				
			filename = "particle_init_{}{}.txt".format(y, padded_month)
			init.save_to_file(filename, all_xs, all_ys, all_ds, all_ts)

			model_dir = "../Year{}/{}-{}/".format(y, padded_month, month_names[str(m)])
			os.makedirs(os.path.dirname(model_dir), exist_ok=True)	
			
			shutil.copy(filename, model_dir)
			shutil.copy("/Volumes/jilab/zahner-ssf2020/model_runs/job_submit.sh", model_dir)
			shutil.copt("/Volumes/jilab/zahner-ssf2020/model_runs/sbatch_gom3.sh", model_dir)
			shutil.copy("../prep.m", model_dir)
				
	os.chdir('..')
	
			
	