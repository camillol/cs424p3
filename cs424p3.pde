import org.khelekore.prtree.*;

View rootView;

PFont font;

HBar hbar;
HBar hbar2;
Animator settingsAnimator;
Animator detailsAnimator;

PApplet papplet;
MapView mapv;
GraphView graphView;
Button graphButton;
boolean graphOn;
SettingsView settingsView;
SightingDetailsView sightingDetailsView;

DateFormat dateTimeFormat= new SimpleDateFormat("EEEE, MMMM dd, yyyy HH:mm");
DateFormat dateFormat= new SimpleDateFormat("EEEE, MMMM dd, yyyy");
DateFormat shortDateFormat= new SimpleDateFormat("MM/dd/yyyy HH:mm");
DateFormat dbDateFormat= new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

color backgroundColor = 0;
color textColor = 255;
color boldTextColor = #FFFF00;
color viewBackgroundColor = #2D2A36;
color airportAreaColor = #FFA500;
color militaryBaseColor = #CC0000;
color weatherStationColor = #FFFF00;
color infoBoxBackground = #000000;
color[] UFOColors = {#000000,#ffffff,#555555,#333333,#444444,#555555,#666666};

int normalFontSize = 13;
int smallFontSize = 10 ;

String[] monthLabelsToPrint = {"January","February","March","April","May","June","July","August","September","October","November","December"};
String[] monthLabels = {"01","02","03","04","05","06","07","08","09","10","11","12"};
String[] yearLabels = {"'00","'01","'02","'03","'04","'05","'06","'07","'08","'09","'10","'11"};
String[] yearLabelsToPrint = {"2000","2001","2002","2003","2004","2005","2006","2007","2008","2009","2010","2011"};
String[] timeLabels = {"00","01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23"};
String[] UFOTypeLabels = {"UFOType 1","UFOType 2","UFOType 3","UFOType 4","UFOType 5","UFOType 6","UFOType 7"};
String[] UFOImages = {"blue.png","green.png","star.png","orange.png","purple.png","red.png","yellow.png"};

PImage airplaneImage;
PImage militaryBaseImage;
PImage weatherStationImage;

SightingTable sightings;
Map<Integer,Place> placeMap;
Map<Integer,Place> airportsMap;
Map<Integer,Place> militaryBaseMap;
Map<Integer,Place> weatherStationMap;
PRTree<Place> placeTree;
PRTree<Place> airportsTree;
PRTree<Place> militaryBaseTree;
PRTree<Place> weatherStationTree;
Map<Integer,SightingType> sightingTypeMap;

Sighting clickedSighting;
Boolean showAirports=false;
Boolean showMilitaryBases = false;
Boolean showWeatherStation = false;
Boolean btwMonths = false;
Boolean btwTime = false;
String byType = "";
Boolean isDragging = false;

SightingsFilter activeFilter;

import de.bezier.data.sql.*;

SQLite db;

void setup()
{
  size(1000, 700, OPENGL);  // OPENGL seems to be slower than the default
//  setupG2D();
  
  papplet = this;
  
  smooth();
//  noSmooth();
  
  /* load data */
  db = new SQLite( this, "ufo.db" );
  if (!db.connect()) println("DB connection failed!");
  db.execute("PRAGMA cache_size=100000;");
  
  activeFilter = new SightingsFilter();

  loadSightingTypes();
  loadCities();
  loadAirports();
  loadMilitaryBases();
  loadWeatherStations();
  reloadCitySightingCounts();
  
  sightings = new DummySightingTable();
  
  /* setup UI */
  rootView = new View(0, 0, width, height);
  font = loadFont("Courier-20.vlw");
  
  airplaneImage = loadImage("plane.png");
  militaryBaseImage = loadImage("irkickflash2.png");
  weatherStationImage = loadImage("irkickflash1.png");
  
  mapv = new MapView(0,0,width,height);
  rootView.subviews.add(mapv);
  
  settingsView = new SettingsView(0,-100,width,125);
  rootView.subviews.add(settingsView);
  
  sightingDetailsView = new SightingDetailsView(0,height,width,200);
  rootView.subviews.add(sightingDetailsView);

  settingsAnimator = new Animator(settingsView.y);
  detailsAnimator = new Animator(sightingDetailsView.y);
  
  // I want to add true multitouch support, but let's have this as a stopgap for now
  addMouseWheelListener(new java.awt.event.MouseWheelListener() {
    public void mouseWheelMoved(java.awt.event.MouseWheelEvent evt) {
      rootView.mouseWheel(mouseX, mouseY, evt.getWheelRotation());
    }
  });

  graphView = new GraphView(10, 10, width-20, height-20);
  
  graphButton = new Button(width-80, 0, 80, 20, "Graph");
  rootView.subviews.add(graphButton);
  graphOn = false;
}

void buttonClicked(Button button)
{
  if (button == graphButton) {
    graphOn = !graphOn;
    if (graphOn) rootView.subviews.add(graphView);
    else rootView.subviews.remove(graphView);
  }
}

void draw()
{
  background(backgroundColor); 
  Animator.updateAll();
  
  settingsView.y = settingsAnimator.value;
  sightingDetailsView.y = detailsAnimator.value;
       
  rootView.draw();
}

void mousePressed()
{
  rootView.mousePressed(mouseX, mouseY);
}

void mouseDragged()
{
  isDragging = true;
  rootView.mouseDragged(mouseX, mouseY);
}

void mouseClicked()
{  
  showAirports = settingsView.showAirport.value;
  showMilitaryBases = settingsView.showMilitaryBases.value;
  showWeatherStation = settingsView.showWeatherStation.value;

  String tmpByType = "";
  int i = 0;
  for (SightingType st : sightingTypeMap.values()) {
   Checkbox cb = settingsView.typeCheckboxMap.get(st);
   if (cb.value){
       i++;
       tmpByType = ((tmpByType.length() > 0)?(tmpByType+", "):tmpByType) + " " + st.id ;
    }
  }
  tmpByType = (i == settingsView.typeCheckboxMap.size())?(tmpByType = ""):((i==0)?("-1"):tmpByType);
 
  if (btwTime != settingsView.timeCheckbox.value || btwMonths != settingsView.monthCheckbox.value || !byType.equals(tmpByType)){
    btwTime = settingsView.timeCheckbox.value;
    btwMonths = settingsView.monthCheckbox.value;
    byType = tmpByType;
    updateFilter();
    println("updating filters...");
  }

  rootView.mouseClicked(mouseX, mouseY);
}

void updateFilter()
{
  SightingsFilter newFilter = new SightingsFilter();
  newFilter.viewMinYear = 2000 + settingsView.yearSlider.minIndex();
  newFilter.viewMaxYear = 2000 + settingsView.yearSlider.maxIndex();
  if (btwMonths) {
    newFilter.viewMinMonth =  1 + settingsView.monthSlider.minIndex();
    newFilter.viewMaxMonth =  1 + settingsView.monthSlider.maxIndex();
  }
  if (btwTime) {
    newFilter.viewMinHour =  settingsView.timeSlider.minIndex();
    newFilter.viewMaxHour =  settingsView.timeSlider.maxIndex();
  }
  newFilter.viewUFOType = byType;
  
  if (!newFilter.equals(activeFilter)) {
    println("updating values...");
    activeFilter = newFilter;
    reloadCitySightingCounts();
    mapv.rebuildOverlay();
    detailsAnimator.target(height);
  }
}

void mouseReleased(){
  if (isDragging) {
    updateFilter();
  }
  isDragging = false;
}

float lastTime;

float stopWatch()
{
  float x = lastTime;
  lastTime = millis();
  return lastTime - x;
}

