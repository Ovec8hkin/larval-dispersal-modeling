from . import data
import descartes as dsc
import matplotlib.pyplot as plt
import matplotlib as mpl
import numpy as np

def plot_coastline(coastline_file, ax=None, color='grey', size=0.001, z=1, **kwargs):
	
	if not ax:
		fig, ax = plt.subplots(1, 1, figsize=(18,8))
	
	coast = data.get_coastline(coastline_file)

	ax.scatter(coast[:, 0], coast[:, 1], c=color, s=size, zorder=z, **kwargs)
	
	ax.set_xlabel("Longitude")
	ax.set_ylabel("Latitude")
	
	return ax
	
def plot_release_region(release_region_file, ax=None, color='k-', size=0.1, z=1, **kwargs):
	
	if not ax:
		fig, ax = plt.subplots(1, 1, figsize=(18,8))
	
	release_region = data.get_release_region(release_region_file)
	ax.plot(release_region[:, 0], release_region[:, 1], color, markersize=size, zorder=z, **kwargs)
	
	ax.set_xlabel("Longitude")
	ax.set_ylabel("Latitude")
	
	return ax

def plot_all_release_regions(files, ax=None, color='k-', size=0.001, z=1, **kwargs):
	
	if not ax:
		fig, ax = plt.subplots(1, 1, figsize=(18,8))
	
	for f in files:
		ax = plot_release_region(f, ax, color=color, size=size, z=z, **kwargs)
		
	ax.set_xlabel("Longitude")
	ax.set_ylabel("Latitude")
		
	return ax

def plot_particle_positions(lon, lat, ax=None, color='grey', size=0.001, z=1, **kwargs):
	
	if not ax:
		fig, ax = plt.subplots(1, 1, figsize=(18,8))
	
	scatter = ax.scatter(lon, lat, c=color, s=size, zorder=z, **kwargs)
	
	ax.set_xlabel("Longitude")
	ax.set_ylabel("Latitude")
	
	return ax, scatter
	
def plot_density(h, xe, ye, ax=None, **kwargs):
	
	if not ax:
		fig, ax = plt.subplots(1, 1, figsize=(18,8))
	
	im = ax.imshow(h, interpolation='nearest', origin='low', extent=[xe[0], xe[-1], ye[0], ye[-1]], **kwargs)
	
	ax.set_xlabel("Longitude")
	ax.set_ylabel("Latitude")
	
	return ax, im
	
def plot_dispersal_kernel(h, bins, ax=None, **kwargs):
	
	if not ax:
		fig, ax = plt.subplots(1, 1, figsize=(18, 8))
	
	width = (bins[1] - bins[0])
	center = (bins[:-1] + bins[1:]) / 2
	
	bars = ax.bar(center, h, align='center', width=width, **kwargs)
	
	return ax, bars
	
def plot_connectivity_matrix(conn_matrix, ax=None, **kwargs):
	
	if not ax:
		fig, ax = plt.subplots(1, 1, figsize=(18,8))
	
	im = ax.imshow(conn_matrix, **kwargs)
	
	ax.set_aspect('equal')

	ax.set_xlabel("Source Ploygon")
	ax.set_ylabel("Sink Polygon")
	ax.set_xticks(range(0, 47, 2))
	ax.set_yticks(range(0, 47, 2))

	mab_rect = mpl.patches.Rectangle((1, 1), 13, 13, linewidth=1,edgecolor='k',facecolor='none')
	sne_rect = mpl.patches.Rectangle((14, 14), 11, 11, linewidth=1,edgecolor='b',facecolor='none') 
	gb_rect = mpl.patches.Rectangle((25, 25),6,6,linewidth=1,edgecolor='r',facecolor='none')
	gom_rect = mpl.patches.Rectangle((31, 31), 15, 15, linewidth=1,edgecolor='g',facecolor='none')

	ax.add_patch(mab_rect)
	ax.add_patch(sne_rect)
	ax.add_patch(gb_rect)
	ax.add_patch(gom_rect)
	
	return ax, im
	
def plot_strata(strata, ax, face='w', edge='k', z=1, cmap="jet", **kwargs):
	
	if not ax:
		fig, ax = plt.subplots(1, 1, figsize=(18, 8))

	polygons = []
	colors = []
	
	for i in range(0, len(strata)):
		poly = strata.loc[strata['STRATA_NUM'] == i+1]
		geo = poly['geometry']
			
		if type(face) is np.ndarray:
			c = face[i]
			colors.append(c)
			
		polygons.append(dsc.PolygonPatch(geo.all(), fc='w', ec=edge, zorder=z))
	
	patches = mpl.collections.PatchCollection(polygons, match_original=True, cmap=mpl.cm.get_cmap(cmap), zorder=z, **kwargs)
	
	if type(face) is np.ndarray:
		patches.set_array(np.array(colors))
		
	ax.add_collection(patches)
	
	ax.set_xlabel("Longitude")
	ax.set_ylabel("Latitude")
	
	return ax, patches, polygons
	
	
class MidpointNormalize(mpl.colors.Normalize):
	"""
	Normalise the colorbar so that diverging bars work there way either side from a prescribed midpoint value)

	e.g. im=ax1.imshow(array, norm=MidpointNormalize(midpoint=0.,vmin=-100, vmax=100))
	"""
	def __init__(self, vmin=None, vmax=None, midpoint=None, clip=False):
		self.midpoint = midpoint
		mpl.colors.Normalize.__init__(self, vmin, vmax, clip)

	def __call__(self, value, clip=None):
		# I'm ignoring masked values and all kinds of edge cases to make a
		# simple example...
		x, y = [self.vmin, self.midpoint, self.vmax], [0, 0.5, 1]
		return np.ma.masked_array(np.interp(value, x, y), np.isnan(value))