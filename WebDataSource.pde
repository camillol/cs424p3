import org.json.*;

class WebDataSource implements DataSource {
  String baseURL;
  
  WebDataSource(String baseURL)
  {
    this.baseURL = baseURL;
  }
  
  void tsvLoad(String filename, String tag)
  {
    String[] rows = loadStrings(filename);  // actually text lines
    for (int i = 0; i < rows.length; i++) {
      if (trim(rows[i]).length() == 0) {
        continue; // skip empty rows
      }
      if (rows[i].startsWith("#")) {
        continue;  // skip comment lines
      }

      String[] pieces = split(rows[i], TAB);
      
      processRow(pieces, tag);
    }
  }
  
  void processRow(String pieces[], String tag)
  {
    if (tag.equals("sighting_types")) {
      int id = int(pieces[0]);
      sightingTypeMap.put(id, new SightingType(
        id,
        loadImage(pieces[2]),
        color(UFOColors[id-1]),
        pieces[1]
      ));
    }
    else if (tag.equals("states")) {
      int id = int(pieces[0]);
      stateMap.put(id, new State(
        id,
        new Location(float(pieces[3]), float(pieces[4])),
        pieces[2],
        pieces[1]
      ));
    }
    else if (tag.equals("cities")) {
      int id = int(pieces[0]);
      cityMap.put(id, new City(
        id,
        new Location(float(pieces[4]), float(pieces[5])),
        pieces[3],
        0,
        int(pieces[2]),
        int(pieces[1])
      ));
    }
    else if (tag.equals("airports")) {
      int id = int(pieces[0]);
      airportMap.put(id, new Place(AIRPORT,
        id,
        new Location(float(pieces[3]), float(pieces[4])),
        pieces[1],
        0
      ));
    }
    else if (tag.equals("military_bases")) {
      int id = int(pieces[0]);
      militaryBaseMap.put(id, new Place(MILITARY_BASE,
        id,
        new Location(float(pieces[2]), float(pieces[3])),
        pieces[1],
        0
      ));
    }
    else if (tag.equals("weather_stations")) {
      int id = int(pieces[0]);
      weatherStationMap.put(id, new Place(WEATHER_STATION,
        id,
        new Location(float(pieces[4]), float(pieces[5])),
        pieces[1],
        0
      ));
    }
    
    else if (tag.equals("city_dist")) {
      int city_id = int(pieces[0]);
      Place p = cityMap.get(city_id);
      if (p!=null){
        p.airportDist = float(pieces[1]);
        p.militaryDist = float(pieces[2]);
        p.weatherDist = float(pieces[3]);
      }
    }
  }
  
  void loadSightingTypes()
  {
    tsvLoad("sighting_types.tsv", "sighting_types");
  }
  
  void loadStates()
  {
    tsvLoad("states.tsv", "states");
  }
  
  void loadCities()
  {
    tsvLoad("cities.tsv", "cities");
  }
  
  void reloadCitySightingCounts()
  {
    minCountSightings = 10000;
    maxCountSightings = 0;
    totalCountSightings = 0;

    String request = baseURL + "/sighting/counts/" + activeFilter.toString().replaceAll(" ", "%20");
    try {
      JSONObject result = new JSONObject(join(loadStrings(request), ""));
      JSONArray cities = result.getJSONArray("cities");
      for (int i = 0; i < cities.length(); i++) {
        JSONObject city = cities.getJSONObject(i);
        Place p = cityMap.get(city.getInt("id"));
        p.sightingCount = 0;
        
        JSONArray counts = city.getJSONArray("counts");
        int idx = 0;
        for (SightingType st : sightingTypeMap.values()) {
          int typeCount = counts.getInt(idx);
          p.counts[idx] = typeCount;
          if (st.active) p.sightingCount += typeCount;
          idx++;
        }
        minCountSightings = min(p.sightingCount, minCountSightings);
        maxCountSightings = max(p.sightingCount, maxCountSightings);
        totalCountSightings += p.sightingCount;
      }
    }
    catch (JSONException e) {
      println (e);
    }
  }
  
  void loadAirports()
  {
    tsvLoad("airports.tsv", "airports");
  }
  
  void loadMilitaryBases()
  {
    tsvLoad("military_bases.tsv", "military_bases");
  }
  
  void loadWeatherStations()
  {
    tsvLoad("weather_stations.tsv", "weather_stations");
  }
  
  void loadCityDistances()
  {
    tsvLoad("city_dist.tsv", "city_dist");
  }
  
