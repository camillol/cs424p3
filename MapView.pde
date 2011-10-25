import processing.opengl.*;
import com.modestmaps.*;
import com.modestmaps.core.*;
import com.modestmaps.geo.*;
import com.modestmaps.providers.*;

class MapView extends View {
  InteractiveMap mmap;
  float zoomValue = 4;
  float minZoom = 4;
  float maxZoom = 15;
  int minPointSize= 5;
  int maxPointSize = 45;
  int minIconSize= 8;
  int maxIconSize = 25;
  int minDistSize = 1;
  int maxDistSize = 100;
  Sighting clickedSighting;
  Place clickedPlace;
  
  int MAX_BUFFERS_TO_KEEP = 64;
  
  PImage tempIcon;
  
  Map<Coordinate, PGraphics> buffers;
  boolean USE_BUFFERS = true;
  
  double TILE_EXPAND_FACTOR = 0.05;  // as a fraction of the tile size
  
  MapView(float x_, float y_, float w_, float h_)
  {
    super(x_, y_, w_, h_);
    mmap = new InteractiveMap(papplet, new Microsoft.HybridProvider(), w, h);
   // mmap = new InteractiveMap(papplet, new Microsoft.AerialProvider());  
 /* String template = "http://{S}.mqcdn.com/tiles/1.0.0/osm/{Z}/{X}/{Y}.png";
  String[] subdomains = new String[] { "otile1", "otile2", "otile3", "otile4"}; // optional
  mmap = new InteractiveMap(papplet, new TemplatedMapProvider(template, subdomains));*/
  
    mmap.MAX_IMAGES_TO_KEEP = 64;
    mmap.setCenterZoom(new Location(39,-98), int(zoomValue));
    tempIcon = loadImage("yellow.png");
    
    buffers = new LinkedHashMap<Coordinate, PGraphics>(MAX_BUFFERS_TO_KEEP, 0.75, true) {
      protected boolean removeEldestEntry(Map.Entry eldest) {
        return size() > MAX_BUFFERS_TO_KEEP;
      }
    };
  }
  
  void drawOverlay()
  {
    double sc = mmap.sc;
    double tx = mmap.tx;
    double ty = mmap.ty;
    
    // translate and scale, from the middle
    pushMatrix();
    translate(width/2, height/2);
    scale((float)sc);
    translate((float)tx, (float)ty);

    // find the bounds of the ur-tile in screen-space:
    float minX = screenX(0,0);
    float minY = screenY(0,0);
    float maxX = screenX(mmap.TILE_WIDTH, mmap.TILE_HEIGHT);
    float maxY = screenY(mmap.TILE_WIDTH, mmap.TILE_HEIGHT);

    int zoom = mmap.getZoom();
    int cols = (int)pow(2,zoom);
    int rows = (int)pow(2,zoom);

    // find start and end columns
//    println("minX " + minX + " maxX " + maxX + " cols " + cols);
    int minCol = (int)floor(cols * (0-minX) / (maxX-minX));
    int maxCol = (int)ceil(cols * (w-minX) / (maxX-minX)) - 1;
    int minRow = (int)floor(rows * (0-minY) / (maxY-minY));
    int maxRow = (int)ceil(rows * (h-minY) / (maxY-minY)) - 1;
    
    minCol = constrain(minCol, 0, cols);
    maxCol = constrain(maxCol, 0, cols);
    minRow = constrain(minRow, 0, rows);
    maxRow = constrain(maxRow, 0, rows);

    scale(1.0f/pow(2, zoom));
    int count = 0;
    for (int col = minCol; col <= maxCol; col++) {
      for (int row = minRow; row <= maxRow; row++) {
	// source coordinate wraps around the world:
	Coordinate coord = mmap.provider.sourceCoordinate(new Coordinate(row,col,zoom));

	// let's make sure we still have ints:
	coord.row = round(coord.row);
	coord.column = round(coord.column);
	coord.zoom = round(coord.zoom);

        if (!buffers.containsKey(coord))
          buffers.put(coord, makeOverlayBuffer(coord));
        
        image(buffers.get(coord), coord.column*mmap.TILE_WIDTH, coord.row*mmap.TILE_HEIGHT, mmap.TILE_WIDTH, mmap.TILE_HEIGHT);
        count++;
      }
    }
    popMatrix();
//    println("images: " + count + " col " + minCol + " " + maxCol + " rows " + minRow + " " + maxRow);
  }
  
  void applyMapToTileMatrix(PGraphics buffer, Coordinate tileCoord) {
    buffer.translate(-tileCoord.column * mmap.TILE_WIDTH, -tileCoord.row * mmap.TILE_HEIGHT);
    buffer.scale(pow(2, tileCoord.zoom));
    buffer.translate(-(float)mmap.tx, -(float)mmap.ty);
    buffer.scale(1.0/(float)mmap.sc);
    buffer.translate(-mmap.width/2, -mmap.height/2);
  }
  
