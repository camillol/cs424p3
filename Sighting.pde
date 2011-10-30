/* a sighting is owned by a place */
class Sighting {
  String description;
  SightingType type;
  float airportDist;
  float militaryDist;
  Date localTime;
  Date reportedTime;
  Place location;
  String shapeName;
  String weather;
  int temperature;
  
  Sighting(String desc, SightingType type, String shapeName, float airportDist, float milDist, Date localTime,Date reportedTime, Place location,String weather, int temperature) {
    this.description = desc;
    this.type = type;
    this.shapeName = shapeName;
    this.airportDist = airportDist;
    this.militaryDist = milDist;
    this.localTime = localTime;
    this.reportedTime = reportedTime;
    this.location = location;
    this.weather = weather;
    this.temperature = temperature;
  }
}


class SightingType {
  int id;
  PImage icon;
  color colr;
  String name;
  
  boolean active;
  Animator activeAnimator;
  
  SightingType(int id, PImage icon, color colr, String name) {
    this.id = id;
    this.icon = icon;
    this.colr = colr;
    this.name = name;
    
    active = true;
    activeAnimator = new Animator(1.0);
  }

  /* for dummy data */
  SightingType(PImage icon, color colr, String name) {
    this(-1, icon, colr, name);
  }
  
  void setActive(boolean act)
  {
    active = act;
    activeAnimator.target(active ? 1.0 : 0.0);
  }
}

final static int CITY = 0;
final static int AIRPORT = 1;
final static int MILITARY_BASE = 2;
final static int WEATHER_STATION = 3;
final static int STATE = 4;

class Place {
  int type;  /* city, airport, military base */
  int id;
  Location loc;
  String name;
  int sightingCount;
  int counts[];
  
  Place(int type, int id, Location loc, String name, int sightingCount) {
    this.type = type;
    this.id = id;
    this.loc = loc;
    this.name = name;
    this.sightingCount = sightingCount;
    counts = new int[sightingTypeMap.size()];
  }

  /* only for dummy data */
  Place(int type, Location loc, String name) {
    this(type, -1, loc, name, 0);
  }
}

class City extends Place {
  int county_id;
  int state_id;
  
  City(int id, Location loc, String name, int sightingCount, int state_id, int county_id) {
    super(CITY, id, loc, name, sightingCount);
    this.state_id = state_id;
    this.county_id = county_id;
  }
}

class State extends Place {
  String abbr;
  
  State(int id, Location loc, String name, String abbr) {
    super(STATE, id, loc, name, 0);
    this.abbr = abbr;
  }
}

class PlaceMBRConverter implements MBRConverter<Place> {
  double getMaxX(Place p) { return p.loc.lon; }
  double getMinX(Place p) { return p.loc.lon; }
  double getMaxY(Place p) { return p.loc.lat; }
  double getMinY(Place p) { return p.loc.lat; }
}

void buildPlaceTree()
{
  /* build spatial index of places */
  print("Building R-tree...");
  cityTree = new PRTree<Place> (new PlaceMBRConverter(), 10);
  cityTree.load(cityMap.values());
  
  airportTree = new PRTree<Place> (new PlaceMBRConverter(), 10);
  airportTree.load(airportMap.values());
  
  militaryBaseTree = new PRTree<Place> (new PlaceMBRConverter(), 10);
  militaryBaseTree.load(militaryBaseMap.values());
  
  weatherStationTree = new PRTree<Place> (new PlaceMBRConverter(), 10);
  weatherStationTree.load(weatherStationMap.values());
  println(stopWatch());
}


int minCountSightings;
int maxCountSightings;
int totalCountSightings;

class SightingsFilter {
  final static int yearFirst = 2000, yearLast = 2011;
  int viewMinYear = yearFirst, viewMaxYear = yearLast;
  int viewMinMonth = 1, viewMaxMonth = 12;
  int viewMinHour = 0, viewMaxHour = 23;
  Set<SightingType> activeTypes = new HashSet(sightingTypeMap.values());
  
  String whereClause()
  {
    StringBuffer where = new StringBuffer();
    
    if (viewMinYear > yearFirst) where.append("cast(strftime('%Y',occurred_at) as integer) >= " + viewMinYear + " and ");
    if (viewMaxYear < yearLast) where.append("cast(strftime('%Y',occurred_at) as integer) <= " + viewMaxYear + " and ");
    if (viewMinMonth > 1) where.append("cast(strftime('%m',occurred_at) as integer) >= " + viewMinMonth + " and ");
    if (viewMaxMonth < 12) where.append("cast(strftime('%m',occurred_at) as integer) <= " + viewMaxMonth + " and ");
    if (viewMinHour > 0) where.append("cast(strftime('%H',occurred_at) as integer) >= " + viewMinHour + " and ");
    if (viewMaxHour < 23) where.append("cast(strftime('%H',occurred_at) as integer) <= " + viewMaxHour + " and ");
    if (activeTypes != null && activeTypes.size() < sightingTypeMap.size()) {
      where.append("type_id IN (");
      boolean first = true;
      for (SightingType st : activeTypes) {
        if (first) first = false;
        else where.append(",");
        where.append(st.id);
      }
      where.append(") and ");
    }
    
    where.append("1 ");
    return where.toString();
  }
  
