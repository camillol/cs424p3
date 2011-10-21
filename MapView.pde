import processing.opengl.*;
import com.modestmaps.*;
import com.modestmaps.core.*;
import com.modestmaps.geo.*;
import com.modestmaps.providers.*;

class MapView extends View {
  InteractiveMap mmap;
  float zoomValue = 4;
  float minZoom = 4;
  float maxZoom = 12;
  int minPointSize= 7;
  int maxPointSize = 25;
  int minIconSize= 8;
  int maxIconSize = 25;
  int minDistSize = 1;
  int maxDistSize = 100;
  Sighting clickedSighting;
  
  MapView(float x_, float y_, float w_, float h_)
  {
    super(x_, y_, w_, h_);
    mmap = new InteractiveMap(papplet, new Microsoft.HybridProvider(), w, h);
   // mmap = new InteractiveMap(papplet, new Microsoft.AerialProvider());  
 /* String template = "http://{S}.mqcdn.com/tiles/1.0.0/osm/{Z}/{X}/{Y}.png";
  String[] subdomains = new String[] { "otile1", "otile2", "otile3", "otile4"}; // optional
  mmap = new InteractiveMap(papplet, new TemplatedMapProvider(template, subdomains));*/
  
    mmap.setCenterZoom(new Location(39,-98), int(zoomValue));     
  }
  
  void drawContent()
  {
    imageMode(CORNER);  // modestmaps needs this - I sent a patch, but who knows when it'll be committed
    mmap.draw();
    smooth();

    drawSightings();
    if (showAirports)
        drawAirports();
    drawSightingsInformationBox();
  }

  boolean contentMouseWheel(float lx, float ly, int delta)
  {
    float sc = 1.0;
    if (delta < 0) {
      sc = 1.05;
    }
    else if (delta > 0) {
      sc = 1.0/1.05;
    }
    float mx = lx - w/2;
    float my = ly - h/2;
    mmap.tx -= mx/mmap.sc;
    mmap.ty -= my/mmap.sc;
    if (mmap.sc*sc > 16 && mmap.sc*sc < 800){
      mmap.sc *= sc;
      zoomValue = ceil(map((int)mmap.sc,16,800,minZoom,maxZoom));
      println(zoomValue + " " + mmap.sc);
    }  
    mmap.tx += mx/mmap.sc;
    mmap.ty += my/mmap.sc;
    
    println("Map tx ty " + mmap.tx + " " + mmap.ty );
    return true;
  }
 
  boolean mouseClicked(float px, float py)
  {
    return true;
  }
  
  boolean mouseDragged(float px, float py)
  {
    mmap.mouseDragged();
    return true;
  }
  
  void drawAirports(){
       noStroke();
       fill(airportAreaColor,40);
       Point2f p2 = mmap.locationPoint(new Location(41.97, -87.905));
       ellipse(p2.x,p2.y,map(zoomValue,minZoom,maxZoom,minDistSize,maxDistSize),map(zoomValue,minZoom,maxZoom,minDistSize,maxDistSize));
       image(airplaneImage,p2.x,p2.y,map(zoomValue,minZoom,maxZoom,minIconSize,maxIconSize),map(zoomValue,minZoom,maxZoom,minIconSize,maxIconSize));
  }
  
  void drawSightings(){
   imageMode(CENTER);
   for (Iterator<Sighting> sightingList = sightings.activeSightingIterator(); sightingList.hasNext();) {
      Sighting newSighting = sightingList.next();
      Point2f p = mmap.locationPoint(((Place)(newSighting.location)).loc);
      image(((SightingType)newSighting.type).icon,p.x,p.y,map(zoomValue,minZoom,maxZoom,minPointSize,maxPointSize),map(zoomValue,minZoom,maxZoom,minPointSize,maxPointSize));
   }
  }
  
  void drawSightingsInformationBox(){
   for (Iterator<Sighting> sightingList = sightings.activeSightingIterator(); sightingList.hasNext();) {
      Sighting newSighting = sightingList.next();
      Point2f p = mmap.locationPoint(((Place)(newSighting.location)).loc);
      if (dist(mouseX,mouseY,p.x,p.y) < map(zoomValue,minZoom,maxZoom,minPointSize/2,maxPointSize/2)){
        textSize(normalFontSize);
        strokeWeight(1);
        stroke(((SightingType)newSighting.type).colr);
        String textToPrint = dateFormat.format(newSighting.localTime);
        if (dateFormat.format(newSighting.localTime).length() < ((Place)(newSighting.location)).name.length())
              textToPrint = ((Place)(newSighting.location)).name;
        fill(infoBoxBackground);
        float w_ = textWidth(textToPrint)+10;
        float x_ = (p.x+w_ > w)?w-w_-5:p.x;
        float h_ = (textAscent() + textDescent()) *3 + 10;
        float y_ = (p.y+h_ > h)?h-h_-5:p.y;
        rect(x_,y_,w_,h_);
        fill(textColor);
        text(dateFormat.format(newSighting.localTime), x_ + (w_ - textWidth(dateFormat.format(newSighting.localTime)))/2 ,y_+5);
        text(((Place)(newSighting.location)).name,x_ + (w_ - textWidth(((Place)(newSighting.location)).name))/2, (y_+ h_/2));
        textSize(smallFontSize);
        text("Click on it to see details",x_+5,y_+h_-10);
        if (mousePressed){
          clickedSighting = newSighting;
        }        
      }
      else if (clickedSighting == newSighting){
        clickedSighting = null;
      }
   }
  }
}

