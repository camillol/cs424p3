import sqlite3
from math import *

def haversin(x):
	return sin(x/2)**2

def geo_dist(lon1, lat1, lon2, lat2):
    """
    in: coordinates in degrees
    out: great circle distance in km
    
    http://en.wikipedia.org/wiki/Haversine_formula
    """
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
    h = haversin(lat2 - lat1) + cos(lat1) * cos(lat2) * haversin(lon2 - lon1)
    R = 6371.	# mean earth radius in km
    return R * 2 * asin(sqrt(h))

conn = sqlite3.connect('data/ufo.db')
c = conn.cursor()
c2 = conn.cursor()

def make_table(placetype):
	c.execute('CREATE TABLE city_%s_dist (city_id INTEGER, %s_id INTEGER, distance NUMERAL)' % (placetype,placetype))
	c.execute('CREATE INDEX city_%s_dist_index_city_id on city_%s_dist(city_id)' % (placetype,placetype))

def load_distances(placetype):
	places = []
	
	c.execute('select id, lat, lon from ' + placetype + 's')
	for id, lat, lon in c:
		places.append((id,lat,lon))
	
	c.execute('select id, lat, lon from cities')
	for id, lat, lon in c:
		if lat == None or lon == None: continue
		min_d = 10000000
		min_aid = None
		for aid, alat, alon in places:
			d = geo_dist(lon, lat, alon, alat)
			if d < min_d:
				min_d = d
				min_aid = aid
		c2.execute('insert into city_%s_dist (city_id, %s_id, distance) values (?, ?,?)'
			% (placetype,placetype), (id, min_aid, min_d))
