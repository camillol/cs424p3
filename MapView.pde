import processing.opengl.*;
import com.modestmaps.*;
import com.modestmaps.core.*;
import com.modestmaps.geo.*;
import com.modestmaps.providers.*;
import java.util.concurrent.*;
import java.awt.geom.*;

/* Cohen-Sutherland algorithm */
Line2D clipLineToRect(Line2D l, Rectangle2D r)
{
  double x1 = l.getP1().getX();
  double y1 = l.getP1().getY();
  double x2 = l.getP2().getX();
  double y2 = l.getP2().getY();
  int out1 = r.outcode(x1, y1);
  int out2 = r.outcode(x2, y2);
  
  while (true) {
    if ((out1 | out2) == 0) return new Line2D.Double(x1, y1, x2, y2);  /* entirely inside */
    if ((out1 & out2) != 0) return null;                               /* entirely outside */
    
    int out = out1 != 0 ? out1 : out2;
    double x, y;
    if ((out & (Rectangle2D.OUT_LEFT | Rectangle2D.OUT_RIGHT)) != 0) {
      x = r.getX();
      if ((out & Rectangle2D.OUT_RIGHT) != 0) x += r.getWidth();
      y = y1 + (x - x1) * (y2 - y1) / (x2 - x1);
    } else {
      y = r.getY();
      if ((out & Rectangle2D.OUT_BOTTOM) != 0) y += r.getHeight();
      x = x1 + (y - y1) * (x2 - x1) / (y2 - y1);
    }
    if (out == out1) {
      x1 = x;
      y1 = y;
      out1 = r.outcode(x1, y1);
    } else {
      x2 = x;
      y2 = y;
      out2 = r.outcode(x2, y2);
    }
  }
}

class Player {
  final static int LOAD_LIMIT = 500;
  final static float DAYS_PER_SECOND = 5.0;
  final static float LINGER_MILLIS = 5.0 * 24 * 3600 * 1000;  // 5 days - in the data timescale!
  long start;
  LinkedList<SightingLite> loaded;
  int loadOffset;
  Date firstDate;
  Calendar now;
  boolean more;

  Player() {
    start = millis();
    loaded = new LinkedList<SightingLite>(data.sightingsByTime(LOAD_LIMIT, 0));
    loadOffset = LOAD_LIMIT;
    firstDate = loaded.get(0).localTime;
    now = Calendar.getInstance();
    more = true;
  }
  
  long ageInMillis(SightingLite s) {
    return now.getTimeInMillis() - s.localTime.getTime();
  }
  
