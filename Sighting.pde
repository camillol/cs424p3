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
  
  SightingType(int id, PImage icon, color colr, String name) {
    this.id = id;
    this.icon = icon;
    this.colr = colr;
    this.name = name;
  }

  /* for dummy data */
  SightingType(PImage icon, color colr, String name) {
    this(-1, icon, colr, name);
  }
}

final static int CITY = 0;
final static int AIRPORT = 1;

class Place {
  int type;  /* city, airport, military base */
  int id;
  Location loc;
  String name;
  int sightingCount;
  int typeOfSightingCount = 7;
  int sightingType;
  
  Place(int type, int id, Location loc, String name, int sightingCount) {
    this.type = type;
    this.id = id;
    this.loc = loc;
    this.name = name;
    this.sightingCount = sightingCount;
  }

  /* only for dummy data */
  Place(int type, Location loc, String name) {
    this(type, -1, loc, name, 0);
  }
}

class PlaceMBRConverter implements MBRConverter<Place> {
  double getMaxX(Place p) { return p.loc.lon; }
  double getMinX(Place p) { return p.loc.lon; }
  double getMaxY(Place p) { return p.loc.lat; }
  double getMinY(Place p) { return p.loc.lat; }
}

int minCountSightings;
int maxCountSightings;

void loadCities()
{
  stopWatch();
  print("Loading cities...");
  db.query("select cities.*, count(*) as sighting_count from cities join sightings on sightings.city_id = cities.id group by cities.id");
  placeMap = new HashMap<Integer,Place>();
  minCountSightings = 1000;
  maxCountSightings = 0;
  while (db.next()) {
    placeMap.put(db.getInt("id"), new Place(CITY,
      db.getInt("id"),
      new Location(db.getFloat("lat"), db.getFloat("lon")),
      db.getString("name"),
      db.getInt("sighting_count")
    ));
    minCountSightings = min(db.getInt("sighting_count"), minCountSightings);
    maxCountSightings = max(db.getInt("sighting_count"), maxCountSightings);
  }
  println(stopWatch());
  print("Building R-tree...");
  placeTree = new PRTree<Place> (new PlaceMBRConverter(), 10);
  placeTree.load(placeMap.values());
  println(stopWatch());
}

class SightingsFilter {
  final static int yearFirst = 2000, yearLast = 2011;
  int viewMinYear = yearFirst, viewMaxYear = yearLast;
  int viewMinMonth = 1, viewMaxMonth = 12;
  int viewMinHour = 0, viewMaxHour = 23;
  String viewUFOType = "";
  
  String whereClause()
  {
    StringBuffer where = new StringBuffer();
    
    if (viewMinYear > yearFirst) where.append("cast(strftime('%Y',occurred_at) as integer) >= " + viewMinYear + " and ");
    if (viewMaxYear < yearLast) where.append("cast(strftime('%Y',occurred_at) as integer) <= " + viewMaxYear + " and ");
    if (viewMinMonth > 1) where.append("cast(strftime('%m',occurred_at) as integer) >= " + viewMinMonth + " and ");
    if (viewMaxMonth < 12) where.append("cast(strftime('%m',occurred_at) as integer) <= " + viewMaxMonth + " and ");
    if (viewMinHour > 0) where.append("cast(strftime('%H',occurred_at) as integer) >= " + viewMinHour + " and ");
    if (viewMaxHour < 23) where.append("cast(strftime('%H',occurred_at) as integer) <= " + viewMaxHour + " and ");
    if (viewUFOType.length() > 0) where.append("type_id IN ("+viewUFOType+") and ");
    
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
      viewUFOType == other.viewUFOType;
  }
}

void reloadCitySightingCounts()
{
  stopWatch();
  print("query db for sighting counts...");
  db.query("select cities.id, count(*) as sighting_count, count(distinct type_id) as types_count,type_id"
    + " from cities join sightings on sightings.city_id = cities.id join shapes on shape_id = shapes.id"
    + " where " + activeFilter.whereClause()
    + " group by cities.id");
  
  minCountSightings = 1000;
  maxCountSightings = 0;
  println(stopWatch());
  print("update objects...");
 
  //Clean the places values
  for (Place pl : placeMap.values()) {
    pl.sightingCount = 0;
    pl.typeOfSightingCount = 0;
    pl.sightingType = 0;
  }
  
  while (db.next()) {
    Place p = placeMap.get(db.getInt("id"));
    p.sightingCount = db.getInt("sighting_count");
    p.typeOfSightingCount = db.getInt("types_count");
    p.sightingType = db.getInt("type_id");
    minCountSightings = min(p.sightingCount, minCountSightings);
    maxCountSightings = max(p.sightingCount, maxCountSightings);
  }
  println(stopWatch());
}

void loadAirports()
{
  stopWatch();
  print("Loading airports...");
  db.query("select * from airports");
  airportsMap = new HashMap<Integer,Place>();

  while (db.next()) {
    airportsMap.put(db.getInt("id"), new Place(AIRPORT,
      db.getInt("id"),
      new Location((db.getFloat("lat")/100), (db.getFloat("lon")/100)),
      db.getString("name"),
      0
    ));
  }
  println(stopWatch());
  print("Building airport R-tree...");
  
  airportsTree = new PRTree<Place> (new PlaceMBRConverter(), 10);
  airportsTree.load(airportsMap.values());
  println(stopWatch());
}

void loadMilitaryBases()
{
  stopWatch();
  print("Loading military bases...");
  db.query("select * from military_bases");
  militaryBaseMap = new HashMap<Integer,Place>();

  while (db.next()) {
    militaryBaseMap.put(db.getInt("id"), new Place(AIRPORT,
      db.getInt("id"),
      new Location((db.getFloat("lat")/100), (db.getFloat("lon")/100)),
      db.getString("name"),
      0
    ));
  }
  println(stopWatch());
  print("Building military bases R-tree...");
  
  militaryBaseTree = new PRTree<Place> (new PlaceMBRConverter(), 10);
  militaryBaseTree.load(militaryBaseMap.values());
  println(stopWatch());
}

Iterable<Place> placesInRect(Location locTopLeft, Location locBottomRight, double expandFactor)
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
  
  return placeTree.find(minLon, minLat, maxLon, maxLat);
}

Iterable<Place> aiportsInRect(Location locTopLeft, Location locBottomRight, double expandFactor)
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
  
  return airportsTree.find(minLon, minLat, maxLon, maxLat);
}

void loadSightingTypes()
{
  db.query("select * from sighting_types;");
  sightingTypeMap = new HashMap<Integer, SightingType>();
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

interface SightingTable {
  Iterator<Sighting> activeSightingIterator();
}

class DummySightingTable implements SightingTable {
  ArrayList<Sighting> sightingList;
  
  DummySightingTable() {
      sightingList = new ArrayList<Sighting>();

  
  }
  
  Iterator<Sighting> activeSightingIterator() {
    return sightingList.iterator();
  }
}

