class WebDataSource implements DataSource {
  
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
    /* TODO */
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
    
    return sightings;
  }
  
  List<Bucket> sightingCountsByYear()
  {
    return new ArrayList<Bucket>();
  }
  
  List<Bucket> sightingCountsBySeason()
  {
    return new ArrayList<Bucket>();
  }
  
  List<Bucket> sightingCountsByMonth()
  {
    return new ArrayList<Bucket>();
  }
  
  List<Bucket> sightingCountsByHour()
  {
    return new ArrayList<Bucket>();
  }
  
  List<Bucket> sightingCountsByAirportDistance()
  {
    return new ArrayList<Bucket>();
  }
  
  List<Bucket> sightingCountsByWeatherStDistance()
  {
    return new ArrayList<Bucket>();
  }
  
  List<Bucket> sightingCountsByMilitaryBaseDistance()
  {
    return new ArrayList<Bucket>();
  }
  
  List<Bucket> sightingCountsByPopulationDensity()
  {
    return new ArrayList<Bucket>();
  }
  
  List<SightingLite> sightingsByTime(int chunkSize, int chunkNum)
  {
    return new ArrayList<SightingLite>();
  }
  
  Date getLastSightingDate()
  {
    return new Date();
  }
}

