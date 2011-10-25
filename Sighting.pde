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
  
  Sighting(String desc, SightingType type, String shapeName, float airportDist, float milDist, Date localTime,Date reportedTime, Place location) {
    this.description = desc;
    this.type = type;
    this.shapeName = shapeName;
    this.airportDist = airportDist;
    this.militaryDist = milDist;
    this.localTime = localTime;
    this.reportedTime = reportedTime;
    this.location = location;
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
  int typeOfSightingCount;
  int sightingType;
  
  Place(int type, int id, Location loc, String name, int sightingCount,int typeOfSightingCount,int sightingType) {
    this.type = type;
    this.id = id;
    this.loc = loc;
    this.name = name;
    this.sightingCount = sightingCount;
    this.typeOfSightingCount = typeOfSightingCount;
    this.sightingType = sightingType;
  }

  /* only for dummy data */
  Place(int type, Location loc, String name) {
    this(type, -1, loc, name, 0,0,0);
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
  db.query("select cities.*, count(*) as sighting_count, count(distinct type_id) as types_count, type_id from cities join sightings on sightings.city_id = cities.id join shapes on shape_id = shapes.id group by cities.id");
  placeMap = new HashMap<Integer,Place>();
  minCountSightings = 1000;
  maxCountSightings = 0;
  while (db.next()) {
    placeMap.put(db.getInt("id"), new Place(CITY,
      db.getInt("id"),
      new Location(db.getFloat("lat"), db.getFloat("lon")),
      db.getString("name"),
      db.getInt("sighting_count"),
      db.getInt("types_count"),
      db.getInt("type_id")
    ));
    minCountSightings = min(db.getInt("sighting_count"), minCountSightings);
    maxCountSightings = max(db.getInt("sighting_count"), maxCountSightings);
  }
  placeTree = new PRTree<Place> (new PlaceMBRConverter(), 10);
  placeTree.load(placeMap.values());
}

void reloadCitySightingCounts()
{
  println("query db for sighting counts");
  db.query("select cities.id, count(*) as sighting_count, count(distinct type_id) as types_count,type_id"
    + " from cities join sightings on sightings.city_id = cities.id join shapes on shape_id = shapes.id"
    + " where occurred_at >= '"+yearMin+".01.01' and occurred_at < '"+yearMax+".01.01'"
    + " group by cities.id");
  minCountSightings = 1000;
  maxCountSightings = 0;
  println("update objects");
  while (db.next()) {
    Place p = placeMap.get(db.getInt("cities.id"));
    p.sightingCount = db.getInt("sighting_count");
    p.typeOfSightingCount = db.getInt("types_count");
    p.sightingType = db.getInt("type_id");
    minCountSightings = min(p.sightingCount, minCountSightings);
    maxCountSightings = max(p.sightingCount, maxCountSightings);
  }
  println("done");
}

void loadAirports()
{
 /* db.query("select cities.*, count(*) as sighting_count from cities join sightings on sightings.city_id = cities.id group by cities.id");
  airports = new ArrayList<Airport>();
  while (db.next()) {
    places.add(new Place(AIRPORT,
      db.getInt("id"),
      new Location(db.getFloat("lat"), db.getFloat("lon")),
      db.getString("name"),
      db.getInt("sighting_count")
    ));
  }*/
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

void loadSightingTypes()
{
  db.query("select * from sighting_types;");
  sightingTypeMap = new HashMap<Integer, SightingType>();
  while (db.next()) {
    sightingTypeMap.put(db.getInt("id"), new SightingType(
      db.getInt("id"),
      loadImage(db.getString("img_name")),
      color(db.getInt("color")),
      db.getString("name")
    ));
  }
}

List<Sighting> sightingsForCity(Place p)
{
  db.query("select * from sightings join shapes on shape_id = shapes.id where city_id = "+p.id+" and occurred_at >= '"+yearMin+".01.01' and occurred_at < '"+yearMax+".01.01' order by occurred_at;");
  
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
      p
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

