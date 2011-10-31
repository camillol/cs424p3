#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'uri'
require 'net/http'
require 'chronic'
require "sqlite3"
require 'progressbar'
require 'fastercsv'
require 'date'


#TODO add method that will write the data into flat file OR database
module Scraper
  #Downloads data and parses it into three buckets seasons, episodes, and phrases
  DUMP_FILE_NAME = "scraped_rb_dump.bin".freeze
  SITE_DIRECTORY = "/webreports".freeze
  BANNED_LOCATIONS = ["UNSPECIFIED/INTERNATIONAL", "ALBERTA,CANADA", "BRITISH COLUMBIA,CAN", "MANITOBA,CANADA", "NEW BRUNSWICK,CAN",
                      "NEWFOUNDLAND,CAN", "NOVA SCOTIA,CAN", "ONTARIO,CAN", "PROV OF QUE,CAN", "SASKATCHEWAN,CAN"].freeze

  def self.dump_file_path
    File.join File.expand_path(File.dirname(__FILE__)), DUMP_FILE_NAME
  end

  def self.update_coordinates_counties_from_api
    db = SQLite3::Database.new("ufo.db") 
    find_county = lambda do |county_name|
      county_result = db.execute("SELECT id FROM counties WHERE name like ? ", county_name)
      unless county_result.empty?
        county_id = county_result.first.first
      else
        nil
      end
    end
    #http://dev.virtualearth.net/REST/v1/Locations/Skokie,IL?o=xml&key=AglK4wns9bo4A1oV_robGjdXYuKww4c7lM5b6fbgIh-WXJAurJpfJIlCJIbHmT7V
    #url = URI.encode("http://maps.googleapis.com/maps/api/geocode/xml?address=#{row[2].gsub(/(\(.*?\))/, '')}, #{row[1]}&sensor=false")
    db.execute("SELECT c.id, s.name_abbreviation, c.name, s.id FROM cities c JOIN states s ON c.state_id = s.id WHERE lat is null or lon is null or c.county_id is null").each do |row|
      url = URI.encode("http://maps.googleapis.com/maps/api/geocode/xml?address=#{row[2].gsub(/(\(.*?\))/, '')},#{row[1]}&sensor=false")
      #url = URI.encode("http://dev.virtualearth.net/REST/v1/Locations/#{row[2].gsub(/(\(.*?\))/, '')},#{row[1]}?o=xml&key=AglK4wns9bo4A1oV_robGjdXYuKww4c7lM5b6fbgIh-WXJAurJpfJIlCJIbHmT7V")
      html = Nokogiri.HTML(open(url))
      lat_doc, lon_doc, county_doc = nil, nil, nil
      if url.include? "google"
        lat_doc = html.xpath("//geometry/location/lat").first
        lon_doc = html.xpath("//geometry/location/lng").first
        county_doc = html.xpath("//address_component[type='administrative_area_level_2']/long_name").first
      else
        lat_doc = html.xpath("//location/point/latitude").first
        lon_doc = html.xpath("//location/point/longitude").first
        county_doc = html.xpath("//address_co/admindistrict2").first
      end
      if lat_doc and lon_doc
        lat = lat_doc.content
        lon = lon_doc.content
        county_id = nil
        if county_doc
          county = county_doc.content 
          county.gsub!("Co.", '')
          county.strip!
          county_id = find_county.call(county)
          unless county_id
            db.execute("INSERT INTO counties (name, state_id) VALUES ( ?, ? )", county, row[3])
            county_id = find_county.call(county)
          end
        end
        db.execute("UPDATE cities SET lat = ?, lon = ?, county_id = ? WHERE id = ? ", lat, lon, county_id, row[0])
      else
        puts html.content
      end
    end
  end

  def self.update_city_coordinates
    i = 0
    db = SQLite3::Database.new('ufo.db')
    FasterCSV.foreach(File.join(File.expand_path(File.dirname(__FILE__)), "../data", "Gaz_places_national.csv"), :col_sep => "\t") do |line|
      if i > 0
        rows = db.execute("SELECT c.id FROM cities c JOIN states s ON s.id = c.state_id WHERE c.name like ? AND s.name_abbreviation like ? ", 
                   "%#{line[3].gsub(/(CDP|city|town)/, '').strip}%", "%#{line[0]}%")
        if rows.one?
          db.execute("UPDATE cities SET lat = ?, lon = ? WHERE id = ?", line[8].to_f, line[9].to_f, rows.first.first)
        end
      end
      i+=1
    end
  end

  def self.open(url_string, j=0)
    url = URI.parse(url_string)
    #host_rel_path = "#{url.scheme}://#{url.host + SITE_DIRECTORY}"
    request = Net::HTTP.new(url.host, url.port)
    request.read_timeout = 60
    try = 0
    response = nil
    begin
      response = request.get(url.request_uri)
      loc = response['location']
      raise "Too many redirects" if j > 2

      if loc and url_string.include? "findweather/getForecast?"
        puts "ABOUT..."
        x = open("#{url.scheme}://" + url.host + loc + "&format=xml", j+=1)
        return x
      else
        response = response.body
      end
    rescue Exception => e
      try+=1
      if try < 10
        retry
      end
      puts "FAILED TO OPEN: " + url_string.to_s
      puts e
    end
    response
  end

  def self.scrape
    year_2000 = Time.mktime(2000)
    host_rel_path = "http://www.nuforc.org#{SITE_DIRECTORY}"

    #Represent tables
    states = []
    sightings = []
    rows = Nokogiri::HTML(open(host_rel_path + "/ndxloc.html")).xpath("//table/tbody/tr/td[1]//a")
    pbar = ProgressBar.new("Loading...", rows.length - BANNED_LOCATIONS.length)
    rows.each_with_index do |sighting_link_html, i|
      state = {}
      state[:sightings_url] = "#{host_rel_path}/#{sighting_link_html["href"]}"
      state[:name] = sighting_link_html.content
      next if BANNED_LOCATIONS.include? state[:name]
      pbar.inc
      states << state 
      html = open(state[:sightings_url])
      next unless html
      Nokogiri::HTML(html).xpath("//table/tbody/tr").each do |sighting_html|
        sighting = {}
        columns = sighting_html.xpath "td"
        #ONLY 2 rows out of the whole set have these problems, really broken HTML in summary, lets ignore these records
        if columns.length == 7 
          sighting[:occurred_at] = columns[0].content.strip_html.strip
          if sighting[:occurred_at] and !sighting[:occurred_at].empty? and sighting[:occurred_at].to_date < year_2000
            break 
          end
          sighting[:city] = columns[1].content.strip_html.strip.downcase.capitalize
          sighting[:state] = columns[2].content.strip_html.strip.upcase
          state[:name_abbreviation] ||= sighting[:state].strip.upcase
          sighting[:shape] = columns[3].content.strip_html.strip.downcase.capitalize
          sighting[:duration] = columns[4].content.strip_html.strip
          sighting[:summary_description] = columns[5].content.strip_html.strip
          sighting[:posted_at] = columns[6].content.strip_html.strip
          sighting[:sighting_detail_url] = "#{host_rel_path}/#{columns.first.xpath(".//a").first["href"]}"
        else
          sighting[:broken] = sighting_html.content.strip
        end
        sightings << sighting
        if sighting[:sighting_detail_url]
          html = open(sighting[:sighting_detail_url])
          next unless html
          details_html = Nokogiri::HTML(html).xpath "//table/tbody/tr/td"
          if details_html.length > 1
            reported_at = details_html.first.content.to_s.strip_html.scan /Reported:\s(.*?)\s.*[PAM]{2}\s(\d{1,2}:\d{1,2})/
            if reported_at.one?
              sighting[:reported_at] = reported_at.first.map(&:strip).join(" ").strip
            end
            full_description = details_html.last.content.strip_html.strip
            unless full_description.empty?
              sighting[:full_description] = full_description.strip
            end
          end
        end
      end
    end
    pbar.finish
    result = {:states => states, :sightings => sightings}
    cached_result = Marshal.dump result
    file_path = self.dump_file_path
    f = File.new file_path, "w" 
    f.write cached_result
    f.close
    result
  end

  def self.createdb
    raise "#{DUMP_FILE_NAME} not found" unless File.exists? self.dump_file_path
    result = Marshal.load IO.read(self.dump_file_path)

    result[:sightings].delete_if{|sighting| !sighting[:broken].nil? }

    db = SQLite3::Database.new('ufo.db')
    db.transaction do
      create_query  = %{
        
        DROP INDEX IF EXISTS states_index_id;
        DROP INDEX IF EXISTS states_index_name_abbreviation;
        DROP INDEX IF EXISTS states_index_lat_lon;

        DROP INDEX IF EXISTS counties_index_id;
        DROP INDEX IF EXISTS counties_index_state_id;
        DROP INDEX IF EXISTS counties_index_name_state_id;
        DROP INDEX IF EXISTS counties_index_lat_lon;

        DROP INDEX IF EXISTS cities_index_id;
        DROP INDEX IF EXISTS cities_index_state_id;
        DROP INDEX IF EXISTS cities_index_county_id;
        DROP INDEX IF EXISTS cities_index_lat_lon;
        DROP INDEX IF EXISTS cities_index_name_state_id;

        DROP INDEX IF EXISTS shapes_index_id;

        DROP INDEX IF EXISTS sightings_index_id;
        DROP INDEX IF EXISTS sightings_index_shape_id;
        DROP INDEX IF EXISTS sightings_index_city_id;
        DROP INDEX IF EXISTS sightings_index_occurred_at;
        
        DROP INDEX IF EXISTS airports_index_id;
        DROP INDEX IF EXISTS airports_index_lat_lon;

        DROP INDEX IF EXISTS military_bases_id;
        DROP INDEX IF EXISTS military_bases_lat_lon;

        DROP INDEX IF EXISTS city_proximities_city_id_relation_id_relation;
        DROP INDEX IF EXISTS city_proximities_distance;

        DROP INDEX IF EXISTS weather_stations_index_id;
        DROP INDEX IF EXISTS weather_stations_index_lat_lon;
        

        DROP TABLE IF EXISTS states;
        CREATE TABLE states (
          id INTEGER PRIMARY KEY, 
          name_abbreviation STRING, 
          name STRING,
          lat REAL,
          lon REAL
          );

        DROP TABLE IF EXISTS counties;
        CREATE TABLE counties (
          id INTEGER PRIMARY KEY,
          state_id INTEGER,
          name STRING,
          population_density INTEGER,
          lat REAL,
          lon REAL
        );

        DROP TABLE IF EXISTS city_proximities;
        CREATE TABLE city_proximities (
          city_id INTEGER,
          distance REAL,
          relation_id INTEGER,
          relation STRING
        );

        DROP TABLE IF EXISTS cities;
        CREATE TABLE cities (
          id INTEGER PRIMARY KEY,
          county_id integer,
          state_id integer,
          name STRING,
          lat REAL,
          lon REAL
        );

        DROP TABLE IF EXISTS sighting_types;
        CREATE TABLE sighting_types (
          id INTEGER PRIMARY KEY,
          name STRING,
          img_name STRING,
          color STRING
        );

        DROP TABLE IF EXISTS shapes;
        CREATE TABLE shapes (
          id INTEGER PRIMARY KEY,
          name STRING,
          sighting_type_id INTEGER
        );
        
        DROP TABLE IF EXISTS sightings;
        CREATE TABLE sightings (
          id INTEGER PRIMARY KEY,
          city_id INTEGER,
          shape_id INTEGER,
          summary_description STRING,
          full_description STRING, 
          occurred_at TIMESTAMP,
          reported_at TIMESTAMP,
          posted_at TIMESTAMP,
          temperature INTEGER,
          weather_conditions STRING
        );

        DROP TABLE IF EXISTS airports;
        CREATE TABLE airports(
          ID INTEGER PRIMARY KEY,
          name STRING,
          city STRING,
          lat REAL,
          lon REAL);
      
        DROP TABLE IF EXISTS military_bases;
        CREATE TABLE military_bases(
          ID INTEGER PRIMARY KEY,
          name STRING,
          lat REAL,
          lon REAL
        );

        DROP TABLE IF EXISTS weather_stations;
        CREATE TABLE weather_stations(
          id INTEGER PRIMARY KEY,
          name STRING,
          key STRING,
          state_id INTEGER,
          lat REAL,
          lon REAL
        );
      }

      db.execute_batch create_query
        
      # feeding data to database   
      puts "Inserting states"
      result[:states].each do |state|
        db.execute "INSERT INTO states (name, name_abbreviation) VALUES (?,?)", state[:name], state[:name_abbreviation]
      end
      #TODO find county for each city, insert conties into table, and map cities to counties
      puts "Inserting cities"
      result[:sightings].map{|sighting| [sighting[:city], sighting[:state]] }.uniq.each do |city_state|
        db.execute "INSERT INTO cities (name, state_id) VALUES (?, (SELECT id FROM states WHERE name_abbreviation LIKE ?))", city_state.first, city_state.last
      end

      puts "Inserting shapes"
      result[:sightings].map{|sighting| sighting[:shape] }.uniq.each do |shape|
        db.execute "INSERT INTO shapes (name) VALUES (?)", shape
      end

      puts "Inserting sightings"
      result[:sightings].each do |sighting|
        db.execute "INSERT INTO sightings (city_id, shape_id, summary_description, full_description, occurred_at, reported_at, posted_at)
                                  VALUES((SELECT id FROM cities WHERE name LIKE ?), (SELECT id FROM shapes WHERE name LIKE ?), ?, ?, ?, ?, ?)",
                                  sighting[:city], sighting[:shape], sighting[:summary_description], sighting[:full_description], 
                                  sighting[:occurred_at].to_date(:db),
                                  sighting[:reported_at] ? sighting[:reported_at].to_date(:db) : nil, 
                                  sighting[:posted_at].to_date(:db)
      end

      puts "Building indexes"
      db.execute "CREATE INDEX states_index_id ON states(id);"
      db.execute "CREATE UNIQUE INDEX states_index_name_abbreviation ON states(name_abbreviation);"
      db.execute "CREATE UNIQUE INDEX states_index_lat_lon ON states(lat,lon);"

      db.execute "CREATE INDEX counties_index_id ON counties(id);"
      db.execute "CREATE INDEX counties_index_state_id ON counties(state_id);"
      db.execute "CREATE UNIQUE INDEX counties_index_name_state_id ON counties(name, state_id);"
      db.execute "CREATE INDEX counties_index_lat_lon ON counties(lat, lon)"

      db.execute "CREATE INDEX cities_index_id ON cities(id);"
      db.execute "CREATE INDEX cities_index_state_id ON cities(state_id);"
      db.execute "CREATE INDEX cities_index_county_id ON cities(county_id);"
      db.execute "CREATE INDEX cities_index_lat_lon ON cities(lat, lon);"
      db.execute "CREATE UNIQUE INDEX cities_index_name_state_id ON cities(name, state_id);"

      db.execute "CREATE INDEX shapes_index_id ON shapes(id)"

      db.execute "CREATE INDEX sightings_index_id ON sightings(id)"
      db.execute "CREATE INDEX sightings_index_shape_id ON sightings(shape_id)"
      db.execute "CREATE INDEX sightings_index_city_id ON sightings(city_id)"
      db.execute "CREATE INDEX sightings_index_occurred_at ON sightings(occurred_at);"

      db.execute "CREATE INDEX airports_index_id ON airports(id)"
      db.execute "CREATE INDEX airports_index_lat_lon ON airports(lat, lon)"

      db.execute "CREATE INDEX military_bases_id ON military_bases(id)"
      db.execute "CREATE INDEX military_bases_lat_lon ON military_bases(lat, lon)"

      db.execute "CREATE INDEX city_proximities_city_id_relation_id_relation ON city_proximities(city_id, relation_id, relation)"
      db.execute "CREATE INDEX city_proximities_distance ON city_proximities(distance)"

      db.execute "CREATE INDEX weather_stations_index_id ON weather_stations(id)"
      db.execute "CREATE INDEX weather_stations_index_lat_lon ON weather_stations(lat, lon)"
    end
  end

  def self.calculate_distances
    db = SQLite3::Database.new('ufo.db')
    db.execute("DELETE FROM city_proximities")
    relations = {}
    %w(airports military_bases weather_stations).each do |relation|
      relations[relation] = db.execute("SELECT id, lat, lon FROM #{relation} WHERE lat IS NOT NULL AND lon IS NOT NULL")
    end

    db.transaction do
      db.execute("SELECT id, lat, lon FROM cities WHERE lat IS NOT NULL AND lon IS NOT NULL").each do |city|
        relations.each do |relation, rows|
          smallest_distance_query = nil
          rows.each do |other|
            d = distance(city[1].to_f, city[2].to_f, other[1].to_f, other[2].to_f)
            #puts "#{city[0]}" #, #{other[0]}, #{relation}, #{d}"
            query = ["INSERT INTO city_proximities (city_id, relation_id, relation, distance) VALUES (?, ?, ?, ?)", 
                    city[0], other[0], relation, d]
            if smallest_distance_query.nil? or smallest_distance_query.last > d
              smallest_distance_query = query
            end
          end
          if smallest_distance_query
            db.execute(*smallest_distance_query)
          end
        end
      end
    end
  end

  def self.add_population_density
    db = SQLite3::Database.new('ufo.db')
    file_path = File.join(File.expand_path(File.dirname(__FILE__)), "../data", "population_density_by_county.csv")
    FasterCSV.foreach(file_path, :headers => true) do |line|
      puts "updating..."
      db.execute("UPDATE counties SET population_density = ? WHERE id IN (SELECT c.id FROM counties c JOIN states s ON s.id = c.state_id WHERE c.name like ? AND s.name like ?)", line[6].to_f * 100 , line[5].gsub(/County.*/i, '').strip, line[2].strip)
    end
  end

  def self.clear_banned_data

    #UNSAFE, SQL INJECTIONS CAN BE DONE HERE!
    db = SQLite3::Database.new('ufo.db')
    db.transaction do
      result = db.execute("SELECT s.id, c.id, si.id FROM states s JOIN cities c ON s.id = c.state_id JOIN sightings si ON si.city_id = c.id WHERE s.name IN ('#{ BANNED_LOCATIONS.join("', '") }')")
      db.execute("DELETE FROM sightings WHERE id in (#{result.map{|m| m[2].to_i}.join(", ")})")
      db.execute("DELETE FROM cities WHERE id in (#{result.map{|m| m[1].to_i}.join(", ")})")
      db.execute("DELETE FROM states WHERE id in (#{result.map{|m| m[0].to_i}.join(", ")})")
    end
  end

  def self.group_shapes
    db = SQLite3::Database.new('ufo.db')
    db.transaction do
      query = %{
        DELETE FROM sighting_types;
        INSERT INTO sighting_types(name, img_name, color) VALUES('polygon', 'blue.png', '0000FF');
        INSERT INTO sighting_types(name, img_name, color) VALUES('changing', 'red.png', 'FF0000');
        INSERT INTO sighting_types(name, img_name, color) VALUES('unknown', 'green.png', '00FF00');
        INSERT INTO sighting_types(name, img_name, color) VALUES('other', 'yellow.png', 'FFFF00');
        INSERT INTO sighting_types(name, img_name, color) VALUES('round', 'orange.png', 'FF8000');
        INSERT INTO sighting_types(name, img_name, color) VALUES('triangle', 'purple.png', '8000FF');
        INSERT INTO sighting_types(name, img_name, color) VALUES('light', 'star.png', '00FFFF');
        UPDATE shapes SET type_id = (SELECT id FROM sighting_types WHERE name like 'polygon') 
          WHERE name IN ('Rectangle', 'Diamond', 'Chevron');
        UPDATE shapes SET type_id = (SELECT id FROM sighting_types WHERE name like 'changing')
          WHERE name IN ('Changing');
        UPDATE shapes SET type_id = (SELECT id FROM sighting_types WHERE name like 'unknown')
          WHERE name IN ('Unknown', 'Other');
        UPDATE shapes SET type_id = (SELECT id FROM sighting_types WHERE name like 'other')
          WHERE name IN ('Teardrop', 'Cigar', 'Cylinder', 'Crescent');
        UPDATE shapes SET type_id = (SELECT id FROM sighting_types WHERE name like 'round')
          WHERE name IN ('Circle', 'Sphere', 'Oval', 'Egg', 'Disk');
        UPDATE shapes SET type_id = (SELECT id FROM sighting_types WHERE name like 'triangle')
          WHERE name IN ('Triangle', 'Cone');
        UPDATE shapes SET type_id = (SELECT id FROM sighting_types WHERE name like 'light')
          WHERE name IN ('Light', 'Fireball', 'Flash');
      }
      
