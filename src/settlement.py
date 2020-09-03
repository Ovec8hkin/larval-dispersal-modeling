import aux_code.data as data

import os
import netCDF4 as nc
import numpy as np
from scipy.spatial import cKDTree

def settle(f, temp_range, depth_range, good_substrate, num=None):
	
	sediments_filename = "/vortexfs1/share/jilab/public/share/sediments.nc"
	gom3_filename = "/vortexfs1/share/jilab/gom3_hourly/gom3_201601.nc"
	
	particle_data = nc.Dataset(f)
	x = particle_data.variables['x'][:, :].data
	y = particle_data.variables['y'][:, :].data
	z = particle_data.variables['z'][:, :].data
	
	h = particle_data.variables['h'][:, :].data
	t = particle_data.variables['T'][:, :].data
	
	sed = data.get_substrate(sediments_filename)
	
	particle_lons, particle_lats = data.project(x, y, to_lola=True)
	
	yr = f.split("/")[1][4:]
	mn = f.split("/")[2][:2]
	
	e Yearinits = np.loadtxt("/".join(f.split("/")[:-1])+"/particle_init_{}{}.txt".format(yr, mn), skiprows=1)#[:, -1]/24 - 1
	init_lons, init_lats = data.project(inits[:, 1], inits[:, 2], to_lola=True)
	init_depths = inits[:, 3]
	init_times = (inits[:, 4]/24 - 1).astype(int)
	
	if not num or num > x.shape[1]:
		num = x.shape[1]
		
	rand_particles = np.random.randint(0, x.shape[1], num)
	
	pinit_lons, pinit_lats = init_lons[rand_particles], init_lats[rand_particles]
	pinit_depths, pinit_times = init_depths[rand_particles], init_times[rand_particles]
	
	plons, plats = particle_lons[:, rand_particles], particle_lats[:, rand_particles]
	pdepths, pbathy, ptemp = z[:, rand_particles], h[:, rand_particles], t[:, rand_particles]
	
	pld_mins, pld_maxs, pld_ranges = set_plds(pld_min=45, pld_max=60, num=num)
	
	print('plds computed')
	
	tree = build_tree(gom3_filename)
	
	final_lon = np.empty(shape=(num))
	final_lat = np.empty(shape=(num))
	final_depth = np.empty(shape=(num))
	final_time = np.empty(shape=(num))
	
	settled_particles = []
	unsettled_particles = []

	for i in range(num):
		particle_settled = False
		pld_min, pld_max = pld_ranges[i]
		release_day = pinit_times[i]
		for t in range(pld_min, pld_max+1):
			t_real = t+release_day-np.min(pinit_times) # needs to be adjusted so as to reflect the calendar day of PLD
			lon, lat, depth = plons[t_real, i], plats[t_real, i], pdepths[t_real, i]
			h, t = pbathy[t_real, i], ptemp[t_real, i]

			dist, idx = tree.query([lon, lat])
			s = sed[idx]
			
			final_lon[i] = lon
			final_lat[i] = lat
			final_depth[i] = depth
			final_time[i] = t_real
			
			if habitat_is_suitable(t, h, s, temp_range, depth_range, good_substrate):
				settled_particles.append(i)
				particle_settled = True
				break;

		if not particle_settled:
			unsettled_particles.append(i)
				
		if i % 1000 == 0:
			print(i)
	 
	############ Write settlement data to NetCDF file for reuse ##############
	settlement_file = "/".join(f.split("/")[:-1])+"/settlement.nc"
	if os.path.exists(settlement_file):
		os.remove(settlement_file)
	  
	print(settlement_file)
	
	sett_f = nc.Dataset(settlement_file, 'w', format="NETCDF4")
	
	sett_f.createDimension('num_particles', num)
	sett_f.createDimension('settled', None)
	sett_f.createDimension('unsettled', None)

	init_lons_var    = sett_f.createVariable("init_lons",    "f8", ("num_particles",))
	init_lats_var    = sett_f.createVariable("init_lats",    "f8", ("num_particles",))
	init_depths_var  = sett_f.createVariable("init_depths",  "f8", ("num_particles",))
	init_times_var   = sett_f.createVariable("init_times",   "f8", ("num_particles",))
	
	final_lons_var   = sett_f.createVariable("final_lons",   "f8", ("num_particles",))
	final_lats_var   = sett_f.createVariable("final_lats",   "f8", ("num_particles",))
	final_depths_var = sett_f.createVariable("final_depths", "f8", ("num_particles",))
	final_times_var  = sett_f.createVariable("final_times",  "f8", ("num_particles",))

	settled_particles_var   = sett_f.createVariable("settled_particles",   "u8", ("settled",))
	unsettled_particles_var = sett_f.createVariable("unsettled_particles", "u8", ("unsettled",))
	
	init_lons_var[:] = pinit_lons
	init_lats_var[:] = pinit_lats
	init_depths_var[:] = pinit_depths
	init_times_var[:] = pinit_times
	
	final_lons_var[:] = final_lon
	final_lats_var[:] = final_lat
	final_depths_var[:] = final_depth
	final_times_var[:] = final_time
	
	settled_particles_var[:] = np.array(settled_particles)
	unsettled_particles_var[:] = np.array(unsettled_particles)
	
	sett_f.close()
	
	##########################################################################
		
	final_data = np.column_stack((final_lon, final_lat, final_depth, final_time))    
		
	return final_data, settled_particles, unsettled_particles

def set_plds(pld_min, pld_max, num):
	pld_mean = pld_min + (pld_max - pld_min)/2

	pld_mins = np.random.randint(pld_min, pld_mean, size=num).tolist()
	pld_maxs = np.random.randint(pld_mean, pld_max, size=num).tolist()
	pld_ranges = list(zip(pld_mins, pld_maxs))
	
	return pld_mins, pld_maxs, pld_ranges
	
def get_substrate(gom3_filename, sediments_filename):
	nbve = nc.Dataset(gom3_filename).variables['nbve'][:, :].data
	substrate = data.get_substrate(sediments_filename)
		
	return substrate

def subset_particles(lons, lats, times, num):
	n = np.random.randint(0, lons.shape[1], num)
	return lons[:, n], lats[:, n], times[n]

def build_tree(gom3_filename):
	lons, lats, nodes = data.get_latlon(gom3_filename)
	grid_points = np.dstack([lons.ravel(),lats.ravel()])[0]
	tree = cKDTree(grid_points)

def habitat_is_suitable(t, h, s, trange, hrange, srange):
	return  (s in srange) and (hrange[0] < h < hrange[1]) and (trange[0] < t < trange[1])