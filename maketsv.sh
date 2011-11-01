sqlite3 data/ufo.db <<EOF
.mode tabs
.output data/sighting_types.tsv
select * from sighting_types;
.output data/states.tsv
select * from states;
.output data/cities.tsv
select cities.*, count(*) as sighting_count , cities.name||', '||states.name_abbreviation as city_name from cities join sightings on sightings.city_id = cities.id join states on cities.state_id = states.id group by cities.id;
.output data/airports.tsv
select * from airports;
.output data/military_bases.tsv
select * from military_bases;
.output data/weather_stations.tsv
select * from weather_stations;
.output data/city_dist.tsv
select cities.id, city_airport_dist.distance as airportDist, city_military_base_dist.distance as militaryDist, city_weather_station_dist.distance as weatherDist from cities left outer join city_airport_dist on cities.id = city_airport_dist.city_id left outer join city_military_base_dist on cities.id = city_military_base_dist.city_id left outer join city_weather_station_dist on cities.id = city_weather_station_dist.city_id;
.exit
EOF

