import os
import netCDF4 as nc
import numpy as np
import scipy.io as sio
import geopandas as gpd
import pyproj as proj
from shapely import geometry as sgeo

def get_latlon(filename):
	gom3_data = nc.Dataset(filename)
	
	lac = gom3_data.variables['latc'][:].data # Latitudes at triangle centers
	loc = gom3_data.variables['lonc'][:].data # Longitude at triangle center
	nv = gom3_data['nv'][:].data
	
	gom3_data.close()
	
	return loc, lac, nv
	
def get_xy(filename):
	gom3_data = nc.Dataset(filename)
	
	xc = gom3_data.variables['xc'][:].data # Latitudes at triangle centers
	yc = gom3_data.variables['yc'][:].data # Longitude at triangle center
	nv = gom3_data['nv'][:].data
	
	gom3_data.close()
	
	return xc, yc, nv
	
def get_substrate(filename):
	sediments_data = nc.Dataset(filename)
	substrate = sediments_data['substrate'][:].data # Sediment types at triangle center
	substrate = substrate.astype(np.float32)
	sediments_data.close()
	return substrate
	
def get_depth(filename, nodes):
	gom3_data = nc.Dataset(filename)
	depth  = gom3_data.variables['h'][:].data
	gom3_data.close()
	
	h = standardize_to_centers(depth, nodes)
	
	return h

def get_temperature(dir, years, month, nodes):
	
	temp = np.zeros(shape=(1, 48451))
	
	# Get temperature mean of for range of years 
	for y in years:
		m = str(month).zfill(2)
		filename = "{}/gom3_{}{}.nc".format(dir, y, m)
		
		temp_data = nc.Dataset(filename)
		t  = temp_data.variables['temp'][0, 0, :].data  # use surface temperature
		temp_data.close()
		
		temp += t
		
	temp /= len(years)
	temp = temp[0]
	
	t = standardize_to_centers(temp, nodes)
		
	return t	
	
def get_coastline(filename):
	coast_data = sio.loadmat(filename)
	coast = coast_data['GOM3_coast']
	return coast
	
def get_topography(filename):
	topo = nc.Dataset(filename)
	
	topo_lat = topo.variables['lat'][:].data
	topo_lon = topo.variables['lon'][:].data
	z 		 = topo.variables['Band1'][:, :].data
	
	lo, la = np.meshgrid(topo_lon, topo_lat)
	
	topo.close()
	
	return lo, la, z
	
def get_strata(filename):
	strata = gpd.read_file(filename)
	strata_polygons = strata['geometry'][:]
	
	return strata_polygons, strata	
	
def get_release_region(filename):
	polygon_coords = np.loadtxt(filename)
	return polygon_coords
	
def get_release_region_polygon(filename):
	coords = get_release_region(filename)
	poly = sgeo.Polygon(coords)
	return poly
	
def get_connectivty_matrix(filename):
	cm = np.loadtxt(filename)
	return cm
	


	
def get_data_files_for_year(basedir, year, fname):
	directory = "{}/Year{}".format(basedir, year)
	dirs = list(os.walk(directory))
	subdirs = dirs[1:]
	file_paths = []
	for i in range(len(subdirs)):
		filename = "{}/{}".format(subdirs[i][0], fname)
		if os.path.exists(filename):
			file_paths.append(filename)
	
	return file_paths	
	
def combine_data_for_year(basedir, year, fname):
	files = get_data_files_for_year(basedir, year, fname)
	
	all_lons_start = np.array([])
	all_lats_start = np.array([])
	all_depths_start = np.array([])
	all_times_start = np.array([])
	
	all_lons_last = np.array([])
	all_lats_last = np.array([])
	all_depths_last = np.array([])
	all_times_last = np.array([])
	all_temps_last = np.array([])
	all_bathy_last = np.array([])
	all_settled = np.array([])	
	for f in files:
		d = nc.Dataset(f)
		
		start_lons = d.variables['init_lons'][:].data
		start_lats = d.variables['init_lats'][:].data
		start_depths = d.variables['init_depths'][:].data
		start_times = d.variables['init_times'][:].data
		
		final_lons = d.variables['final_lons'][:].data
		final_lats = d.variables['final_lats'][:].data
		final_depths = d.variables['final_depths'][:].data
		final_temps = d.variables['final_temps'][:].data
		final_bathy = d.variables['final_bathy'][:].data
		final_times = d.variables['final_times'][:].data
		
		settled = d.variables['settled_particles'][:].data
		
		settled += len(all_lons_start)
		
		all_lons_start = np.concatenate((all_lons_start, start_lons))
		all_lats_start = np.concatenate((all_lats_start, start_lats))
		all_depths_start = np.concatenate((all_depths_start, start_depths))
		all_times_start = np.concatenate((all_times_start, start_times))
		
		all_lons_last = np.concatenate((all_lons_last, final_lons))
		all_lats_last = np.concatenate((all_lats_last, final_lats))
		all_depths_last = np.concatenate((all_depths_last, final_depths))
		all_times_last = np.concatenate((all_times_last, final_times))
		all_temps_last = np.concatenate((all_temps_last, final_temps))
		all_bathy_last = np.concatenate((all_bathy_last, final_bathy))
		
		
		all_settled = np.concatenate((all_settled, settled.astype(int)))
		
		d.close()
		
	start = np.hstack((
						np.array([all_lons_start]).transpose(), 
						np.array([all_lats_start]).transpose(),
						np.array([all_depths_start]).transpose(),
						np.array([all_times_start]).transpose()
					 ))
	end = np.hstack((
						np.array([all_lons_last]).transpose(), 
						np.array([all_lats_last]).transpose(),
						np.array([all_depths_last]).transpose(),
                		np.array([all_temps_last]).transpose(),
                		np.array([all_bathy_last]).transpose(),
						np.array([all_times_last]).transpose()
				   ))
	
	return start, end, all_settled
	
def get_data_for_years(basedir, years, fname):
	
	all_start = np.empty(shape=(1, 4))
	all_end = np.empty(shape=(1, 6))
	all_settled = np.empty(shape=(1,))
	
	for y in years:
		start, end, settled = combine_data_for_year(basedir, y, fname)
		
		settled += len(all_start)-1
		
		all_start = np.vstack((all_start, start))
		all_end = np.vstack((all_end, end))
		all_settled = np.append(all_settled, settled)
		
	return all_start[1:], all_end[1:], all_settled[1:].astype(int)	
	
def get_settled_particles(starts, end, settled):
	settled = settled.astype(int)
	return start[settled, :], end[settled, :]
	
	
	
def project(x, y, to_lola=False):
	proj_out = proj.Proj('esri:102284')
	
	xproj, yproj = proj_out(x, y, inverse=to_lola)
	
	return xproj, yproj	
	
	
	
def standardize_to_centers(data, nodes):
	
	x = np.empty(shape=(90415))
	for i in range(90415):
		n = nodes[:, i]-1
		x_vals = data[n]
		x_avg = np.mean(x_vals)
		x[i] = x_avg
	
	return x
