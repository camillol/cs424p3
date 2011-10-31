import sqlite3
import csv
import re
import codecs

conn = sqlite3.connect('data/ufo.db')
c = conn.cursor()

with codecs.open("data/Gaz_counties_national.csv","r","latin-1") as f:
	for idx, line in enumerate(f):
		if idx == 0: continue
		row = line.split('\t')
		lat = float(row[8])
		lon = float(row[9])
		name = re.sub('\s+County','',row[3])
		c.execute('select id from counties where name like ?', (name,))
		id = c.fetchone()
		if id:
			c.execute('update counties set lat = ?, lon = ? where id = ?', (lat, lon, id[0]))
		else:
			print "not found:", name
conn.commit()