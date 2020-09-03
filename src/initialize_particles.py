import numpy as np
from shapely import geometry as sgeo
import descartes
import matplotlib.pyplot as plt
import pyproj as proj

def load_release_region_polygon(filename):
	coords = np.loadtxt(filename)
	poly = sgeo.Polygon(coords)
	return poly
	
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
	
def generate_point_grid(bounds, x_points, y_points):
	
	lon_min, lon_max, lat_min, lat_max = bounds
	
	xs = np.linspace(lon_min, lon_max, x_points)
	ys = np.linspace(lat_min, lat_max, y_points)
	
	XS, YS = np.meshgrid(xs, ys)
	
	return XS, YS
	
def generate_random_points(bounds, num):
	lon_min, lon_max, lat_min, lat_max = bounds

	xs = np.random.uniform(lon_min, lon_max, num)
	ys = np.random.uniform(lat_min, lat_max, num)
	
	return xs, ys
	
def generate_depths(bounds, num):
	depth_min, depth_max = bounds
	
	depths = xs = np.random.uniform(depth_min, depth_max, num)
	return depths
	
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
	
	return good_coords
	
def plot_points(coords, polygon, envelope):
	
	poly = descartes.PolygonPatch(polygon, fc='blue', ec='blue', alpha=0.25, zorder=2)
	env = descartes.PolygonPatch(envelope, fc='green', alpha=0.25)
	
	fig = plt.figure()
	ax = plt.axes()
	
	ax.add_patch(poly)
	ax.add_patch(env)
	ax.scatter(coords[:, 0], coords[:, 1], s=1)
	
	return ax
	
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