  List<Sighting> sightingsForCity(Place p)
  {
    ArrayList<Sighting> sightings = new ArrayList<Sighting>();
    
    String request = baseURL + "/sighting/forCity/" + p.id + "/" + activeFilter.toString();
    try {
      JSONObject result = new JSONObject(join(loadStrings(request), ""));
      JSONArray sa = result.getJSONArray("sightings");
      for (int i = 0; i < sa.length(); i++) {
        JSONObject s = sa.getJSONObject(i);
        try {
          sightings.add(new Sighting(
            s.getString("full_description"),
            sightingTypeMap.get(s.getInt("type_id")),
            s.getString("name"),
            0.0, /* TODO: fill in airport distance */
            0.0, /* TODO: fill in military base distance */
            dbDateFormat.parse(s.getString("occurred_at")),
            dbDateFormat.parse(s.getString("posted_at")),
            p,
            s.getString("weather_conditions"),
            s.getInt("temperature")
          ));
        }
        catch(Exception ex){
          println(ex); 
        }
      }
    }
    catch (JSONException e) {
      println ("There was an error parsing the JSONObject.");
    }
    
    return sightings;
  }
  
  List<Bucket> sightingCountsByCategoryQuery(String categoryName)
  {
    List<Bucket> buckets = new ArrayList();
    
    String request = baseURL + "/sighting/countsByCategory/" + categoryName ;
    try {
      JSONObject result = new JSONObject(join(loadStrings(request), ""));
      JSONArray ba = result.getJSONArray("buckets");
      for (int i = 0; i < ba.length(); i++) {
        JSONObject b = ba.getJSONObject(i);
        String cat = b.getString(categoryName);

        Bucket bucket = new Bucket(cat);
        buckets.add(bucket);

        JSONArray counts = b.getJSONArray("counts");
        int idx = 0;
        for (SightingType st : sightingTypeMap.values()) {
          int typeCount = counts.getInt(idx);
          bucket.counts.put(st, typeCount);
          idx++;
        }
      }
    }
    catch (JSONException e) {
      println ("There was an error parsing the JSONObject.");
    }
    
    return buckets;
  }
  
  List<Bucket> sightingCountsByYear()
  {
    return sightingCountsByCategoryQuery("year");
  }
  
  List<Bucket> sightingCountsBySeason()
  {
    String seasonNames[] = {"Winter", "Spring", "Summer", "Fall"};
    List<Bucket> buckets = sightingCountsByCategoryQuery("season");
    for (Bucket b : buckets) {
      b.label = seasonNames[int(b.label)];
    }
    return buckets;
  }
  
  List<Bucket> sightingCountsByMonth()
  {
    return sightingCountsByCategoryQuery("month");
  }
  
  List<Bucket> sightingCountsByHour()
  {
    return sightingCountsByCategoryQuery("hour");
  }
  
  List<Bucket> sightingCountsByAirportDistance()
  {
    return sightingCountsByCategoryQuery("airport_dist");
  }
  
  List<Bucket> sightingCountsByWeatherStDistance()
  {
    return sightingCountsByCategoryQuery("weather_dist");
  }
  
  List<Bucket> sightingCountsByMilitaryBaseDistance()
  {
    return sightingCountsByCategoryQuery("military_dist");
  }
  
  List<Bucket> sightingCountsByPopulationDensity()
  {
    return sightingCountsByCategoryQuery("pop_density");
  }
  
  List<SightingLite> sightingsByTime(int limit, int offset)
  {
    List<SightingLite> sightings = new ArrayList(limit);
    
    String request = baseURL + "/sighting/byTime/" + limit + "/" + offset;
    try {
      JSONObject result = new JSONObject(join(loadStrings(request), ""));
      JSONArray sa = result.getJSONArray("sightings");
      for (int i = 0; i < sa.length(); i++) {
        JSONObject s = sa.getJSONObject(i);
        try {
          sightings.add(new SightingLite(
            sightingTypeMap.get(s.getInt("type_id")),
            dbDateFormat.parse(s.getString("occurred_at")),
            cityMap.get(s.getInt("city_id"))
          ));
        } catch (ParseException e) {
          println(e);
        }
      }
    }
    catch (JSONException e) {
      println ("There was an error parsing the JSONObject.");
    }
    
    return sightings;
  }
  
  Date getLastSightingDate()
  {
    String request = baseURL + "/lastSightingDate";
    try {
      return dbDateFormat.parse(join(loadStrings(request), ""));
    } catch (ParseException e) {
      println(e);
      return null;
    }
  }
}

