import processing.core.*; 
import processing.xml.*; 

import processing.opengl.*; 
import com.modestmaps.*; 
import com.modestmaps.core.*; 
import com.modestmaps.geo.*; 
import com.modestmaps.providers.*; 
import java.awt.Graphics2D; 
import java.awt.Shape; 
import java.util.jar.*; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class cs424p3 extends PApplet {

static class Animator {
  static List<Animator> allAnimators;  /* looks like we can use generics after al */
  
  final float attraction = 0.2f;
  final float reached_threshold = 10e-3f;
  
  float value;
  float target;
  float oldtarget;
  boolean targeting;
  float velocity;
  
  Animator()
  {
    if (allAnimators == null) allAnimators = new ArrayList();
    allAnimators.add(this);
    targeting = false;
  }
  
  Animator(float value_)
  {
    this();
    value = value_;
  }
  
  public void close()
  {
    allAnimators.remove(this);
  }
  
  public void set(float value_)
  {
    value = value_;
  }
  
  public void target(float target_)
  {
    if (target_ != target) oldtarget = target;
    target = target_;
    targeting = (target != value);
  }
  
  public void update()
  {
    if (!targeting) return;
    
    float a = attraction * (target - value);
    velocity = (velocity + a) / 2;
    value += velocity;
    
    if (abs(target - value) < reached_threshold) {
      value = target;
      targeting = false;
      velocity = 0;
    }
  }
  
  public static void updateAll()
  {
    if (allAnimators != null) for (Animator animator : allAnimators) animator.update();
  }
}


int checkboxColor = 255;

class Checkbox extends View {
  boolean value;
  int ckbColor = -1;
  String imageName = "";
  PImage icon;
  String title;
  
  Checkbox(float x_, float y_, float w_, float h_,String text_, String image_)
  {
    super(x_, y_, w_, h_);
    value = false;
    imageName = image_;
    icon = loadImage(imageName);
    title = text_;
  }
  
  Checkbox(float x_, float y_, float w_, float h_, String text_,int color_)
  {
    super(x_, y_, w_, h_);
    value = false;
    ckbColor = color_;
    title = text_;
  }
  
  Checkbox(float x_, float y_, float w_, float h_, String text_)
  {
    super(x_, y_, w_, h_);
    value = false;
    title = text_;
  }
  
  public void drawContent()
  {
    strokeWeight(1);

    if (value){
      stroke((ckbColor== -1)?checkboxColor:ckbColor);
      noFill();
      rect(0, 0, w, h);
      fill((ckbColor== -1)?checkboxColor:ckbColor);
      rect(2, 2, w-4, h-4);
    }
    else{
      stroke((ckbColor== -1)?checkboxColor:ckbColor);
      noFill();
      rect(0, 0, w, h);
    }
   fill(textColor);
   textFont(font,normalFontSize);
   textAlign(LEFT,TOP);
   if (imageName.length() > 0){
     text(title, w + w + 10, 0);
     imageMode(CORNERS);
     image(icon, w + 5, 0,w+5+w,h);
     
   }
   else{
     text(title, w + 5, 0);
   }
    
  }
  
  public boolean contentPressed(float lx, float ly)
  {
    value = !value;
    return true;
  }
  
  public void setValue(Boolean _value){
    value = _value;
  }
}


public abstract class DataMapper {
  public static SQLite db;
  public static PApplet parent;
  public static void connect(PApplet parent){
    DataMapper.parent = parent;
    db = new SQLite(parent, "ufo.db");
    db.connect();
  }
}

class HBar extends View {
  float level;
  
  HBar(float x_, float y_, float w_, float h_)
  {
    super(x_, y_, w_, h_);
    level = 0.5f;
  }
  
  public void drawContent()
  {
    noFill();
    stroke(0);
    rect(0, 0, w, h);
    fill(128);
    rect(0, 0, w*level, h);
  }
  
  public boolean contentPressed(float lx, float ly)
  {
    level = lx/w;
    return true;
  }
  
  public boolean contentDragged(float lx, float ly)
  {
    level = lx/w;
    return true;
  }
}


int spaceBtwLines = 13;
int markSize = 10;
int sliderColor = 150;
int activeSliderColor = 255;

class HSlider extends View {
  private float value;
  private int index_1;
  private int index_2;
  private String minLabel;
  private String maxLabel;
  String[] labels;
  private String title;
  
  private boolean movingMin;
  private boolean movingMax;
  private int charactersToShow;

  
  HSlider(float x_, float y_, float w_, float h_,String[] _labels,String _title,int _chr)
  {
    super(x_, y_, (PApplet.parseInt(textWidth(_title))  + (_labels.length*spaceBtwLines)), (textAscent() + textDescent() + markSize+2));
    index_1 = 0;
    index_2 = _labels.length-1;
    labels = _labels;
    title = _title;
    charactersToShow = _chr;
  }
  
  HSlider(float x_, float y_, float w_, float h_,String[] _labels,int _chr)
  {
    super(x_, y_, (_labels.length*spaceBtwLines), (textAscent() + textDescent() + markSize+2));
    index_1 = 0;
    index_2 = _labels.length-1;
    labels = _labels;
    title = "";
    charactersToShow = _chr;
  }
  
  public void drawContent()
  {
   
      textAlign(LEFT,CENTER);
      textFont(font,normalFontSize);
      fill(textColor);
      text(title, 0, 0);
    
      textFont(font,smallFontSize);
      for (int i = 0; i < labels.length; i++) {
        float x = PApplet.parseInt(textWidth(title)) + i*spaceBtwLines;
        if (i == index_1) {
          strokeWeight(2);
          stroke(activeSliderColor);
          line(x, 0, x, markSize);
          textAlign(CENTER, TOP);
          text(labels[index_1].substring(0,charactersToShow), x, markSize+2);
        } 
       else if (i == index_2) {
          strokeWeight(2);
          stroke(activeSliderColor);
          line(x, 0, x, markSize);
          textAlign(CENTER, TOP);
          text(labels[index_2].substring(0,charactersToShow), x, markSize+2);
        } 
        else {
          strokeWeight(1);
          stroke(sliderColor);
          line(x, 0, x,markSize-4);
        }
      }
  }
  
  public boolean contentPressed(float lx, float ly)
  {
    
    value = constrain(PApplet.parseInt((lx - textWidth(title)) / spaceBtwLines),0,labels.length-1);
    if (value == index_1)
    {
       movingMin = true;
       movingMax = false;
    }
    else if (value == index_2){
      movingMax = true;
      movingMin = false;
    }
    else {
      movingMin = false;
      movingMax = false;
    }
    
    return true;
  }
  
  public boolean contentDragged(float lx, float ly)
  {
    value = constrain(PApplet.parseInt((lx - textWidth(title)) / spaceBtwLines),0,labels.length-1);
    if (movingMin){        
        index_1 = PApplet.parseInt(value);
    }else if (movingMax){
        index_2 = PApplet.parseInt(value);
    }
    return true;
  }
  
  public int minIndex(){
    if (index_1 > index_2){
        return index_2;
    }
    return index_1;
  }
  
  public int maxIndex(){
    if (index_1 > index_2){
        return index_1;
    }
    return index_2;
  }
}








class MapView extends View {
  InteractiveMap mmap;
  int zoomValue = 4;
  int minZoom = 4;
  int maxZoom = 12;
  int minPointSize= 5;
  int maxPointSize = 20;
  int minIconSize= 8;
  int maxIconSize = 25;
  int minDistSize = 1;
  int maxDistSize = 100;
  
  MapView(float x_, float y_, float w_, float h_)
  {
    super(x_, y_, w_, h_);
    mmap = new InteractiveMap(papplet, new Microsoft.HybridProvider(), w, h);
    mmap.setCenterZoom(new Location(41.881944f,-87.627778f), zoomValue);     
  }
  
  public void drawContent()
  {
    imageMode(CORNER);  // modestmaps needs this - I sent a patch, but who knows when it'll be committed
    mmap.draw();
    smooth();

    drawSightings();
    drawAirports();
  }

  public boolean contentMouseWheel(float lx, float ly, int delta)
  {
    float sc = 1.0f;
    if (delta < 0) {
      sc = 1.05f;
    }
    else if (delta > 0) {
      sc = 1.0f/1.05f;
    }
    float mx = lx - w/2;
    float my = ly - h/2;
    mmap.tx -= mx/mmap.sc;
    mmap.ty -= my/mmap.sc;
    mmap.sc *= sc;
    mmap.tx += mx/mmap.sc;
    mmap.ty += my/mmap.sc;

    return true;
  }

  public boolean mouseDragged(float px, float py)
  {
    mmap.mouseDragged();
    return true;
  }
  
  public void drawAirports(){
       noStroke();
       fill(airportAreaColor,40);
       Point2f p2 = mmap.locationPoint(new Location(41.97f, -87.905f));
       ellipse(p2.x,p2.y,map(zoomValue,minZoom,maxZoom,minDistSize,maxDistSize),map(zoomValue,minZoom,maxZoom,minDistSize,maxDistSize));
       image(airplaneImage,p2.x,p2.y,map(zoomValue,minZoom,maxZoom,minIconSize,maxIconSize),map(zoomValue,minZoom,maxZoom,minIconSize,maxIconSize));
  }
  
  public void drawSightings(){
   
   imageMode(CENTER);
   for (Iterator<Sighting> sightingList = sightings.activeSightingIterator(); sightingList.hasNext();) {
      Sighting newSighting = sightingList.next();
      Point2f p = mmap.locationPoint(((Place)(newSighting.location)).loc);
      image(((SightingType)newSighting.type).icon,p.x,p.y,map(zoomValue,minZoom,maxZoom,minPointSize,maxPointSize),map(zoomValue,minZoom,maxZoom,minPointSize,maxPointSize));
   }
  }
}


class SettingsView extends View {
  HSlider yearSlider;
  HSlider monthSlider;
  HSlider timeSlider;
  Checkbox yearCheckbox, monthCheckbox, timeCheckbox;
  Checkbox UFOType1,UFOType2,UFOType3,UFOType4,UFOType5,UFOType6,UFOType7,UFOType8;
  Checkbox showAirport;
  
  int CHECKBOX_X = 450;
  int CHECKBOX_Y = 10;
  int CHECKBOX_W = 300;
  
  boolean showView;
  float heightView ;
  String title;
  
  SettingsView(float x_, float y_, float w_, float h_)
  {
    super(x_, y_, w_, h_);
    heightView = h;
    textFont(font,normalFontSize);
    
    monthCheckbox = new Checkbox(10,40,12,12,"Month:");
    this.subviews.add(monthCheckbox);
    
    timeCheckbox = new Checkbox(10,70,12,12,"Time:");
    this.subviews.add(timeCheckbox);
    
    yearSlider = new HSlider(75,10,0,0,yearLabels,"",3);
    this.subviews.add(yearSlider);

    monthSlider = new HSlider(75,40,0,0,monthLabels,"",2);
    this.subviews.add(monthSlider);

    timeSlider = new HSlider(75,70,0,0,timeLabels,"",2);
    this.subviews.add(timeSlider);
    
    UFOType1 = new Checkbox(CHECKBOX_X + 10 ,CHECKBOX_Y + 9 ,12,12,UFOTypeLabels[0],UFOImages[0]);
    this.subviews.add(UFOType1);
    
    UFOType2 = new Checkbox(CHECKBOX_X + 10 ,CHECKBOX_Y + 29,12,12,UFOTypeLabels[1],UFOImages[1]);
    this.subviews.add(UFOType2);
    
    UFOType3 = new Checkbox(CHECKBOX_X + 10 ,CHECKBOX_Y + 49,12,12,UFOTypeLabels[2],UFOImages[2]);
    this.subviews.add(UFOType3);
    
    UFOType4 = new Checkbox(CHECKBOX_X + 10 ,CHECKBOX_Y + 69,12,12,UFOTypeLabels[3],UFOImages[3]);
    this.subviews.add(UFOType4);
    
    UFOType5 = new Checkbox(CHECKBOX_X + 170 ,CHECKBOX_Y + 9,12,12,UFOTypeLabels[4],UFOImages[4]);
    this.subviews.add(UFOType5);
    
    UFOType6 = new Checkbox(CHECKBOX_X + 170 ,CHECKBOX_Y + 29,12,12,UFOTypeLabels[5],UFOImages[5]);
    this.subviews.add(UFOType6);
    
    UFOType7 = new Checkbox(CHECKBOX_X + 170,CHECKBOX_Y + 49,12,12,UFOTypeLabels[6],UFOImages[6]);
    this.subviews.add(UFOType7);
    
    showAirport = new Checkbox(800,10,12,12,"Show airports","plane.png");
    this.subviews.add(showAirport);
    
    showView = false;
  }
  
   public void drawContent()
  {
    fill(viewBackgroundColor,220);
    stroke(viewBackgroundColor,220);
    rect(0,0, w, h-25);
    rect(0,h-25,95,25);
    textFont(font,normalFontSize);
    textAlign(LEFT,TOP);
    fill(textColor);
    text((showView)?"Hide Settings":"Show Settings",5,h-20);
  
    text("Year: ",10,10);
    textAlign(LEFT,CENTER);
    title = " Type of UFO ";
    text(title,CHECKBOX_X,CHECKBOX_Y);
    stroke(textColor);
    line(CHECKBOX_X + textWidth(title)+5,CHECKBOX_Y,CHECKBOX_X+CHECKBOX_W,CHECKBOX_Y);
    line(CHECKBOX_X,CHECKBOX_Y,CHECKBOX_X,h-30);
    line(CHECKBOX_X,h-30,CHECKBOX_X+CHECKBOX_W,h-30);
    line(CHECKBOX_X+CHECKBOX_W,CHECKBOX_Y,CHECKBOX_X+CHECKBOX_W,h-30);
    
    textAlign(LEFT,TOP);
    title = "MAP " + ((yearSlider.minIndex()!=yearSlider.maxIndex())?("From: "+yearLabelsToPrint[yearSlider.minIndex()] + " To: " + yearLabelsToPrint[yearSlider.maxIndex()]):("Year: "+yearLabelsToPrint[yearSlider.minIndex()]));
    title = title + ((monthCheckbox.value)?((monthSlider.minIndex()!=monthSlider.maxIndex())?(" - " + monthLabelsToPrint[monthSlider.minIndex()] + " to " + monthLabelsToPrint[monthSlider.maxIndex()]):(" - " +  monthLabelsToPrint[monthSlider.minIndex()])):(""));
    title = title +  ((timeCheckbox.value)?((timeSlider.minIndex()!=timeSlider.maxIndex())?(" - " + timeLabels[timeSlider.minIndex()] + ":00 to " + timeLabels[timeSlider.maxIndex()] +":00"):(" - " + timeLabels[timeSlider.minIndex()])+":00"):(""));   
    text(title,(width-textWidth(title))/2,h-20);
 
       
  }
  
  public boolean contentPressed(float lx, float ly)
  {
    if(lx > 0 && lx <95 && ly>h-25 && ly < h){
        settingsAnimator.target((showView)?(-heightView+25):0);
        showView = !showView;    
    }
        
    return true;
  }
}


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
    this.location = location;
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
  int colr;
  String name;
  public SQLite db;

  SightingType(int id, String name, PImage icon, int colr) {
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
    String relation_name = getRelationNameByType(type);
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
  public Iterator<Sighting> activeSightingIterator();
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

  public Iterator<Sighting> activeSightingIterator(){
    return sightingList.iterator();
  }
}






Graphics2D g2;
Shape[] clipStack;
int clipIdx;

public void setupG2D()
{
  g2 = ((PGraphicsJava2D)g).g2;
  clipStack = new Shape[32];
  clipIdx = 0;
}

/* I can't believe this is not part of the Processing API! */
public void clipRect(int x, int y, int w, int h)
{
  g2.clipRect(x, y, w, h);
}

public void clipRect(float x, float y, float w, float h)
{
  g2.clipRect((int)x, (int)y, (int)w, (int)h);
}

public void noClip()
{
  g2.setClip(null);
}

public void pushClip()
{
  clipStack[clipIdx++] = g2.getClip();
}

public void popClip()
{
  g2.setClip(clipStack[--clipIdx]);
  clipStack[clipIdx] = null;
}

public String[] listDataSubdir(String subdir)
{
  String[] items = null;
  /* dataPath does not work for application, either. it's only useful in the IDE */
/*  if (sketchPath != null) {
    println(dataPath(subdir));
    File dir = new File(dataPath(subdir));
    items = dir.list();
    println(items);
  } else */
  
  ClassLoader cl = getClass().getClassLoader();
  URL url = cl.getResource("META-INF/MANIFEST.MF");  /* just a random file that's known to exist */
  if (url == null) {  /* running in IDE */
    File dir = new File(dataPath(subdir));
    items = dir.list();
  } else try {  /* applet OR application */
    JarURLConnection conn = (JarURLConnection)url.openConnection();
    JarFile jar = conn.getJarFile();
    Enumeration e = jar.entries();
    String re = "data/" + subdir + "/(.*)";
    /* note that jars don't have directory entries, or at least Processing's don't */
    Set<String> itemSet = new LinkedHashSet<String>();
    while (e.hasMoreElements()) {
      JarEntry entry = (JarEntry)e.nextElement();
      String[] groups = match(entry.getName(), re);
      if (groups == null) continue;
      String[] comps = split(groups[1], "/");
      itemSet.add(comps[0]);
    }
    /*Iterator it = itemSet.iterator();
    while (it.hasNext()) {
      println(it.next());
    }*/
    items = (String[])itemSet.toArray(new String[0]);
  } catch (IOException e) {
    println(e);
  }
  return items;
}

public boolean dataFileExists(String path)
{
  InputStream is = createInput(path);
  if (is == null) return false;
  else {
    try { is.close(); }
    catch (IOException e) {}
    return true;
  }
}


class View {
  float x, y, w, h;
  ArrayList subviews;
  
  View(float x_, float y_, float w_, float h_)
  {
    x = x_;
    y = y_;
    w = w_;
    h = h_;
    subviews = new ArrayList();
  }
  
  public void draw()
  {
    pushMatrix();
    translate(x, y);
    // draw out content, then our subviews on top
    drawContent();
    for (int i = 0; i < subviews.size(); i++) {
      View v = (View)subviews.get(i);
      v.draw();
    }
    popMatrix();
  }
  
  public void drawContent()
  {
    // override this
    // when this is called, the coordinate system is local to the view,
    // i.e. 0,0 is the top left corner of this view
  }
  
  public boolean contentPressed(float lx, float ly)
  {
    // override this
    // lx, ly are in the local coordinate system of the view,
    // i.e. 0,0 is the top left corner of this view
    // return false if the click is to "pass through" this view
    return true;
  }
  
  public boolean contentDragged(float lx, float ly)
  {
    return true;
  }
  
  public boolean contentClicked(float lx, float ly)
  {
    return true;
  }
  
  public boolean contentMouseWheel(float lx, float ly, int delta)
  {
    return false;
  }

  public boolean ptInRect(float px, float py, float rx, float ry, float rw, float rh)
  {
    return px >= rx && px <= rx+rw && py >= ry && py <= ry+rh;
  }

  public boolean mousePressed(float px, float py)
  {
    if (!ptInRect(px, py, x, y, w, h)) return false;
    float lx = px - x;
    float ly = py - y;
    // check our subviews first
    for (int i = subviews.size()-1; i >= 0; i--) {
      View v = (View)subviews.get(i);
      if (v.mousePressed(lx, ly)) return true;
    }
    return contentPressed(lx, ly);
  }

  public boolean mouseDragged(float px, float py)
  {
    if (!ptInRect(px, py, x, y, w, h)) return false;
    float lx = px - x;
    float ly = py - y;
    // check our subviews first
    for (int i = subviews.size()-1; i >= 0; i--) {
      View v = (View)subviews.get(i);
      if (v.mouseDragged(lx, ly)) return true;
    }
    return contentDragged(lx, ly);
  }

  public boolean mouseClicked(float px, float py)
  {
    if (!ptInRect(px, py, x, y, w, h)) return false;
    float lx = px - x;
    float ly = py - y;
    // check our subviews first
    for (int i = subviews.size()-1; i >= 0; i--) {
      View v = (View)subviews.get(i);
      if (v.mouseClicked(lx, ly)) return true;
    }
    return contentClicked(lx, ly);
  }
  
  public boolean mouseWheel(float px, float py, int delta)
  {
    if (!ptInRect(px, py, x, y, w, h)) return false;
    float lx = px - x;
    float ly = py - y;
    // check our subviews first
    for (int i = subviews.size()-1; i >= 0; i--) {
      View v = (View)subviews.get(i);
      if (v.mouseWheel(lx, ly, delta)) return true;
    }
    return contentMouseWheel(lx, ly, delta);
  }
}


View rootView;

PFont font;

HBar hbar;
HBar hbar2;
Animator settingsAnimator;

PApplet papplet;
MapView mapv;
SettingsView settingsView;

int backgroundColor = 0;
int textColor = 255;
int viewBackgroundColor = 0xff2D2A36;
int airportAreaColor = 0xffFFA500;
int[] UFOColors = {0xff345677,0xff568999,0xff456789,0xff908766,0xff229988,0xff771122,0xff121211};

int normalFontSize = 13;
int smallFontSize = 9 ;
String[] monthLabelsToPrint = {"January","February","March","April","May","June","July","August","September","October","November","December"};
String[] monthLabels = {"01","02","03","04","05","06","07","08","09","10","11","12"};
String[] yearLabels = {"'00","'01","'02","'03","'04","'05","'06","'07","'08","'09","'10","'11"};
String[] yearLabelsToPrint = {"2000","2001","2002","2003","2004","2005","2006","2007","2008","2009","2010","2011"};
String[] timeLabels = {"00","01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23"};
String[] UFOTypeLabels = {"UFOType 1","UFOType 2","UFOType 3","UFOType 4","UFOType 5","UFOType 6","UFOType 7"};
String[] UFOImages = {"blue.png","green.png","gray.png","orange.png","purple.png","red.png","yellow.png"};

PImage airplaneImage;

SightingTable sightings;
List<Place> places;
List<SightingType> sightingTypes;

public void setup()
{
  size(1000, 700);
  setupG2D();
  DataMapper.connect(this); 
  papplet = this;
  
  smooth();
  
  sightings = new DummySightingTable();
  
  rootView = new View(0, 0, width, height);
  font = loadFont("Helvetica-48.vlw");
  
  airplaneImage = loadImage("plane.png");
  
  mapv = new MapView(0,0,width,height);
  rootView.subviews.add(mapv);
  
  
  settingsView = new SettingsView(0,-100,width,125);
  rootView.subviews.add(settingsView);

  settingsAnimator = new Animator(settingsView.y);
  
  // I want to add true multitouch support, but let's have this as a stopgap for now
  addMouseWheelListener(new java.awt.event.MouseWheelListener() {
    public void mouseWheelMoved(java.awt.event.MouseWheelEvent evt) {
      rootView.mouseWheel(mouseX, mouseY, evt.getWheelRotation());
    }
  });
}

public void draw()
{
  background(backgroundColor); 
  Animator.updateAll();
  
  settingsView.y = settingsAnimator.value;
  
  rootView.draw();
}

public void mousePressed()
{
  rootView.mousePressed(mouseX, mouseY);
}

public void mouseDragged()
{
  rootView.mouseDragged(mouseX, mouseY);
}

public void mouseClicked()
{
  rootView.mouseClicked(mouseX, mouseY);
}


    static public void main(String args[]) {
        PApplet.main(new String[] { "--bgcolor=#ECE9D8", "cs424p3" });
    }
}
