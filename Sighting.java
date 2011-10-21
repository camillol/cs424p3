import de.bezier.data.sql.*;

/* a sighting is owned by a place */
import java.util.Iterator;
import java.util.Date;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.text.ParseException;
import processing.core.*;
import java.awt.Color;
import com.modestmaps.*;
import com.modestmaps.geo.Location;
import java.util.ArrayList;
import java.sql.ResultSetMetaData;
import javax.*;

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
    this.location = location;
    this.description_short = description_short;
    this.description_long = description_long;
    this.db = DataMapper.db;
  }

  Sighting(SQLite record, Place place){
    try{
      for(int i=1; i<40; i++){
        //System.out.println(record.result.getMetaData().getColumnName(i));
      }
    }
    catch(Exception e){
    }
    SightingType sightingType= new SightingType(record.getInt("shape_id"), record.getString("shape_name"));
    DateFormat df = new SimpleDateFormat("yyyy.mm.dd hh:mm");
    Date occurred_at = null;
    try{
      occurred_at = df.parse(record.getString("occurred_at"));
    }
    catch(ParseException e){
      e.printStackTrace();
    }

    new Sighting(record.getInt("sighting_id"), sightingType, 
        occurred_at, place, record.getString("summary_description"), record.getString("full_description") );
  }

}


class SightingType {
  public int id;
  public PImage icon;
  int colr;
  public String name;
  public SQLite db;

  SightingType(int id, String name, PImage icon, int colr) {
    this(id, name); 
    this.colr = colr;
    this.icon = icon;
  }

  SightingType(int id, String name){
    this.id = id;
    this.name = name;
    this.db = DataMapper.db;
    //Load image data
  }
}

class Place {
  int id;
  int type;  /* city, airport, military base */
  Location loc;
  String name;
  public static ArrayList<Place> places;
  public SQLite db;
  ArrayList<Sighting> sightings;


  public static final int STATE  = 1;
  public static final int COUNTY = 2;
  public static final int CITY   = 3;

  Place(int id, int type, Location loc, String name) {
    this.id = id;
    this.type = type;
    this.loc = loc;
    this.name = name;
    this.db = DataMapper.db;
  }

  Place(SQLite record){
    int type = 0;
    boolean coordinates = false;
    try{
      type = getTypeByRelationName(record.result.getMetaData().getTableName(1));
      coordinates = DataMapper.columnExists(record.result.getMetaData(), "lat");
      if(coordinates && type < 3){
        System.out.println("SHOULD NOT GET HERE");
      }
    }
    catch(Exception e) {
      e.printStackTrace();
    }
    String relation_name = getRelationNameByType(type);
    this.id = record.getInt( "id");
    this.type = type;
    if(coordinates)
      this.loc = new Location(record.getFloat("lat") / 100, record.getFloat("lon") / 100);
    this.name = record.getString("name");
    this.db = DataMapper.db;
  }

  public static String getRelationalJoins(int type){
    String join_sightings = " JOIN sightings ON cities.id = sightings.city_id ";
    String join_cities = " JOIN cities ON counties.id = cities.county_id ";
    String join_counties = " JOIN counties ON states.id = counties.state_id ";
    String joins = "";
    if(type < CITY)
      joins = join_cities + joins;
    if(type < COUNTY)
      joins = join_counties + joins;
    joins = join_sightings + joins;
    return joins;
  }

  public String getRelationalJoins(){
    return getRelationalJoins(type);
  }

  public int sightingsCount(){
    String query = "SELECT count(1) AS total FROM " + getRelationNameByType(type) + getRelationalJoins() + " WHERE " + getRelationNameByType(type) + ".id = " + id;
    System.out.println(query);
    db.query(query);
    db.next();
    return db.getInt("total");
  }

  public ArrayList<Sighting> sightings(){
    if(sightings == null){
      sightings = new ArrayList<Sighting>();
      String query = "SELECT *, shapes.name as shape_name, sightings.id as sighting_id FROM  " + getRelationNameByType(type) + getRelationalJoins() + " JOIN shapes ON shapes.id = sightings.shape_id WHERE " + getRelationNameByType(type) + ".id = " + id;
      db.query(query);
      while(db.next()){
        sightings.add(new Sighting(db, this));
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
      String currentName = getRelationNameByType(i);
      if(currentName.equals(name))
        return i;
    }
    return -1;
  }

  public static ArrayList<Place> allByType(int type){
    if(places==null){
      places = new ArrayList<Place>();
      String query = "SELECT * FROM " + Place.getRelationNameByType(type);
      DataMapper.db.query(query);
      while(DataMapper.db.next()){
        places.add(new Place(DataMapper.db));
      }
    }
    return places; 
  }

  public static Place findById(int id, int type){
    return find(type, getRelationNameByType(type) + ".id = " + id);
  }
  
  public static Place findByName(String name, int type){
    return find(type, getRelationNameByType(type) + ".name like '" + name + "'");
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
    System.out.println("NUMBER OF SIGHTINGS IN CHICAGO: " + Place.findByName("Chicago", Place.CITY).sightingsCount());
    System.out.println("NUMBER OF SIGHTINGS IN Cook: " + Place.findByName("Cook", Place.COUNTY).sightingsCount());
    System.out.println("NUMBER OF SIGHTINGS IN ILLINOIS: " + Place.findByName("Illinois", Place.STATE).sightingsCount());
  }

  public Iterator<Sighting> activeSightingIterator(){
    return sightingList.iterator();
  }
}

