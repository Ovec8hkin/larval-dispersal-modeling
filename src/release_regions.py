import numpy as np
import alphashape as ashp

def mask_temperature(temp, tmin, tmax):
	t = temp.copy()
	t_mask = (t < tmin) | (t > tmax)
	
	t[t_mask] = np.nan
	return t

def mask_depth(depth, hmin, hmax):
	h = depth.copy()
	h_mask = (h < hmin) | (h > hmax)
	
	h[h_mask] = np.nan
	return h

def mask_substrate(substrate, sgood):
	s = substrate.copy()
	s_mask = np.isin(s, sgood)
	
	s[~s_mask] = np.nan
	return s
	
def mask_latlon(lat, lon, tmask, hmask, smask):
	la, lo = lat.copy(), lon.copy()
	
	ths_mask = ~np.isnan(tmask) & ~np.isnan(hmask) & ~np.isnan(smask)
	
	la[~ths_mask] = np.nan
	lo[~ths_mask] = np.nan
	
	return la, lo

def compute_alpha_shapes(lon, lat, bounds, a_value=25):
	ashapes = []
	for b in bounds:
		alpha_shape = compute_alpha_shape(lon, lat, b, a_value)
		ashapes.append(alpha_shape)
	return ashapes
	
def get_all_coords(ashapes):
	all_coords = np.array([])
	for alpha_shape in ashapes:
		coords = get_coords_for_shape(alpha_shape)[1:]
		all_coords = np.concatenate([all_coords, coords])
	return all_coords
	
def save_release_zone_files(filename_base, coords):
	filenames = []
	for i, poly in enumerate(coords):
		filename = "{}_{}.txt".format(filename_base, i)
		poly = poly[0] if poly.ndim > 2 else poly
		f = save_coords_to_file(filename, poly)
		filenames.append(filename)
	return filenames

	
	
def compute_alpha_shape(lons, lats, bounds, a_value=25):

	lo_hull = lons.copy()[~np.isnan(lons)]
	la_hull = lats.copy()[~np.isnan(lats)]

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
	
def get_coords_for_shape(alpha_shape):
	all_coords = [[]]
	num_polygons = len(alpha_shape.__geo_interface__['coordinates'])
	for i in range(num_polygons):
		cs = alpha_shape.__geo_interface__['coordinates'][i]
		coords = np.array([list(c) for c in cs])
		#print(coords)
		all_coords.append(coords)
	#print(all_coords)
	all_coords = np.array(all_coords)
	return all_coords
	
def save_coords_to_file(filename, coords):
	np.savetxt(filename, coords, delimiter="\t")
	return filename