  PGraphics makeOverlayBuffer(Coordinate coord) {
//    println("makebuf: " + coord);
    PGraphics buf = createGraphics(mmap.TILE_WIDTH, mmap.TILE_HEIGHT, JAVA2D);
    buf.beginDraw();
/*    if ((coord.row + coord.column) % 2 == 0) {
      buf.background(255,0,0,128);
    }
    buf.text(coord.toString(), 50, 50);*/
    
    // we want to be compatible with drawing code that calls mmap.locationPoint
    applyMapToTileMatrix(buf, coord);
    
    // only draw places inside this tile, but with a little margin to account for markers that cross tile boundaries
    Location loc1 = mmap.provider.coordinateLocation(coord);
    Coordinate coord2 = new Coordinate(coord.row + 1, coord.column + 1, coord.zoom);
    Location loc2 = mmap.provider.coordinateLocation(coord2);
    
    double minLon = loc1.lon;
    double maxLon = loc2.lon;
    double minLat = loc2.lat;
    double maxLat = loc1.lat;
    double fudgeLat = (maxLat - minLat) * TILE_EXPAND_FACTOR;
    double fudgeLon = (maxLon - minLon) * TILE_EXPAND_FACTOR;
    
    minLon -= fudgeLon;
    maxLon += fudgeLon;
    minLat -= fudgeLat;
    maxLat += fudgeLat;
    
    drawPlaces(buf, placeTree.find(minLon, minLat, maxLon, maxLat));
    
    buf.endDraw();
    return buf;
  }
  
  void drawContent()
  {
    imageMode(CORNER);  // modestmaps needs this - I sent a patch, but who knows when it'll be committed
    mmap.draw();

    if (USE_BUFFERS) drawOverlay();
    else drawPlaces(papplet.g, places);

    drawPlacesInformationBox();
   // drawSightings();
    if (showAirports)
        drawAirports();
  //  drawSightingsInformationBox();
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
    }  
    mmap.tx += mx/mmap.sc;
    mmap.ty += my/mmap.sc;
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
  
  void drawPlaces(PGraphics buffer, Iterable<Place> places) {
    buffer.imageMode(CENTER);
    for (Place place : places) {
      float maxPointValue =  map(zoomValue, minZoom, maxZoom, minPointSize, maxPointSize);
      float dotSize =  map(place.sightingCount, minCountSightings, maxCountSightings, minPointSize, maxPointValue);
   
      Point2f p = mmap.locationPoint(place.loc);
      
      buffer.image(tempIcon, p.x, p.y, dotSize, dotSize);
    } 
  }
  
  void drawPlacesInformationBox() {
    imageMode(CENTER);
    PImage icon = loadImage("yellow.png");
    for (Iterator<Place> it = places.iterator(); it.hasNext();) {
      Place place = it.next();
      float maxPointValue =  map(zoomValue, minZoom, maxZoom, minPointSize, maxPointSize);
      float dotSize =  map(place.sightingCount, minCountSightings, maxCountSightings, minPointSize, maxPointValue);
      Point2f p = mmap.locationPoint(place.loc); 
          if (dist(mouseX,mouseY,p.x,p.y) < dotSize/2){
            textSize(normalFontSize);
            strokeWeight(1);
            String textToPrint = "Click on it to see details";
            String numOfSightings = "Total # of sightings = " + str(place.sightingCount);
            if (textToPrint.length() < place.name.length())
                  textToPrint = place.name;
            if (textToPrint.length() < numOfSightings.length())
                  textToPrint = numOfSightings;
            fill(infoBoxBackground);
            float w_ = textWidth(textToPrint)+10;
            float x_ = (p.x+w_ > w)?w-w_-5:p.x;
            float h_ = (textAscent() + textDescent()) *3 + 10;
            float y_ = (p.y+h_ > h)?h-h_-5:p.y;
            rect(x_,y_,w_,h_);
            fill(textColor);
            text(place.name, x_ + (w_ - textWidth(place.name))/2 ,y_+5);
            text(numOfSightings,x_ + (w_ - textWidth(numOfSightings))/2, (y_+ h_/3)+5);
            textSize(smallFontSize);
            text("Click on it to see details",x_+5,y_+h_-10);
            if (mousePressed){
              clickedPlace = place;
            }        
          }
      } 
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
        textAlign(LEFT);
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
     // else if (clickedSighting == newSighting){
       // clickedSighting = null;
     // }
   }
  }
}