  boolean equals(SightingsFilter other)
  {
    return viewMinYear == other.viewMinYear &&
      viewMaxYear == other.viewMaxYear &&
      viewMinMonth == other.viewMinMonth &&
      viewMaxMonth == other.viewMaxMonth &&
      viewMinHour == other.viewMinHour &&
      viewMaxHour == other.viewMaxHour &&
      activeTypes.equals(other.activeTypes);
  }
  
  String toString()
  {
    return viewMinYear + "-" + viewMaxYear + " "
      + viewMinMonth + "-" + viewMaxMonth + " "
      + viewMinHour + "-" + viewMaxHour + " "
      + activeTypes;
  }
}

Iterable<Place> placesInRect(PRTree<Place> tree, Location locTopLeft, Location locBottomRight, double expandFactor)
{
  double minLon = locTopLeft.lon;
  double maxLon = locBottomRight.lon;
  double minLat = locBottomRight.lat;
  double maxLat = locTopLeft.lat;
  double fudgeLat = (maxLat - minLat) * expandFactor;
  double fudgeLon = (maxLon - minLon) * expandFactor;
  
  minLon -= fudgeLon;
  maxLon += fudgeLon;
  minLat -= fudgeLat;
  maxLat += fudgeLat;
  
  return tree.find(minLon, minLat, maxLon, maxLat);
}
  
void updateStateSightingCounts()
{
  int idx;

  stopWatch();
  print("updating state sighting counts...");
  for (State s : stateMap.values()) {
    for (idx = 0; idx < sightingTypeMap.size(); idx++)
      s.counts[idx] = 0;
    s.sightingCount = 0;
  }
  for (Place p : cityMap.values()) {
    City c = (City)p;
    State s = stateMap.get(c.state_id);
    for (idx = 0; idx < sightingTypeMap.size(); idx++) {
      s.counts[idx] += c.counts[idx];
      s.sightingCount += c.counts[idx];
    }
  }
  println(stopWatch());
}


interface DataSource {
  void loadSightingTypes();
  void loadStates();
  void loadCities();
  void reloadCitySightingCounts();
  void loadAirports();
  void loadMilitaryBases();
  void loadWeatherStations();
  List<Sighting> sightingsForCity(Place p);
  List<Bucket> sightingCountsByYear();
  List<Bucket> sightingCountsByMonth();
  List<Bucket> sightingCountsByHour();
}

class Bucket {
  String label;
  Map<SightingType, Integer> counts;
  
  Bucket(String label)
  {
    this.label = label;
    counts = new LinkedHashMap<SightingType, Integer>();
  }
}

/*
  bucket sets we need to support:
  - distance from airport
  - population density
  - time of day
  - month
  - season??
  - unemployment (by county and year)?
  - income??
*/

/* SQLite DB access */

import de.bezier.data.sql.*;

class SQLiteDataSource implements DataSource {
  SQLite db;

  SQLiteDataSource()
  {
    db = new SQLite(papplet, "ufo.db");
    if (!db.connect()) println("DB connection failed!");
    db.execute("PRAGMA cache_size=100000;");
  }
  
  void loadCities()
  {
    stopWatch();
    print("Loading cities...");
    db.query("select cities.*, count(*) as sighting_count from cities join sightings on sightings.city_id = cities.id group by cities.id");
    cityMap = new HashMap<Integer,Place>();
    minCountSightings = 1000;
    maxCountSightings = 0;
    while (db.next()) {
      cityMap.put(db.getInt("id"), new City(
        db.getInt("id"),
        new Location(db.getFloat("lat"), db.getFloat("lon")),
        db.getString("name"),
        db.getInt("sighting_count"),
        db.getInt("state_id"),
        db.getInt("county_id")
      ));
      minCountSightings = min(db.getInt("sighting_count"), minCountSightings);
      maxCountSightings = max(db.getInt("sighting_count"), maxCountSightings);
    }
    println(stopWatch());
  }
  
  void loadStates()
  {
    stopWatch();
    print("Loading states...");
    db.query("select * from states");
    stateMap = new HashMap<Integer,State>();
    while (db.next()) {
      stateMap.put(db.getInt("id"), new State(
        db.getInt("id"),
        new Location(db.getFloat("lat"), db.getFloat("lon")),
        db.getString("name"),
        db.getString("name_abbreviation")
      ));
    }
    println(stopWatch());
  }

