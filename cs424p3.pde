View rootView;

PFont font;

HBar hbar;
HBar hbar2;
Animator settingsAnimator;

PApplet papplet;
MapView mapv;
SettingsView settingsView;

color backgroundColor = 0;
color textColor = 255;
color viewBackgroundColor = #2D2A36;
color airportAreaColor = #FFA500;
color[] UFOColors = {#345677,#568999,#456789,#908766,#229988,#771122,#121211};

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

void setup()
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

void draw()
{
  background(backgroundColor); 
  Animator.updateAll();
  
  settingsView.y = settingsAnimator.value;
  
  rootView.draw();
}

void mousePressed()
{
  rootView.mousePressed(mouseX, mouseY);
}

void mouseDragged()
{
  rootView.mouseDragged(mouseX, mouseY);
}

void mouseClicked()
{
  rootView.mouseClicked(mouseX, mouseY);
}