  void update() {
    float seconds = (millis() - start) / 1000.0;
    float dataSeconds = seconds * 24 * 3600;
    now.setTime(firstDate);
    now.add(Calendar.SECOND, ceil(dataSeconds));
    
    while (more && (loaded.isEmpty() || now.after(loaded.getLast().localTime))) {
      List<SightingLite> s = data.sightingsByTime(LOAD_LIMIT, loadOffset);
      println("loaded " + s.size());
      if (s.size() == 0) more = false;
      else {
        loaded.addAll(s);
        loadOffset += s.size();
        println(loaded.getLast().localTime);
      }
    }
    
    Iterator<SightingLite> it = loaded.iterator();
    while (it.hasNext()) {
      SightingLite s = it.next();
      if (ageInMillis(s) > LINGER_MILLIS) it.remove();
    }
  }
}

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
  
  Map<State, StateGlyph> stateGlyphs;
  boolean movingGlyphs;
  PMatrix2D glyphSavedMatrix;
  PMatrix2D currentTileToMapMatrix;
  
  MapView(float x_, float y_, float w_, float h_)
  {
    super(x_, y_, w_, h_);
//    mmap = new InteractiveMap(papplet, new Microsoft.HybridProvider(), w, h);
//    mmap = new InteractiveMap(papplet, new Microsoft.AerialProvider(), w, h);
    String template = "http://{S}.mqcdn.com/tiles/1.0.0/osm/{Z}/{X}/{Y}.png";
    String[] subdomains = new String[] { "otile1", "otile2", "otile3", "otile4"}; // optional
    mmap = new InteractiveMap(papplet, new TemplatedMapProvider(template, subdomains), w, h);
  
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
    
    stateGlyphs = new HashMap<State, StateGlyph>();
  }
  
  void rebuildOverlay()
  {
    for (Future<PGraphics> future : buffers.values()) {
      future.cancel(true);
    }
    buffers.clear();
    stateGlyphs.clear();
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
  
  PMatrix2D makeMapToTileMatrix(Coordinate tileCoord) {
    PMatrix2D m = new PMatrix2D();
    m.translate(-tileCoord.column * mmap.TILE_WIDTH, -tileCoord.row * mmap.TILE_HEIGHT);
    m.scale(pow(2, tileCoord.zoom));
    m.translate(-(float)mmap.tx, -(float)mmap.ty);
    m.scale(1.0/(float)mmap.sc);
    m.translate(-mmap.width/2, -mmap.height/2);
    return m;
  }
  
  PMatrix2D makeTileToMapMatrix(Coordinate tileCoord) {
    PMatrix2D m = new PMatrix2D();
    m.translate(mmap.width/2, mmap.height/2);
    m.scale((float)mmap.sc);
    m.translate((float)mmap.tx, (float)mmap.ty);
    m.scale(pow(2, -tileCoord.zoom));
    m.translate(tileCoord.column * mmap.TILE_WIDTH, tileCoord.row * mmap.TILE_HEIGHT);
    return m;
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
    
    if (showByStates) {
//      drawStates(buf, stateMap.values());
    } else
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
  
  class StateGlyph {
    final static float REPULSION = 0.85;
    final static float RETURN = 0;
    final static float FRICTION = 0.6;
    final static int MARGIN = 2;
    final static float STOP_THRESHOLD = 0.01;
    
    PGraphics buf;
    float x0, y0;
    float x;
    float y;
    float vx;
    float vy;
    
    StateGlyph(State state) {
      int boxsz = ceil(sqrt(state.sightingCount));
      buf = createGraphics(boxsz, boxsz, JAVA2D);
      buf.beginDraw();
      drawSightingDots(buf, state, new Point2f(boxsz/2, boxsz/2));
      buf.endDraw();
      
      Point2f p = mmap.locationPoint(state.loc);
      x = x0 = p.x;
      y = y0 = p.y;
      vx = vy = 0;
    }
    
    Rectangle2D rect()
    {
      return new Rectangle2D.Float(x - buf.width/2 - MARGIN, y - buf.height/2 - MARGIN, buf.width + MARGIN*2, buf.height + MARGIN*2);
    }
    
    Point2f posOnScreen()
    {
      float tilept[] = new float[2];
      glyphSavedMatrix.mult(new float[] {x, y}, tilept);
      float screenpt[] = new float[2];
      currentTileToMapMatrix.mult(tilept, screenpt);
      return new Point2f(screenpt[0], screenpt[1]);
    }
    
    void collide(StateGlyph other)
    {
      Rectangle2D rect_this = this.rect();
      Rectangle2D rect_other = other.rect();
      Rectangle2D rect_intersect = rect_this.createIntersection(rect_other);
        
      if (!rect_intersect.isEmpty()) {
        double m_this = rect_this.getHeight() * rect_this.getWidth();
        double m_other = rect_other.getHeight() * rect_other.getWidth();
        
        Line2D l = new Line2D.Double(rect_this.getCenterX(), rect_this.getCenterY(), rect_other.getCenterX(), rect_other.getCenterY());
        l = clipLineToRect(l, rect_intersect);
        
        double dx = l.getX1() - l.getX2();
        double dy = l.getY1() - l.getY2();
        
        vx += dx * m_other / (m_this + m_other) * REPULSION;
        vy += dy * m_other / (m_this + m_other) * REPULSION;
        
        other.vx += - dx * m_this / (m_this + m_other) * REPULSION;
        other.vy += - dy * m_this / (m_this + m_other) * REPULSION;
      }
    }
    
    float move()
    {
      vx += (x0 - x) * RETURN;
      vy += (y0 - y) * RETURN;
      
      vx *= (1 - FRICTION);
      vy *= (1 - FRICTION);
      
      x += vx;
      y += vy;
      
      return sqrt(vx*vx + vy*vy);
    }
  }
  
  void drawContent()
  {
    imageMode(CORNER);  // modestmaps needs this - I sent a patch, but who knows when it'll be committed
    mmap.draw();

    currentTileToMapMatrix = makeTileToMapMatrix(new Coordinate(0,0,0));
    
    if (playing) {
      player.update();
      noStroke();
      for (SightingLite s : player.loaded) {
        long age = player.ageInMillis(s);
        if (age < 0) break;
        float a = map(age, 0, player.LINGER_MILLIS, 255, 0);
        Point2f p = mmap.locationPoint(s.location.loc);
        fill(s.type.colr, a);
        ellipse(p.x, p.y, 10, 10);
      }
      
      return;
    }

    if (USE_BUFFERS) drawOverlay();
    else{
      if (!showByStates) drawPlaces(papplet.g, cityMap.values());
      if (showAirports)
        drawAirports(papplet.g, airportMap.values());
      if (showMilitaryBases)
        drawMilitaryBases(papplet.g,militaryBaseMap.values());
      if (showWeatherStation)
        drawWeatherStations(papplet.g,weatherStationMap.values());
    }
    if (showByStates) {
      imageMode(CENTER);
      
      /* create all glyphs if missing */
      if (stateGlyphs.size() == 0) {
        for (State state : stateMap.values()) {
          if (state.sightingCount <= 0) continue;
  //        if (state.abbr.equals("CA") || state.abbr.equals("NV"))
          stateGlyphs.put(state, new StateGlyph(state));
        }
        if (stateGlyphs.size() > 0) {
          movingGlyphs = true;
          glyphSavedMatrix = makeMapToTileMatrix(new Coordinate(0,0,0));
          /* this matrix maps from screen to megatile coordinates. hopefully. */
        }
      }
      
      if (movingGlyphs) {
        float max_move = 0;
        /* let's try to avoid overlaps */
        int i = 0;
        for (StateGlyph sg : stateGlyphs.values()) {
          int j = 0;
          for (StateGlyph sg2 : stateGlyphs.values()) {
            if (j > i) sg.collide(sg2);
            j++;
          }
          max_move = max(max_move, sg.move());
          i++;
        }
        if (max_move < StateGlyph.STOP_THRESHOLD) {
          movingGlyphs = false;
          println("done moving");
        }
      }
      
      for (State state : stateMap.values()) {
        if (state.sightingCount <= 0) continue;
        StateGlyph sg = stateGlyphs.get(state);
        
        if (sg == null) continue;
        
//        line(sg.x, sg.y, sg.x0, sg.y0);
        Point2f p = sg.posOnScreen();
        image(sg.buf, p.x, p.y);
      }
    }
    
    if (showByStates) drawStatesInformationBox();
    else drawPlacesInformationBox();
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
  
  void drawSightingDots(PGraphics buffer, Place place, Point2f p)
  {
    int boxsz = ceil(sqrt(place.sightingCount));
    int boxx = 0;
    int boxy = 0;
    buffer.pushMatrix();
    buffer.translate(p.x - boxsz/2, p.y - boxsz/2);
    int idx = 0;

    buffer.noStroke();
    for (SightingType st : sightingTypeMap.values()) {
      if (st.active) {
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
      }
      idx++;
    }
    buffer.popMatrix();
  }
  
  void drawPlaces(PGraphics buffer, Iterable<? extends Place> places) {
    buffer.imageMode(CENTER);
    buffer.strokeWeight(0.5);
    
    buffer.noStroke();
    for (Place place : places) {
      if (place.sightingCount > 0){
        Point2f p = mmap.locationPoint(place.loc);
        if (DRAW_ALL_TYPES) {
          drawSightingDots(buffer, place, p);
        } else {
          SightingType st = mainSightingTypeForPlace(place);
          float maxPointValue =  map(zoomValue, minZoom, maxZoom, minPointSize, maxPointSize);
          float dotSize =  map(place.sightingCount, minCountSightings, maxCountSightings, minPointSize, maxPointValue);
          
          if (st == null) {
              buffer.stroke(0);
              buffer.fill(255);
              buffer.ellipse(p.x, p.y, dotSize, dotSize);
          }
          else {
              buffer.noStroke();
              buffer.fill(st.colr,150);
              buffer.ellipse(p.x, p.y, dotSize, dotSize);
              //buffer.image((sightingTypeMap.get(place.sightingType)).icon, p.x, p.y, dotSize, dotSize);
          }   
        }
      }
    } 
  }
  
  SightingType mainSightingTypeForPlace(Place place)
  {
    /* I now load sighting counts for all types, but this calculates the values we had before */
    int typeOfSightingCount = 0;
    SightingType sightingType = null;
    int idx = 0;
    for (SightingType st : sightingTypeMap.values()) {
      if (st.active && place.counts[idx] > 0) {
        typeOfSightingCount++;
        sightingType = st;
      }
      idx++;
    }
    if (typeOfSightingCount == 1) return sightingType;
    else return null;
  }
  
  void drawStatesInformationBox() {
    textAlign(LEFT, TOP);
    fill(0);
    for (Entry<State,StateGlyph> entry : stateGlyphs.entrySet()) {
      State state = entry.getKey();
      StateGlyph sg = entry.getValue();
      
      Point2f p = sg.posOnScreen();
      float x = p.x - sg.buf.width/2;
      float y = p.y - sg.buf.height/2;
      Rectangle2D r = new Rectangle2D.Float(x, y, sg.buf.width, sg.buf.height);
      if (r.contains(mouseX, mouseY)) {
        fill(infoBoxBackground);
        stroke(textColor);       
        float w_ = textWidth("Total # of sightings = "+nfc(state.sightingCount))+20;
        float x_ = (x+w_ > w)?w-w_-5:x;
        float h_ = (textAscent() + textDescent()) * 2 + 15;
        float y_ = (y + sg.buf.height+h_ > sightingDetailsView.y)?sightingDetailsView.y-h_-5:y + sg.buf.height;
        rect(x_,y_,w_,h_);
        fill(textColor);
        text(state.name, x_ + (w_ - textWidth(state.name))/2 ,y_+5);  
        text("Total # of sightings = "+nfc(state.sightingCount),x_ + (w_ - textWidth("Total # of sightings = "+state.sightingCount))/2, (y_+ h_/2)+5);               
      }
    }
  }
  
  void drawPlacesInformationBox() {
    imageMode(CENTER);
    textAlign(LEFT, TOP);
    
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
                String numOfSightings = "Total # of sightings = " + nfc(place.sightingCount);
                if (textToPrint.length() < place.name.length())
                      textToPrint = place.name;
                if (textToPrint.length() < numOfSightings.length())
                      textToPrint = numOfSightings;
                fill(infoBoxBackground);
                SightingType st = mainSightingTypeForPlace(place);
                if (st == null) stroke(255);
                else stroke(st.colr);
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

