import numpy as np
from shapely import geometry as sgeo
import glob
from datetime import date

def compute_bounding_envelope(polygon):
	env = polygon.envelope
	boundary_coords = env.exterior.coords.xy
	lons = np.array(boundary_coords[0])
	lats = np.array(boundary_coords[1])

	lons.sort()
	lats.sort()

	lon_min, lon_max = lons[0], lons[-1]
	lat_min, lat_max = lats[0], lats[-1]

	return lon_min, lon_max, lat_min, lat_max
	
def generate_random_points(bounds, num):
	lon_min, lon_max, lat_min, lat_max = bounds

	xs = np.random.uniform(lon_min, lon_max, num)
	ys = np.random.uniform(lat_min, lat_max, num)
	
	return xs, ys
	
def generate_depths(bounds, num):
	depth_min, depth_max = bounds
	
	depths = np.random.uniform(depth_min, depth_max, num)
	return depths
	
def generate_times(bounds, month, num):
	beg_date, end_date = bounds
	
	ts = np.random.randint(beg_date, end_date, num)*24 # put into hours rather than days 
	return ts

def mask_points(xs, ys, polygon):
	x_flat = xs.flatten()
	y_flat = ys.flatten()
	
	all_coords = np.array(list(map(list, zip(x_flat, y_flat))))
	
	points = []
	for c in all_coords:
		x, y = c[0], c[1]
		p = sgeo.Point(x, y)
		points.append(p.within(polygon))
		
	good_coords = all_coords[np.array(points)]
	
	xs, ys = good_coords[:, 0], good_coords[:, 1]
	n = len(xs)
	
	return xs, ys, n

def save_to_file(filename, xs, ys, depths, times):
	
	if len(xs.shape) > 1:
		xs = xs.flatten()
		ys = ys.flatten()
	
	nparticles = len(xs)
	
	nums = np.linspace(1, nparticles, nparticles)
	data = np.column_stack((nums, xs, ys, depths, times))
	
	np.savetxt(filename, data, fmt=["%.0f","%.4f","%.4f","%.2f","%.2f"], delimiter="\t")
	
	with open(filename, 'r+') as f:
		content = f.read()
		f.seek(0, 0)
		f.write(str(nparticles-1)+"\n")
		f.write(content)
		
	return filename		
		
def get_bounds_for_month(year, month):
	month_length = (date(year, month+1, 1) - date(year, month, 1)).days
	beg_date = (date(year, month, 1) - date(year, 1, 1)).days + 1
	end_date = beg_date+month_length
	
	return beg_date, end_date
