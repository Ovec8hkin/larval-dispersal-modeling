from . import data

import numpy as np
import shapely as shp
import scipy.stats as stats

def compute_connectivity_matrix(start, end, strata_filename, num=None, save=False, outfile="."):
	
	polygons, strata = data.get_strata(strata_filename)
	polygons = polygons.sample(frac=1)
	
	if num is None or num > len(start):
		num = len(start)

	particles = np.random.randint(0, len(start), num)

	init_lons, init_lats = start[particles, 0], start[particles, 1]
	final_lons, final_lats = end[particles, 0], end[particles, 1]

	first_polygons = np.zeros(shape=(num, 1))
	last_polygons = np.zeros(shape=(num, 1))

	for i in range(num):
		flo, fla = init_lons[i], init_lats[i]
		fpt = shp.geometry.Point(flo, fla)

		llo, lla = final_lons[i], final_lats[i]
		lpt = shp.geometry.Point(llo, lla)

		fpoly_found = False
		lpoly_found = False
		for j, poly in enumerate(polygons):
			if fpt.within(poly):
				poly_id = strata.iloc[j]['STRATA_NUM']
				first_polygons[i] = poly_id
				fpoly_found = True

			if lpt.within(poly):
				poly_id = strata.iloc[j]['STRATA_NUM']
				last_polygons[i] = poly_id
				lpoly_found = True

			if fpoly_found and lpoly_found:
				break
	
	first_polygons = first_polygons[:].flatten()
	last_polygons = last_polygons[:].flatten()
	
	fpolys, lpolys = first_polygons[:], last_polygons[:]
	
	conn_matrix = np.zeros(shape=(47, 47))
	for i in range(num):
		init_node  = fpolys[i]
		final_node = lpolys[i]
		conn_matrix[int(final_node)][int(init_node)] += 1
		
	if save:
		conn_matrix_file = "{}/conn_matrix_{}.txt".format(outfile, num)
		np.savetxt(conn_matrix_file, conn_matrix)
	
	return conn_matrix

def compute_grouped_connectivity_matrix(group_ranges, conn_matrix):
	num_groups = len(group_ranges)
	grouped_conn_matrix = np.zeros(shape=(num_groups, num_groups))
	for i, r1 in enumerate(group_ranges):
		for j, r2 in enumerate(group_ranges):
			g = conn_matrix[r1[0]:r1[1], r2[0]:r2[1]]
			s = g.sum()
			grouped_conn_matrix[i, j] = s
			
	return grouped_conn_matrix
	
def compute_annual_cm_stats(conn_mats):
	sd = conn_mats.std(axis=0)
	mu = conn_mats.mean(axis=0)
	cv = mu/sd
	
	return mu, sd, cv
	
def compute_connectivity_significance(baseline, warm, equal_var=False):
	tval, pval = stats.ttest_ind(baseline, warm, axis=0, equal_var=True)
	return pval
	
def compute_sink_sums(conn_matrix):
	return np.sum(conn_matrix, axis=1)
	
	
def log_transform_matrix(m):
	
	def compute_diff(a):
		if a > 0:
			return np.log10(a)
		else:
			return -np.log10(np.abs(a))
		
	dfunc = np.vectorize(compute_diff)
	log_matrix = dfunc(m)
	log_matrix[log_matrix == np.inf] = 0
	
	return log_matrix
	
	
def compute_larvae_density(x, y, nbins, save=False, outfile="."):
	h, xe, ye = np.histogram2d(x, y, bins=nbins)
	
	if save:
		h_file  = "{}/density.txt".format(outfile)
		xe_file = "{}/density_xe.txt".format(outfile)
		ye_file = "{}/density_ye.txt".format(outfile)
		
		np.savetxt(h_file, h)
		np.savetxt(xe_file, xe)
		np.savetxt(ye_file, ye)
	
	return h, xe, ye
	
	
def compute_dispersal_distances(inits, finals):
	init_lons, init_lats = inits[:, 0], inits[:, 1]
	final_lons, final_lats = finals[:, 0], finals[:, 1]
	
	if inits[0][0] > 1000:
		init_lons, init_lats = data.project(inits[:, 0], inits[:, 1], to_lola=True)
		final_lons, final_lats = data.project(finals[:, 0], finals[:, 1], to_lola=True)
	
	dlon = np.abs(final_lons - init_lons)
	dlat = np.abs(final_lats - init_lats)
	dis = np.sqrt(np.square(dlon)+np.square(dlat))
	
	return dis

	
def compute_dispersal_kernel(inits, finals, nbins=200, save=False, outfile="."):
	
	dis = compute_dispersal_distances(inits, finals)
	
	h, bins = np.histogram(dis, bins=nbins)
	
	if save:
		h_file  = "{}/kernel.txt".format(outfile)
		bins_file = "{}/kernel_bins.txt".format(outfile)
		
		np.savetxt(h_file, h)
		np.savetxt(bins_file, bins)
		
	return h, bins
	
	
def compute_region_area(r):
	region_shape = data.get_release_region_polygon(r)
	region_coords = region_shape.boundary.coords.xy
	lons, lats = region_coords[0], region_coords[1]

	xs, ys = data.project(lons, lats)

	pos = np.hstack((np.array([xs]).transpose(), np.array([ys]).transpose()))
	area = shp.geometry.Polygon(pos).area/(1000**2)
	
	return area
	
	