import org.khelekore.prtree.*;

View rootView;

PFont font;

HBar hbar;
HBar hbar2;
Animator settingsAnimator;
Animator detailsAnimator;

PApplet papplet;
MapView mapv;
SettingsView settingsView;
SightingDetailsView sightingDetailsView;
DateFormat dateTimeFormat= new SimpleDateFormat("EEEE, MMMM dd, yyyy HH:mm");
DateFormat dateFormat= new SimpleDateFormat("EEEE, MMMM dd, yyyy");
DateFormat shortDateFormat= new SimpleDateFormat("MM/dd/yyyy HH:mm");
DateFormat dbDateFormat= new SimpleDateFormat("yyyy.MM.dd HH:mm:ss");

color backgroundColor = 0;
color textColor = 255;
color boldTextColor = #FFFF00;
color viewBackgroundColor = #2D2A36;
color airportAreaColor = #FFA500;
color infoBoxBackground = #000000;
color[] UFOColors = {#000000,#ffffff,#555555,#333333,#444444,#555555,#666666};

int normalFontSize = 13;
int smallFontSize = 9 ;
String[] monthLabelsToPrint = {"January","February","March","April","May","June","July","August","September","October","November","December"};
String[] monthLabels = {"01","02","03","04","05","06","07","08","09","10","11","12"};
String[] yearLabels = {"'00","'01","'02","'03","'04","'05","'06","'07","'08","'09","'10","'11"};
String[] yearLabelsToPrint = {"2000","2001","2002","2003","2004","2005","2006","2007","2008","2009","2010","2011"};
String[] timeLabels = {"00","01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23"};
String[] UFOTypeLabels = {"UFOType 1","UFOType 2","UFOType 3","UFOType 4","UFOType 5","UFOType 6","UFOType 7"};
String[] UFOImages = {"blue.png","green.png","star.png","orange.png","purple.png","red.png","yellow.png"};

PImage airplaneImage;

SightingTable sightings;
List<Place> places;
PRTree<Place> placeTree;
Map<Integer,SightingType> sightingTypeMap;

Sighting clickedSighting;
Boolean showAirports=false;
String yearMin,yearMax,monthMin,monthMax,timeMin,timeMax;
Boolean btwMonths = false;
Boolean btwTime = false;
Boolean byType = false;
Boolean isDragging = false;

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
  
  loadSightingTypes();
  loadCities();
  loadAirports();
  
  sightings = new DummySightingTable();
  
  /* setup UI */
  rootView = new View(0, 0, width, height);
  font = loadFont("Helvetica-48.vlw");
  
  airplaneImage = loadImage("plane.png");
  
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
  Boolean tmpByType = false;
  for (SightingType st : sightingTypeMap.values()) {
   Checkbox cb = settingsView.typeCheckboxMap.get(st);
   tmpByType = (tmpByType || cb.value);
  }
  
  if (btwTime != settingsView.timeCheckbox.value || btwMonths != settingsView.monthCheckbox.value){
      btwTime = settingsView.timeCheckbox.value;
      btwMonths = settingsView.monthCheckbox.value;
      byType = tmpByType;
      loadCities();
      detailsAnimator.target(height);  
  }
  

  
  
  rootView.mouseClicked(mouseX, mouseY);
}

void mouseReleased(){
  if (isDragging){
    if (yearMin != yearLabelsToPrint[settingsView.yearSlider.minIndex()] || yearMax != yearLabelsToPrint[settingsView.yearSlider.maxIndex()]){
      yearMin =  yearLabelsToPrint[settingsView.yearSlider.minIndex()] ;
      yearMax = yearLabelsToPrint[settingsView.yearSlider.maxIndex()];
      loadCities();
      detailsAnimator.target(height);
    }
    else if (monthMin != monthLabelsToPrint[settingsView.monthSlider.minIndex()] || monthMax != monthLabelsToPrint[settingsView.monthSlider.maxIndex()]){
      monthMin =  monthLabelsToPrint[settingsView.monthSlider.minIndex()];
      monthMax = monthLabelsToPrint[settingsView.monthSlider.maxIndex()];
      loadCities();
      detailsAnimator.target(height);
    }
    else  if (timeMin != timeLabels[settingsView.timeSlider.minIndex()]+":00" || timeMax != timeLabels[settingsView.timeSlider.maxIndex()]+":00"){
      timeMin =  timeLabels[settingsView.timeSlider.minIndex()]+":00"; 
      timeMax = timeLabels[settingsView.timeSlider.maxIndex()]+":00";
      loadCities();
      detailsAnimator.target(height);
    }
    
  }
  isDragging = false;
}