=begin
      query = %{
      UPDATE shapes SET group_reference=1, group_name='Polygon' WHERE name IN ('Rectangle','Hexagon','Diamond','Chevron');
      UPDATE shapes SET group_reference=2, group_name='Variable' WHERE name IN ('changed','Changing','Unknown');
      UPDATE shapes SET group_reference=3, group_name='Oval' WHERE name IN ('Crescent','Cylinder','Other','Teardrop','Cross','Cigar','Formation');
      UPDATE shapes SET group_reference=4, group_name='Sphere' WHERE name in ('Disk','Round','Circle','Dome','Sphere','Egg','Oval');
      UPDATE shapes SET group_reference=5, group_name='Cube' WHERE name in ('Delta','Triangle','pyramid','Cone');
      UPDATE shapes SET group_reference=6, group_name='Flash' WHERE name in ('Flare','Light','Flash','Fireball');
      }
=end
      db.execute_batch query
    end
  end

  def self.insert_airports
    data = File.new(File.join("../", "data", "GlobalAirportDatabase.txt"))
    db = SQLite3::Database.new('ufo.db')
    db.transaction do
      db.execute("DELETE FROM airports") 
      while line = data.gets do
        columns = line.split(":")
        if columns[4] == "USA"
          lat = degrees_to_decimal(columns[5].to_f, columns[6].to_f, columns[7].to_f, columns[8])
          lon = degrees_to_decimal(columns[9].to_f, columns[10].to_f, columns[11].to_f, columns[12])
          db.execute("INSERT INTO airports(name,city,lat,lon) VALUES(?, ?, ?, ?)", columns[0], columns[2], lat, lon)
        end
      end
    end
  end

  def self.add_weather_conditions
    j = 0
    db = SQLite3::Database.new('ufo.db')
    db.execute('SELECT states.name_abbreviation, c.name, s.occurred_at, s.id AS sighting_id FROM sightings s JOIN cities c ON c.id = s.city_id JOIN states ON states.id = c.state_id WHERE temperature IS NULL or weather_conditions IS NULL').each do |sighting|
      state = sighting[0] 
      #break if (j+=1) > 10
      city = sighting[1]
      puts sighting[2]
      occurred_at = DateTime.parse sighting[2]
      url = "http://www.wunderground.com/cgi-bin/findweather/getForecast?airportorwmo=query&historytype=DailyHistory&backurl=%2Fhistory%2Findex.html&code=#{URI.encode(city)}%2C+#{URI.encode(state)}&month=#{occurred_at.month}&day=#{occurred_at.day}&year=#{occurred_at.year}"
      result = open(url)
      if result and result.is_a? String
        result = result.split "\n"
        if result.length < 500
          #find proper row
          result.each_with_index do |row, i|
            next if i < 2
            fields = row.strip_html.split(",")
            next if fields.empty?
            next if fields[0].include? "No daily or hourly history data available"
            day_time = DateTime.parse(fields[0])
            #Get proper time
            event = Time.mktime(occurred_at.year, occurred_at.month, occurred_at.day, day_time.strftime("%H"), day_time.strftime("%M")).to_datetime
            if result.length == i + 1 or occurred_at < event
              temperature = fields[1].to_f.round
              condition = fields[11]
              puts "temperature: #{temperature} condition: #{condition} #{i}/#{result.length}"
              db.execute("UPDATE sightings SET temperature = ?, weather_conditions = ? WHERE id = ?", temperature, condition, sighting[3])
              break
            end
          end
        else
          puts "Error took place with url: #{url}"
        end
      end
    end
  end

  def self.insert_military_bases
    data = IO.read(File.join("../", "data", "world_military_bases.kml"))
    db = SQLite3::Database.new('ufo.db')
    xml_doc = Nokogiri.XML(data)
    db.transaction do
      db.execute "DELETE FROM military_bases"
      xml_doc.xpath("//xmlns:Placemark").each do |place_mark|
        name = place_mark.xpath("xmlns:name").first.content
        lon, lat = *place_mark.xpath("xmlns:Point/xmlns:coordinates").first.content.split(",").map{|x| x.to_f}
        #puts "#{name} lat #{lat} lon#{lon}"
        db.execute("INSERT INTO military_bases (name, lat, lon) VALUES( ?, ?, ?)", name, lat, lon)
      end
    end
  end

  def self.import_geographical_centers_states
    data = IO.read(File.join("../", "data", "geographical_center_of_state.html"))
    db = SQLite3::Database.new('ufo.db')
    Nokogiri::HTML(data).xpath("//table/tbody/tr").each_with_index do |row,i|
      if i==0
        next
      end
      columns = row.xpath("td")
      state = columns[0].content.strip_html
      result = db.execute("SELECT id FROM states WHERE name like ?", state)
      raise "Error, state #{state} not found" if result.empty?
      lat_lon_raw = columns[1].content.strip_html
      lat_lon_raw = lat_lon_raw.scan(/(\d+\.*\d*)'(\d+\.*\d*)'?(\d+\.*\d*)?'?(\D)/)
      #In 100ths
      lat,lon = degrees_to_decimal(*lat_lon_raw[1]), degrees_to_decimal(*lat_lon_raw[0])
      puts "lat:#{lat} lon:#{lon}"
      db.execute("UPDATE states SET lat = ?, lon = ? WHERE id = ?", lat, lon, result.first.first)
    end
    nil
  end

  def self.import_geographical_centers_counties
    db = SQLite3::Database.new('ufo.db')
    FasterCSV.foreach(File.join(File.expand_path(File.dirname(__FILE__)), "../data", "Gaz_counties_national.csv"), :col_sep => "\t", :headers => true) do |row|
      county_record = db.execute("SELECT id FROM counties WHERE name like ?", '%' + row[3].gsub(/\s*county/i, '') + '%')
      if county_record.empty?
        puts "Import error, county record #{row[3]} not found" 
        next
      end
      puts "lat: #{row[8]} lon: #{row[9]}"
      db.execute("UPDATE counties SET lat = ?, lon = ? WHERE id = ?", row[8].to_f, row[9].to_f, county_record.first.first)
    end
  end

  def self.insert_weather_stations
    db = SQLite3::Database.new('ufo.db')
    db.execute("DELETE FROM weather_stations")
    db.transaction do
      rows = Nokogiri::HTML(open("http://weather.noaa.gov/cgi-bin/nsd_country_lookup.pl?country=United%20States")).xpath("//ul/ul/a").each_with_index do |s,i|
        data_table_rows = Nokogiri::HTML(open(s["href"])).xpath("//ul/table/tr")
        name,key,state_abbriviation,lat,lon = nil,nil,nil,nil,nil 
        data_table_rows.each do |row|
          td = row.xpath("td")
          if td.first.content.include?("Station Position")
            lat_lon_raw = td.last.content.strip_html.squeeze(" ").gsub(/\(.*?\).*/, '')
            lat_lon_raw = lat_lon_raw.scan(/(\d+)-(\d+)-?(\d+)?(\D)/)
            lat,lon = degrees_to_decimal(*lat_lon_raw[0]), degrees_to_decimal(*lat_lon_raw[1])
          elsif td.first.content.include?("State")
            state_abbriviation = td.last.content.strip_html
          elsif td.first.content.include?("Station Name")
            name = td.last.content.strip_html
          elsif td.first.content.include?("ICAO Location Indicator")
            key = td.last.content.strip_html
          end
        end
        query = ["INSERT INTO weather_stations (name,key,state_id,lat,lon) VALUES (?,?,(SELECT id FROM states WHERE name_abbreviation like ?),?,?)", name,key,state_abbriviation,lat,lon]
        db.execute *query
      end
    end
  end

  #ENTIRE PROCESS CAN TAKE UPTO 24H
  def self.migrate
=begin
    Scraper.scrape
    Scraper.createdb
    Scraper.update_coordinates_counties_from_api
    Scraper.add_population_density
    Scraper.group_shapes
    Scraper.add_weather_conditions
    Scraper.insert_weather_stations
=end
    #puts "update_city_coordinates"
    #Scraper.update_city_coordinates
    puts "insert_airports"
    Scraper.insert_airports
    puts "insert_military_bases"
    Scraper.insert_military_bases
    puts "import_geographical_centers_states"
    Scraper.import_geographical_centers_states
    puts "import_geographical_centers_counties"
    Scraper.import_geographical_centers_counties
    puts "calculate_distances"
    #Scraper.calculate_distances

  end
end

#Extens string class to be able to get rid of any text that is within HTML elements
class String
  def strip_html
      self.gsub(/<script[^>]*>(.|\s)*?<\/script>/i, "").
           gsub(/<style[^>]*>(.|\s)*?<\/style>/i, "").
           gsub(/<!--(.|\s)*?-->/, "").
           gsub(/(&nbsp;)+|\s+/," ").
           gsub(/<\/?[^>]*>/, "").
           squeeze(" ")
  end 

  def to_date(type = nil)
    return nil if self.empty?
    result = self.split("/")
    least_significant_year = result.last
    if "20#{least_significant_year}".to_i > Time.now.year
      year = "19"
    else
      year = "20"
    end
    result = Chronic.parse [result[0], result[1], year + least_significant_year].join("/")
    if type and type == :db and result
      result = result.strftime "%Y.%m.%d %H:%M:%S"
    end
    result
  end

end

class Time
  def to_datetime
    # Convert seconds + microseconds into a fractional number of seconds
    seconds = sec + Rational(usec, 10**6)

    # Convert a UTC offset measured in minutes to one measured in a
    # fraction of a day.
    offset = Rational(utc_offset, 60 * 60 * 24)
    DateTime.new(year, month, day, hour, min, seconds, offset)
  end

end


RAD_PER_DEG = 0.017453293  #  PI/180
Rmiles = 3956           # radius of the great circle in miles
Rkm = 6371              # radius in kilometers...some algorithms use 6367
Rfeet = Rmiles * 5282   # radius in feet
Rmeters = Rkm * 1000    # radius in meters
def distance( lat1, lon1, lat2, lon2 )

  # the great circle distance d will be in whatever units R is in

  

  @distances = Hash.new   # this is global because if computing lots of track point distances, it didn't make
          # sense to new a Hash each time over potentially 100's of thousands of points

=begin rdoc
given two lat/lon points, compute the distance between the two points using the haversine formula
the result will be a Hash of distances which are key'd by 'mi','km','ft', and 'm'
=end

  dlon = lon2 - lon1
  dlat = lat2 - lat1

  dlon_rad = dlon * RAD_PER_DEG 
  dlat_rad = dlat * RAD_PER_DEG

  lat1_rad = lat1 * RAD_PER_DEG
  lon1_rad = lon1 * RAD_PER_DEG

  lat2_rad = lat2 * RAD_PER_DEG
  lon2_rad = lon2 * RAD_PER_DEG

  # puts "dlon: #{dlon}, dlon_rad: #{dlon_rad}, dlat: #{dlat}, dlat_rad: #{dlat_rad}"

  a = (Math.sin(dlat_rad/2))**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * (Math.sin(dlon_rad/2))**2
  c = 2 * Math.atan2( Math.sqrt(a), Math.sqrt(1-a))

  dMi = Rmiles * c          # delta between the two points in miles
  dKm = Rkm * c             # delta in kilometers
  dFeet = Rfeet * c         # delta in feet
  dMeters = Rmeters * c     # delta in meters

  @distances["mi"] = dMi
  @distances["km"] = dKm
  @distances["ft"] = dFeet
  @distances["m"] = dMeters
  return dKm
end

def degrees_to_decimal(d,m,s,dir)
  deg = d.to_f+(((m.to_f*60)+(s.to_f))/3600.0)
  deg *= -1 if %w(W U S).include?(dir.upcase)
  return deg
end

if ARGV[0] == "scrape"
  Scraper.scrape
end
