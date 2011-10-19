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

int normalFontSize = 13;
int smallFontSize = 9 ;
String[] monthLabelsToPrint = {"January","February","March","April","May","June","July","August","September","October","November","December"};
String[] monthLabels = {"01","02","03","04","05","06","07","08","09","10","11","12"};
String[] yearLabels = {"'00","'01","'02","'03","'04","'05","'06","'07","'08","'09","'10","'11"};
String[] yearLabelsToPrint = {"2000","2001","2002","2003","2004","2005","2006","2007","2008","2009","2010","2011"};
String[] timeLabels = {"00","01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23"};

PImage airplaneImage;

SightingTable sightings;

void setup()
{
  size(1000, 700);
  setupG2D();
  
  papplet = this;
  
  smooth();
  
  sightings = new DummySightingTable();
  
  rootView = new View(0, 0, width, height);
  font = loadFont("Helvetica-48.vlw");
  
  airplaneImage = loadImage("plane.png");
  
  /*
  hbar = new HBar(10,100,200,20);
  rootView.subviews.add(hbar);

  hbar2 = new HBar(10,200,200,20);
  rootView.subviews.add(hbar2);
  */
  
  mapv = new MapView(0,0,width,height);
  rootView.subviews.add(mapv);
  
  
  settingsView = new SettingsView(0,-100,width,125);
  rootView.subviews.add(settingsView);

  settingsAnimator = new Animator(settingsView.y);
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

