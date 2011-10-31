import org.khelekore.prtree.*;

View rootView;

PFont font;
  
HBar hbar;
HBar hbar2;
Animator settingsAnimator;
Animator detailsAnimator;

PApplet papplet;
MapView mapv;
GraphContainer graphContainer;
GraphView graphView;
Button graphButton;
ListBox graphModeList;
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
int largeFontSize = 15;

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

Map<Integer,Place> cityMap;
Map<Integer,Place> airportMap;
Map<Integer,Place> militaryBaseMap;
Map<Integer,Place> weatherStationMap;
Map<Integer,State> stateMap;
PRTree<Place> cityTree;
PRTree<Place> airportTree;
PRTree<Place> militaryBaseTree;
PRTree<Place> weatherStationTree;

Map<Integer,SightingType> sightingTypeMap;
Map<SightingType, Checkbox> typeCheckboxMap;

Sighting clickedSighting;
Boolean showAirports=false;
Boolean showMilitaryBases = false;
Boolean showWeatherStation = false;
Boolean showByStates = true;
Boolean btwMonths = false;
Boolean btwTime = false;
String byType = "";
Boolean isDragging = false;


SightingsFilter activeFilter;

DataSource data;
int playYear;
int minYearIndex;
int maxYearIndex;
Boolean startedPlaying = false;
int startingTime = 0;

void setup()
{
  
  
  size(1000, 700);  // OPENGL seems to be slower than the default
//  setupG2D();
  
  papplet = this;
  
  smooth();

  /* load data */
  data = new SQLiteDataSource();
  
  data.loadSightingTypes();
  activeFilter = new SightingsFilter();
  data.loadStates();
  data.loadCities();
  data.loadAirports();
  data.loadMilitaryBases();
  data.loadWeatherStations();
  data.reloadCitySightingCounts();
  updateStateSightingCounts();
  
  buildPlaceTree();
  
  /* setup UI */
  rootView = new View(0, 0, width, height);
  font = loadFont("Courier-20.vlw");
  
  airplaneImage = loadImage("plane.png");
  militaryBaseImage = loadImage("irkickflash2.png");
  weatherStationImage = loadImage("irkickflash1.png");
  
  mapv = new MapView(0,0,width,height);
  rootView.subviews.add(mapv);
  
  settingsView = new SettingsView(0,-80,width,125);
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

  graphContainer = new GraphContainer(0, 20, width, height-20); 
  
  graphButton = new Button(0, 0, width, 20, "Click here to show the Graphs");
  rootView.subviews.add(graphButton);
  graphOn = false;
}

void buttonClicked(Button button)
{
  if (button == graphButton) {
    graphOn = !graphOn;
    if (graphOn){ 
      rootView.subviews.add(graphContainer);
      button.label = "Click here to show the Map";
      graphContainer.updateValuesGraph();  
      
    }
    else{
      rootView.subviews.remove(graphContainer);
      button.label = "Click here to show the Graphs";
    }
  }
}

void buttonClicked(Checkbox button)
{
  if (graphOn)
     graphContainer.updateValuesMap(); 
     
  for (Entry<SightingType, Checkbox> entry : typeCheckboxMap.entrySet()) {
    entry.getKey().setActive(entry.getValue().value);
  }
  btwTime = settingsView.timeCheckbox.value;
  btwMonths = settingsView.monthCheckbox.value;
  
  updateFilter();
  
  if (showAirports != settingsView.showAirportCB.value || showMilitaryBases !=  settingsView.showMilitaryBasesCB.value 
      || showWeatherStation != settingsView.showWeatherStationCB.value || showByStates != settingsView.showByStatesCB.value){
    showAirports = settingsView.showAirportCB.value;
    showMilitaryBases = settingsView.showMilitaryBasesCB.value;
    showWeatherStation = settingsView.showWeatherStationCB.value;
    showByStates = settingsView.showByStatesCB.value;
    mapv.rebuildOverlay();
  }
}

void listClicked(ListBox lb, int index, Object item)
{
  if (lb == graphModeList) {
    graphView.setActiveMode((String)item);
  }
}

void draw()
{
  int seconds = (millis() - startingTime) / 1000;
  
  if (!settingsView.play.value){
    minYearIndex = settingsView.yearSlider.minIndex();
    maxYearIndex = settingsView.yearSlider.maxIndex();
  }
  
  background(backgroundColor); 
  Animator.updateAll();
  
  settingsView.y = settingsAnimator.value;
  sightingDetailsView.y = detailsAnimator.value;
       
  rootView.draw();

  if (settingsView.play.value){
      if (!startedPlaying){
          startedPlaying = true;
          maxYearIndex = minYearIndex;
      }
      else if (seconds % 30 == 2){  //Update the new year to query after few seconds.
          startingTime=millis();
          minYearIndex ++;
          maxYearIndex = minYearIndex;  
      }   
         
      updateFilter();
  }
  if (maxYearIndex == settingsView.yearSlider.maxIndex()+1){
      settingsView.play.value = false;
      settingsView.play.transitionValue = 0;
      startedPlaying = false;
      minYearIndex = settingsView.yearSlider.minIndex();
      maxYearIndex = settingsView.yearSlider.maxIndex();
      updateFilter();
  }  
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
  rootView.mouseClicked(mouseX, mouseY);
}

/* returns true if filter changed */
boolean updateFilter()
{
  SightingsFilter newFilter = new SightingsFilter();
  newFilter.viewMinYear = 2000 + minYearIndex;
  newFilter.viewMaxYear = 2000 + maxYearIndex;
  if (btwMonths) {
    newFilter.viewMinMonth =  1 + settingsView.monthSlider.minIndex();
    newFilter.viewMaxMonth =  1 + settingsView.monthSlider.maxIndex();
  }
  if (btwTime) {
    newFilter.viewMinHour =  settingsView.timeSlider.minIndex();
    newFilter.viewMaxHour =  settingsView.timeSlider.maxIndex();
  }
  
  Set<SightingType> activeTypes = new HashSet<SightingType>();
  for (SightingType type : sightingTypeMap.values()) {
    if (type.active) activeTypes.add(type);
  }
  newFilter.activeTypes = activeTypes;
  
  if (!newFilter.equals(activeFilter)) {
    println(activeFilter + " -> " + newFilter);
    boolean reload = !newFilter.equalsIgnoringTypes(activeFilter);
    activeFilter = newFilter;
    if (reload) {
      data.reloadCitySightingCounts();
      updateStateSightingCounts();
    } else {
      println("recomputing totals");
      updateCitySightingTotals();
      updateStateSightingTotals();
    }
    mapv.rebuildOverlay();
    detailsAnimator.target(height);
    return true;
  }
  else return false;
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

