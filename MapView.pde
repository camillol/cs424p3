import processing.opengl.*;
import com.modestmaps.*;
import com.modestmaps.core.*;
import com.modestmaps.geo.*;
import com.modestmaps.providers.*;

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
    mmap.setCenterZoom(new Location(41.881944,-87.627778), zoomValue);     
  }
  
  void drawContent()
  {
    imageMode(CORNER);  // modestmaps needs this
    mmap.draw();
    smooth();

    drawSightings();
    drawAirports();
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
}

