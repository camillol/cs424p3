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
  PImage icon;
  color colr;
  String name;
  
  SightingType(PImage icon, color colr, String name) {
    this.icon = icon;
    this.colr = colr;
    this.name = name;
  }
}

final static int CITY = 0;

class Place {
  int type;  /* city, airport, military base */
  Location loc;
  String name;
  int sightingCount;
  
  Place(int type, Location loc, String name, int sightingCount) {
    this.type = type;
    this.loc = loc;
    this.name = name;
    this.sightingCount = sightingCount;
  }

  Place(int type, Location loc, String name) {
    this(type, loc, name, 0);
  }
}

void loadCities()
{
  db.query("select cities.*, count(*) as sighting_count from cities join sightings on sightings.city_id = cities.id group by cities.id;");
  places = new ArrayList<Place>();
  while (db.next()) {
    places.add(new Place(CITY, new Location(db.getFloat("lat"), db.getFloat("lon")), db.getString("name"), db.getInt("sighting_count")));
  }
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

