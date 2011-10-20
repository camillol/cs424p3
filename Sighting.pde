/* a sighting is owned by a place */
class Sighting {
  int id;
  SightingType type;
  Date localTime;
  Place location;
  String description_short;
  String description_long;
  public SQLite db;

  Sighting(int id, SightingType type, Date localTime, Place location, String description_short, String description_long) {
    this.id = id; 
    this.type = type;
    this.localTime = localTime;
    this.location = location
    this.description_short = description_short;
    this.description_long = description_long;
    this.db = DataMapper.db;
  }

  Sighting(SQLite record, Place place){
    SightingType sightingType= new SightingType(record.getInt("shapes.id"), record.getString("shapes.name"));
    DateFormat df = new SimpleDateFormat("yyyy.mm.dd hh:mm");
    Date occurred_at = df.parse(record.getString("sightings.occurred_at"));
    new Sighting(record.getString("sightings.id"), sightingType, 
                 occurred_at, place, record.getString("summary_description"), record.getString("full_description") );
  }

}


class SightingType {
  int id;
  PImage icon;
  color colr;
  String name;
  public SQLite db;

  SightingType(int id, String name, PImage icon, color colr) {
    this.id = id;
    this.name = name;
    this.icon = icon;
    this.colr = colr;
    this.db = DataMapper.db;
  }

  SightingType(int id, String name){
    SightingType(id, name, null, null); 
  }
}

class Place {
  int id;
  int type;  /* city, airport, military base */
  Location loc;
  String name;
  public static ArrayList<Place> places;
  public SQLite db;
  ArrayList<Sightings> sightings;


  public static final int STATE  = 1;
  public static final int COUNTY = 2;
  public static final int CITY   = 3;

  Place(int id, int type, Location loc, String name) {
    this.id = id;
    this.type = type;
    this.loc = loc;
    this.name = name;
  }

  Place(SQLite record){
    ResultSetMetaData rsMetaData = record.result.getMetaData();
    int type = getTypeByRelationName(rsMetaData.getTableName(0));
    String relation_name = getRelationNameByType(type)
    return new Place(record.getInt( relation_name + ".id"),
        type, 
        new Location(record.getFloat("lat") / 100, record.getFloat("lon") / 100), 
        record.getString(relation_name + ".name"));
  }

  public String getRelationalJoins(boolean getSightings){
    String join_sightings = " JOIN sightings ON cities.id = sightings.city_id ";
    String join_cities = " JOIN cities ON counties.id = cities.county_id ";
    String join_counties = " JOIN counties ON states.id = counties.state_id ";
    String joins = join_sightings; 
    if(!getSightings)
      joins = "";
    if(type <= COUNTY)
      joins = join_cities + joins;
    if(type == STATE)
      joins = join_counties + joins;
    return joins;
  }

  public String getRelationalJoins(){
    return getRelationalJoins(true);
  }

  public int sightingsCount(){
    String query = "SELECT count(1) AS total FROM " + getRelationNameByType(type) + getRelationalJoins();
    return db.query(query).next().getInt("total");
  }

  public ArrayList<Sighting> sightings(){
    if(sightings == null){
      sightings = new ArrayList<Sighting>();
      String query = "SELECT * FROM sightings " + getRelationalJoins() + " JOIN shapes ON shapes.id = sightings.shape_id WHERE " + getRelationNameByType(type) + ".id = " + id;
      db.query(query);
      while(db.next()){
        sightings.add(new Sighting(db), this);
      }
    }
    return sightings;
  }

  public static String getRelationNameByType(int type){
    switch(type){
      case STATE: return "states";
      case COUNTY: return "counties";
      case CITY: return "cities";
      default: return null;
    }
  }

  public static int getTypeByRelationName(String name){
    for(int i=1; i<=3; ++i){
      String currentName = getPlaceNameByType(i);
      if(currentName.equals(name))
        return i;
    }
  }

  public static ArrayList<Place> allByType(int type){
    if(places==null){
      places = new ArrayList<Place>();
      String query = "SELECT * FROM " + getRelationNameByType(type) + getRelationalJoins(false);
      DataMapper.db.query(query);
      while(DataMapper.db.next()){
        places.add(new Place(DataMapper.db));
      }
    }
    return places; 
  }

  public static Place findById(int id, int type){
    find(type, " id = " + id);
  }
  public static Place findByName(String name, int type){
    find(type, " name like " + name);
  }

  public static Place find(int type, String whereClause){
    DataMapper.db.query("SELECT * FROM " + getRelationNameByType(type) + " WHERE " + whereClause);
    DataMapper.db.next();
    return new Place(DataMapper.db);
  }
}

interface SightingTable {
  Iterator<Sighting> activeSightingIterator();
}

class DummySightingTable implements SightingTable{
  ArrayList<Sighting> sightingList;

  DummySightingTable() {
    //sightingList = new ArrayList<Sighting>();
    //Place chicago = new Place(0, new Location(41.881944, -87.627778), "Chicago");
    //SightingType fruit = new SightingType(loadImage("green.png"), #00FF00, "fruit");
    //sightingList.add(new Sighting("A flying pineapple", fruit, 0.1, 0.2, new Date(), chicago));
    sightingList = Place.findByName("Chicago", Place.CITY).sightings();
  }

  Iterator<Sighting> activeSightingIterator(){
    return sightingList.iterator();
  }
}

