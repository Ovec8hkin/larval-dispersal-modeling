import netCDF4 as ncdf
import scipy.io as sio
import numpy as np
import matplotlib.pyplot as plt
import alphashape as ashp
import shapely
import glob

def read_data(gom3_filename, sediments_filename, coast_filename):
	#gom3_filename = "/Volumes/jilab/gom3_hourly/gom3_201601.nc" 
	gom3_data = ncdf.Dataset(gom3_filename)
	sediments_data = ncdf.Dataset(sediments_filename)
	coast_file = sio.loadmat(coast_filename)
	
	lac = gom3_data.variables['latc'][:].data			# Latitudes at triangle centers
	loc = gom3_data.variables['lonc'][:].data			# Longitude at triangle center
	h  = gom3_data.variables['h'][:].data				# Bathymetry at triangle vertices
	t  = gom3_data.variables['temp'][0, 0, :].data 	# Temperature ar triangle vertices (at surface)
	nv = gom3_data['nv'][:].data						# Vertices indices surrounding triangles
		
	substrate = sediments_data['substrate'][:].data		# Sediment types at triangle center
	substrate = substrate.astype(np.float32)
	
	coast = coast_file['GOM3_coast']					# Coastline polygon
	
	return lac, loc, h, t, nv, substrate, coast
	
def interpolate_ht(h_vert, t_vert, nv):
	h = np.empty(shape=(90415))
	t = np.empty(shape=(90415))
	for i in range(90415):
		nodes = nv[:, i]-1
		h_vals = h_vert[nodes]
		t_vals = t_vert[nodes]
		h_avg = np.mean(h_vals)
		t_avg = np.mean(t_vals)
		h[i] = h_avg
		t[i] = t_avg
		
	return h, t
	
def create_data_mask(lons, lats, h, t, s, h_range, t_range, s_good):
	
	# Make copies of all of the inputs to preserve initial data
	t_restrict 		= t.copy()
	h_restrict 		= h.copy()
	s_restrict 		= s.copy()
	loc_restrict 	= lons.copy()
	lac_restrict 	= lats.copy()

	tmin, tmax = t_range
	hmin, hmax = h_range

	t_mask = (t < tmin) | (t > tmax)	# find indices where t is in range t_range
	h_mask = (h < hmin) | (h > hmax)	# find indices where h is in range h_range
	s_mask = np.isin(s, s_good)			# find indices where s is s_good

	# set inidices outside of mask to NAN
	t_restrict[t_mask] = np.nan			
	h_restrict[h_mask] = np.nan
	s_restrict[~s_mask] = np.nan

	# Combines H/T/S masks
	ths_mask = ~np.isnan(t_restrict) & ~np.isnan(h_restrict) & ~np.isnan(s_restrict)

	# Find valid coordinates that match all three mask parameters
	lac_restrict[~ths_mask] = np.nan
	loc_restrict[~ths_mask] = np.nan
	
	return loc_restrict, lac_restrict, h_restrict, t_restrict, s_restrict
	
def plot_all_data(loc, lac, locr, lacr, t, h, s, coast):
	fig, (ax1, ax2, ax3, ax4) = plt.subplots(1, 4, figsize=(18, 4))

	ax1.plot(coast[:, 0], coast[:, 1], 'k-')
	ax2.plot(coast[:, 0], coast[:, 1], 'k-')
	ax3.plot(coast[:, 0], coast[:, 1], 'k-')
	ax4.plot(coast[:, 0], coast[:, 1], 'k-')

	ax1.scatter(loc,lac,c=t,s=0.1, alpha=0.8)
	ax2.scatter(loc,lac,c=h,s=0.1, alpha=0.8)
	ax3.scatter(loc,lac,c=s,s=0.1, alpha=0.8)
	ax4.scatter(locr,lacr,c='red',s=0.1, alpha=0.8)
	
	ax1.set_title("Temperature Mask")
	ax2.set_title("Depth Mask")
	ax3.set_title("Substrate Mask")
	ax4.set_title("Complete Mask")
	
	return ax1, ax2, ax3, ax4
	
