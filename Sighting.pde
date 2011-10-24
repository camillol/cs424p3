/* a sighting is owned by a place */
class Sighting {
  String description;
  SightingType type;
  float airportDist;
  float militaryDist;
  Date localTime;
  Place location;
  
  Sighting(String desc, SightingType type, float airportDist, float milDist, Date localTime, Place location) {
    this.description = desc;
    this.type = type;
    this.airportDist = airportDist;
    this.militaryDist = milDist;
    this.localTime = localTime;
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

class Place {
  int type;  /* city, airport, military base */
  int id;
  Location loc;
  String name;
  int sightingCount;
  
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

int minCountSightings = 0;
int maxCountSightings = 0;

void loadCities()
{
  db.query("select cities.*, count(*) as sighting_count from cities join sightings on sightings.city_id = cities.id group by cities.id;");
  places = new ArrayList<Place>();
  while (db.next()) {
    places.add(new Place(CITY,
      db.getInt("id"),
      new Location(db.getFloat("lat"), db.getFloat("lon")),
      db.getString("name"),
      db.getInt("sighting_count")
    ));
    minCountSightings = (db.getInt("sighting_count") < minCountSightings)?db.getInt("sighting_count"):minCountSightings;
    maxCountSightings = (db.getInt("sighting_count") > maxCountSightings)?db.getInt("sighting_count"):maxCountSightings;
  }
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
  db.query("select * from sightings join shapes on shape_id = shapes.id where city_id = "+p.id+" order by occurred_at;");
  ArrayList<Sighting> sightings = new ArrayList<Sighting>();
  while (db.next()) {
    try{
    sightings.add(new Sighting(
      db.getString("full_description"),
      sightingTypeMap.get(db.getInt("type_id")),
      0.0, /* TODO: fill in airport distance */
      0.0, /* TODO: fill in military base distance */
      dbDateFormat.parse(db.getString("occurred_at")),
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

    PImage image_ = loadImage(UFOImages[0]);
    Place ohare = new Place(0, new Location(41.97, -87.905), "O'Hare");
    SightingType circle2 = new SightingType(image_, UFOColors[2], UFOTypeLabels[2]);
    sightingList.add(new Sighting("A flying circle2", circle2, 0.5, 0.2, new Date(), ohare));
    image_ = loadImage(UFOImages[1]);
    Place newYork = new Place(0, new Location(40.664274,-73.938500), "New York");
    SightingType circle = new SightingType(image_, UFOColors[1], UFOTypeLabels[1]);
    sightingList.add(new Sighting("A flying circle", circle, 0.3, 0.3, new Date(), newYork));
    image_ = loadImage(UFOImages[2]);
    Place chicago = new Place(0, new Location(41.881944,-87.627778), "Chicago");
    SightingType fruit = new SightingType(image_, UFOColors[0], UFOTypeLabels[0]);
    sightingList.add(new Sighting("A flying pineapple", fruit, 0.1, 0.2, new Date(), chicago));
  }
  
  Iterator<Sighting> activeSightingIterator() {
    return sightingList.iterator();
  }
}

