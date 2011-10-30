import processing.opengl.*;
import com.modestmaps.*;
import com.modestmaps.core.*;
import com.modestmaps.geo.*;
import com.modestmaps.providers.*;
import java.util.concurrent.*;

class MapView extends View {
  InteractiveMap mmap;
  float zoomValue = 4;
  float minZoom = 4;
  float maxZoom = 15;
  int minPointSize= 5;
  int maxPointSize = 45;
  int minIconSize= 10;
  int maxIconSize = 25;
  int minDistSize = 1;
  int maxDistSize = 150;
  Sighting clickedSighting;
  Place clickedPlace;
  
  int MAX_BUFFERS_TO_KEEP = 64;
  
  
  Map<Coordinate, Future<PGraphics>> buffers;
  ExecutorService bufferExec;
  boolean USE_BUFFERS = true;
  
  double TILE_EXPAND_FACTOR = 0.05;  // as a fraction of the tile size
  
  boolean DRAW_ALL_TYPES = false;
  
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
    
    buffers = new LinkedHashMap<Coordinate, Future<PGraphics>>(MAX_BUFFERS_TO_KEEP, 0.75, true) {
      protected boolean removeEldestEntry(Entry<Coordinate, Future<PGraphics>> eldest) {
        if (size() > MAX_BUFFERS_TO_KEEP) {
          eldest.getValue().cancel(true);
          this.remove(eldest.getKey());
        }
        return false;
      }
    };
    bufferExec = Executors.newSingleThreadExecutor();
  }
  
  void rebuildOverlay()
  {
    for (Future<PGraphics> future : buffers.values()) {
      future.cancel(true);
    }
    buffers.clear();
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
          buffers.put(coord, bufferExec.submit(new BufferMaker(coord)));
        
        if (buffers.get(coord).isDone()) {
          try {
            PGraphics img = buffers.get(coord).get();
            image(img, coord.column*mmap.TILE_WIDTH, coord.row*mmap.TILE_HEIGHT, mmap.TILE_WIDTH, mmap.TILE_HEIGHT);
          } catch (InterruptedException e) {
            println(e);
          } catch (ExecutionException e) {
            println(e);
          }
        }
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
    
    drawPlaces(buf, placesInRect(cityTree, loc1, loc2, TILE_EXPAND_FACTOR));
    if (showAirports)
        drawAirports(buf,placesInRect(airportTree,loc1,loc2,TILE_EXPAND_FACTOR));
    if (showMilitaryBases)
        drawMilitaryBases(buf,placesInRect(militaryBaseTree,loc1,loc2,TILE_EXPAND_FACTOR));
    if (showWeatherStation)
        drawWeatherStations(buf,placesInRect(weatherStationTree,loc1,loc2,TILE_EXPAND_FACTOR));
    
    buf.endDraw();
    return buf;
  }
  
  class BufferMaker implements Callable<PGraphics> {
    Coordinate coord;
    BufferMaker(Coordinate coord)
    {
      this.coord = coord;
    }
    
    PGraphics call()
    {
      return makeOverlayBuffer(coord);
    }
  }
  
  void drawContent()
  {
    imageMode(CORNER);  // modestmaps needs this - I sent a patch, but who knows when it'll be committed
    mmap.draw();

    if (USE_BUFFERS) drawOverlay();
    else{
      drawPlaces(papplet.g, cityMap.values());
      drawAirports(papplet.g, airportMap.values());
      drawMilitaryBases(papplet.g,militaryBaseMap.values());
      drawWeatherStations(papplet.g,weatherStationMap.values());
      
    }
    
    drawPlacesInformationBox();

  }

  boolean contentMouseWheel(float lx, float ly, int delta)
  {
    if ( ly > (settingsView.y+settingsView.h) && ly < (sightingDetailsView.y)){
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
        if (mmap.sc*sc > 16 && mmap.sc*sc < 900){
          mmap.sc *= sc;
          zoomValue = ceil(map((int)mmap.sc,16,900,minZoom,maxZoom));
        }  
        mmap.tx += mx/mmap.sc;
        mmap.ty += my/mmap.sc;
    }
    return true;
  }
 
  boolean contentClicked(float px, float py)
  {
    if (clickedPlace == null){
      detailsAnimator.target(height);
    }
    else if (sightingDetailsView.place!=clickedPlace){
      sightingDetailsView.place = clickedPlace;
      sightingDetailsView.setSightings(data.sightingsForCity(mapv.clickedPlace));
      detailsAnimator.target(height-200);
    }
    
    return true;
  }
  
  boolean mouseDragged(float px, float py)
  {
      if ( py > (settingsView.y+settingsView.h) && py < (sightingDetailsView.y)){
          mmap.mouseDragged();
      }
      return true;
  }
  
  void drawAirports(PGraphics buffer, Iterable<Place> airports){
      buffer.imageMode(CENTER);
      buffer.noStroke();
      buffer.fill(airportAreaColor,40);
      for (Place airport : airports) {
          float pointSize =  map(zoomValue, minZoom, maxZoom, minDistSize, maxDistSize);
          float iconSize = map(zoomValue,minZoom,maxZoom,minIconSize,maxIconSize);
          Point2f p = mmap.locationPoint(airport.loc);
          buffer.ellipse(p.x,p.y,pointSize,pointSize);
          buffer.image(airplaneImage,p.x,p.y,iconSize,iconSize);
      } 
  }
  
  void drawMilitaryBases(PGraphics buffer, Iterable<Place> militaryBases){
      buffer.imageMode(CENTER);
      buffer.noStroke();
      buffer.fill(militaryBaseColor,40);
      for (Place militaryBase : militaryBases) {   
        float pointSize =  map(zoomValue, minZoom, maxZoom, minDistSize, maxDistSize);
        float iconSize = map(zoomValue,minZoom,maxZoom,minIconSize,maxIconSize);
        Point2f p = mmap.locationPoint(militaryBase.loc);
        buffer.ellipse(p.x,p.y,pointSize,pointSize);
        buffer.image(militaryBaseImage,p.x,p.y,iconSize,iconSize);
      } 
  }
  
  void drawWeatherStations(PGraphics buffer, Iterable<Place> weatherStations){
      buffer.imageMode(CENTER);
      buffer.noStroke();
      buffer.fill(weatherStationColor,40);
      for (Place weatherStation : weatherStations) {   
        float pointSize =  map(zoomValue, minZoom, maxZoom, minDistSize, maxDistSize);
        float iconSize = map(zoomValue,minZoom,maxZoom,minIconSize,maxIconSize);
        Point2f p = mmap.locationPoint(weatherStation.loc);
        buffer.ellipse(p.x,p.y,pointSize,pointSize);
        buffer.image(weatherStationImage,p.x,p.y,iconSize,iconSize);
      } 
  }
  
  void drawPlaces(PGraphics buffer, Iterable<Place> places) {
    buffer.imageMode(CENTER);
    buffer.strokeWeight(0.5);
    
    buffer.noStroke();
    for (Place place : places) {
      if (place.sightingCount > 0){
        Point2f p = mmap.locationPoint(place.loc);
        if (DRAW_ALL_TYPES) {
          int boxsz = ceil(sqrt(place.sightingCount));
          int boxx = 0;
          int boxy = 0;
          buffer.pushMatrix();
          buffer.translate(p.x - boxsz/2, p.y - boxsz/2);
          int idx = 0;
          for (SightingType st : sightingTypeMap.values()) {
            buffer.fill(st.colr);
            int count = place.counts[idx];
            while (count > 0) {
              if (boxx == boxsz){
                boxx = 0;
                boxy++;
              }
              int len = min(boxsz - boxx, count);
              buffer.rect(boxx, boxy, len, 1);
              boxx += len;
              count -= len;
            }
            idx++;
          }
          buffer.popMatrix();
        } else {
          /* I now load sighting counts for all types, but this calculates the values we had before */
          int typeOfSightingCount = 0;
          SightingType sightingType = null;
          int idx = 0;
          for (SightingType st : sightingTypeMap.values()) {
            if (place.counts[idx] > 0) {
              typeOfSightingCount++;
              sightingType = st;
            }
            idx++;
          }
          
          float maxPointValue =  map(zoomValue, minZoom, maxZoom, minPointSize, maxPointSize);
          float dotSize =  map(place.sightingCount, minCountSightings, maxCountSightings, minPointSize, maxPointValue);
          
          if (typeOfSightingCount > 1) {
              buffer.stroke(0);
              buffer.fill(255);
              buffer.ellipse(p.x, p.y, dotSize, dotSize);
          }
          else {
              buffer.noStroke();
              buffer.fill(sightingType.colr,150);
              buffer.ellipse(p.x, p.y, dotSize, dotSize);
              //buffer.image((sightingTypeMap.get(place.sightingType)).icon, p.x, p.y, dotSize, dotSize);
          }   
        }
      }
    } 
  }
  
  void drawPlacesInformationBox() {
    imageMode(CENTER);
    
    float maxPointValue =  map(zoomValue, minZoom, maxZoom, minPointSize, maxPointSize);
    Location loc1 = mmap.pointLocation(mouseX - maxPointValue, mouseY - maxPointValue);  // TODO: use local coordinates (although they're identical in this app)
    Location loc2 = mmap.pointLocation(mouseX + maxPointValue, mouseY + maxPointValue);
    
    for (Place place : placesInRect(cityTree,loc1, loc2, 0.0)) {
      if (place.sightingCount > 0){
          float dotSize =  map(place.sightingCount, minCountSightings, maxCountSightings, minPointSize, maxPointValue);
          Point2f p = mmap.locationPoint(place.loc); 
              if (dist(mouseX,mouseY,p.x,p.y) < dotSize/2 && p.y > (settingsView.y+settingsView.h) && p.y < (sightingDetailsView.y)){
                textSize(normalFontSize);
                strokeWeight(1);
                String textToPrint = "Click on it to see details";
                String numOfSightings = "Total # of sightings = " + str(place.sightingCount);
                if (textToPrint.length() < place.name.length())
                      textToPrint = place.name;
                if (textToPrint.length() < numOfSightings.length())
                      textToPrint = numOfSightings;
                fill(infoBoxBackground);
                stroke((sightingTypeMap.get(place.sightingType)).colr);
                float w_ = textWidth(textToPrint)+10;
                float x_ = (p.x+w_ > w)?w-w_-5:p.x;
                float h_ = (textAscent() + textDescent()) * 3 + 15;
                float y_ = (p.y+h_ > sightingDetailsView.y)?sightingDetailsView.y-h_-5:p.y;
                rect(x_,y_,w_,h_);
                fill(textColor);
                text(place.name, x_ + (w_ - textWidth(place.name))/2 ,y_+5);  
                text(numOfSightings,x_ + (w_ - textWidth(numOfSightings))/2, (y_+ h_/3)+5);
                textSize(smallFontSize);
                text("Click on it to see details",x_+5,y_+h_-12);
                if (mousePressed){
                  clickedPlace = place;
                }        
              }
          } 
     }
  }
}