  void reloadCitySightingCounts()
  {
    stopWatch();
    print("query db for sighting counts...");
    StringBuffer query = new StringBuffer();
    query.append("select cities.id");
    for (SightingType st : sightingTypeMap.values()) {
      query.append(", sum(case when type_id=" + st.id + " then 1 else 0 end) as count_" + st.id);
    }
    query.append(" from cities join sightings on sightings.city_id = cities.id join shapes on shape_id = shapes.id");
    query.append(" where " + activeFilter.whereClause());
    query.append(" group by cities.id");
    
    db.query(query.toString());
    
    minCountSightings = 10000;
    maxCountSightings = 0;
    totalCountSightings = 0;
    
    println(stopWatch());
    print("update objects...");
   
    while (db.next()) {
      Place p = cityMap.get(db.getInt("id"));
      p.sightingCount = 0;
      int idx = 0;
      for (SightingType st : sightingTypeMap.values()) {
        int typeCount = db.getInt("count_" + st.id);
        p.counts[idx] = typeCount;
        p.sightingCount += typeCount;
        idx++;
      }
      minCountSightings = min(p.sightingCount, minCountSightings);
      maxCountSightings = max(p.sightingCount, maxCountSightings);
      totalCountSightings += p.sightingCount;
    }
    println(stopWatch());
  }
  
  void loadAirports()
  {
    stopWatch();
    print("Loading airports...");
    db.query("select * from airports");
    airportMap = new HashMap<Integer,Place>();
  
    while (db.next()) {
      airportMap.put(db.getInt("id"), new Place(AIRPORT,
        db.getInt("id"),
        new Location((db.getFloat("lat")/100), (db.getFloat("lon")/100)),
        db.getString("name"),
        0
      ));
    }
    println(stopWatch());
  }
  
  void loadMilitaryBases()
  {
    stopWatch();
    print("Loading military bases...");
    db.query("select * from military_bases");
    militaryBaseMap = new HashMap<Integer,Place>();
  
    while (db.next()) {
      militaryBaseMap.put(db.getInt("id"), new Place(MILITARY_BASE,
        db.getInt("id"),
        new Location((db.getFloat("lat")/100), (db.getFloat("lon")/100)),
        db.getString("name"),
        0
      ));
    }
    println(stopWatch());
  }
  
  void loadWeatherStations()
  {
    stopWatch();
    print("Loading weather stations...");
    db.query("select * from military_bases");
    weatherStationMap = new HashMap<Integer,Place>();
  
    while (db.next()) {
      weatherStationMap.put(db.getInt("id"), new Place(WEATHER_STATION,
        db.getInt("id"),
        new Location((db.getFloat("lat")/100), (db.getFloat("lon")/100)),
        db.getString("name"),
        0
      ));
    }
    println(stopWatch());
  }

  void loadSightingTypes()
  {
    db.query("select * from sighting_types;");
    sightingTypeMap = new LinkedHashMap<Integer, SightingType>();
    while (db.next()) {
      sightingTypeMap.put(db.getInt("id"), new SightingType(
        db.getInt("id"),
        loadImage(db.getString("img_name")),
        color(unhex("FF"+db.getString("color"))),
        db.getString("name")
      ));
    }
  }
  
  List<Sighting> sightingsForCity(Place p)
  {
    db.query("select * from sightings join shapes on shape_id = shapes.id"
      + " where city_id = " + p.id + " and " + activeFilter.whereClause()
      + " order by occurred_at;");
    
    ArrayList<Sighting> sightings = new ArrayList<Sighting>();
    while (db.next()) {
      try{
      sightings.add(new Sighting(
        db.getString("full_description"),
        sightingTypeMap.get(db.getInt("type_id")),
        db.getString("name"),
        0.0, /* TODO: fill in airport distance */
        0.0, /* TODO: fill in military base distance */
        dbDateFormat.parse(db.getString("occurred_at")),
        dbDateFormat.parse(db.getString("posted_at")),
        p,
        db.getString("weather_conditions"),
        db.getInt("temperature")
      ));
      }
      catch(Exception ex){
        println(ex); 
      }
    }
  
    return sightings;
  }
 
  List<Bucket> sightingCountsByYear()
  {
    return sightingCountsByCategoryQuery(
      "select strftime('%Y',occurred_at) as year, type_id, count(*) as sighting_count"
      + " from sightings join shapes on shape_id = shapes.id group by year, type_id;",
      "year");
  }
  
  List<Bucket> sightingCountsByMonth()
  {
    return sightingCountsByCategoryQuery(
      "select strftime('%m',occurred_at) as month, type_id, count(*) as sighting_count"
      + " from sightings join shapes on shape_id = shapes.id group by month, type_id;",
      "month");
  }
  
  List<Bucket> sightingCountsByHour()
  {
    return sightingCountsByCategoryQuery(
      "select strftime('%H',occurred_at) as hour, type_id, count(*) as sighting_count"
      + " from sightings join shapes on shape_id = shapes.id group by hour, type_id;",
      "hour");
  }
  
  List<Bucket> sightingCountsByCategoryQuery(String query, String categoryName)
  {
    List<Bucket> buckets = new ArrayList();
    
    db.query(query);
    
    String prev_cat = "NOPE!";
    Bucket bucket = null;
    
    while (db.next()) {
      String cat = db.getString(categoryName);
      SightingType type = sightingTypeMap.get(db.getInt("type_id"));
      int count = db.getInt("sighting_count");
      
      if (!cat.equals(prev_cat)) {
        bucket = new Bucket(cat);
        buckets.add(bucket);
        prev_cat = cat;
      }
      bucket.counts.put(type, count);
    }
    return buckets;
  }
}

