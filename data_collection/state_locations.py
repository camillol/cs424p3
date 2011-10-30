import sqlite3
from lxml import etree
import re

conn = sqlite3.connect('data/ufo.db')
c = conn.cursor()

parser = etree.HTMLParser()
tree = etree.parse('data/geographical_center_of_state.html', parser)

location_re = re.compile("""(\d+(?:\.\d+)?)'(\d+(?:\.\d+)?)'([WE])\s+(\d+(?:\.\d+)?)'(\d+(?:\.\d+)?)'?([NS])?""")

def degrees_to_decimal(d, m, s, dir):
	f = float(d) + float(m)/60. + float(s)/3600.
	if dir in ['S', 'W']: f = -f
	return f

trs = tree.xpath('//table/tbody/tr')
for tr in trs:
	state, location, _ = tr.xpath('.//text()')
	if state == 'State': continue
	m = location_re.match(location)
	lon = degrees_to_decimal(m.group(1), m.group(2), 0, m.group(3))
	lat = degrees_to_decimal(m.group(4), m.group(5), 0, m.group(6))
	print state, lon, lat
	
	c.execute('update states set lat = ?, lon = ? where name = ?', (lat, lon, state.upper()))
conn.commit()