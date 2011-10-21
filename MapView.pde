import processing.opengl.*;
import com.modestmaps.*;
import com.modestmaps.core.*;
import com.modestmaps.geo.*;
import com.modestmaps.providers.*;
import java.util.Iterator;

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
    imageMode(CORNER);  // modestmaps needs this - I sent a patch, but who knows when it'll be committed
    mmap.draw();
    smooth();

    drawSightings();
    drawAirports();
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
    mmap.sc *= sc;
    mmap.tx += mx/mmap.sc;
    mmap.ty += my/mmap.sc;

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
      //Point2f p = mmap.locationPoint(((Place)(newSighting.location)).loc);
     // image(((SightingType)newSighting.type).icon,p.x,p.y,map(zoomValue,minZoom,maxZoom,minPointSize,maxPointSize),map(zoomValue,minZoom,maxZoom,minPointSize,maxPointSize));
   }
  }
}