def plot_complete_mask(loc, lac, coast):
	
	fig, ax = plt.subplots(1, 1, figsize=(15, 10))

	ax.plot(coast[:, 0], coast[:, 1], 'k-')
	ax.scatter(loc,lac, c='red',s=0.1, alpha=0.8)

	xticks = np.arange(-77, -55, 1)
	yticks = np.arange(36, 48, 1)

	ax.set_xticks(xticks)
	ax.set_yticks(yticks)

	ax.grid(True)
	
	return ax
	
def compute_alpha_shape(lon, lat, bounds, a_value=10):
	
	lo_hull = lon.copy()[~np.isnan(lon)]
	la_hull = lat.copy()[~np.isnan(lat)]

	lo_min, lo_max = bounds[:2]
	la_min, la_max = bounds[2:]

	lo_mask = (lo_hull < lo_min) | (lo_hull > lo_max)
	la_mask = (la_hull < la_min) | (la_hull > la_max)

	lo_hull[lo_mask] = np.nan
	la_hull[la_mask] = np.nan

	lalo_mask = ~np.isnan(lo_hull) & ~np.isnan(la_hull)

	lo_hull = lo_hull[lalo_mask]
	la_hull = la_hull[lalo_mask]
	
	points = list(map(list, zip(lo_hull, la_hull)))
	points = np.array(points)
	
	alpha_shape = ashp.alphashape(points, a_value)
	
	return alpha_shape
	
def get_all_coords(alpha_shape):
	all_coords = []
	num_polygons = len(alpha_shape.__geo_interface__['coordinates'])
	print(num_polygons)
	for i in range(num_polygons):
		if num_polygons <= 1:
			cs = alpha_shape.__geo_interface__['coordinates'][i]
		else:
			cs = alpha_shape.__geo_interface__['coordinates'][i][0]
		coords = np.array([list(c) for c in cs])
		all_coords.append(coords)
	all_coords = np.array(all_coords)
	return all_coords

def save_release_zone_files(filename_base, coords, good_polygons):
	for i, poly in enumerate(coords):
		if i not in good_polygons:
			continue
		filename = "{}_{}.txt".format(filename_base, i)
		f = save_coords_to_file(filename, poly)
	
def save_coords_to_file(filename, coords):
	np.savetxt(filename, coords, delimiter="\t")
	return filename
	
def load_coords_from_file(filename):
	polygon_coords = np.loadtxt(filename)
	return polygon_coords
	
def plot_region(coords, coast):
	fig = plt.figure()
	ax = plt.axes()
	ax.plot(coast[:, 0], coast[:, 1], 'k-')
	ax.scatter(coords[:, 0], coords[:, 1], c='r', s=0.5)
	return ax
	#plt.show()
	
def plot_all_regions(locr, lacr, lon, lat, h, coast, title, bounds, save=False):
	files = glob.glob("release*.txt")

	fig, ax = plt.subplots(1, 1, figsize=(15, 7))

	ax.plot(coast[:, 0], coast[:, 1], 'k-', alpha=0.15)
	ax.scatter(locr,lacr, c='red',s=1, alpha=1.0, label="Temp, Depth, Substrate Mask")
	depth = ax.scatter(lon,lat,c=h,s=0.1, alpha=0.15, cmap='jet')

	xticks = np.arange(-77, -55, 1)
	yticks = np.arange(36, 48, 1)

	ax.set_xticks(xticks)
	ax.set_yticks(yticks)

	ax.grid(True)

	for f in files:
		coords = load_coords_from_file(f)
		ax.plot(coords[:, 0], coords[:, 1], 'b-', label="Release Zone")

	ax.set_xlim(bounds[0], bounds[1])
	ax.set_ylim(bounds[2], bounds[3])
	ax.set_title(title)
	plt.legend(loc="lower right")
	fig.colorbar(depth)

	if save:
		plt.savefig("herring_baseline_release.png", dpi=300)
		
	return ax