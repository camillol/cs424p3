CREATE INDEX states_index_id ON states(id);
CREATE INDEX states_index_name_abbreviation ON states(name_abbreviation);

CREATE INDEX counties_index_id ON counties(id);
CREATE INDEX counties_index_state_id ON counties(state_id);

CREATE INDEX cities_index_id ON cities(id);
CREATE INDEX cities_index_state_id ON cities(state_id);
CREATE INDEX cities_index_county_id ON cities(county_id);
CREATE INDEX cities_index_lat_lon ON cities(lat, lon);
CREATE INDEX cities_index_name ON cities(name);

CREATE INDEX shapes_index_id ON shapes(id);

CREATE INDEX sightings_index_id ON sightings(id);
CREATE INDEX sightings_index_shape_id ON sightings(shape_id);
CREATE INDEX sightings_index_city_id ON sightings(city_id);
CREATE INDEX sightings_index_occurred_at ON sightings(occurred_at);

