class Player {
  final static int LOAD_LIMIT = 500;
  final static float DAYS_PER_SECOND = 5.0;
  final static float LINGER_MILLIS = 5.0 * 24 * 3600 * 1000;  // 5 days - in the data timescale!
  long start;
  LinkedList<SightingLite> loaded;
  int loadOffset;
  Date firstDate;
  Date lastDate;
  Calendar now;
  boolean more;

  Player() {
    start = millis();
    loaded = new LinkedList<SightingLite>(data.sightingsByTime(LOAD_LIMIT, 0));
    loadOffset = LOAD_LIMIT;
    firstDate = loaded.get(0).localTime;
    lastDate = data.getLastSightingDate();
    now = Calendar.getInstance();
    more = true;
  }
  
  long ageInMillis(SightingLite s) {
    return now.getTimeInMillis() - s.localTime.getTime();
  }
  
  void update() {
    float seconds = (millis() - start) / 1000.0;
    float dataSeconds = seconds * 24 * 3600 * DAYS_PER_SECOND;
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

class PlayBar extends View {
  final static int MARGIN = 7;

  PlayBar(float x_, float y_, float w_, float h_)
  {
    super(x_, y_, w_, h_);
  }
  
  void drawContent()
  {
    fill(viewBackgroundColor, 220);
    noStroke();
    rect(0, 0, w, h);
    
    if (w > MARGIN*2) {
      stroke(255);
      noFill();
      rect(MARGIN, MARGIN, w - MARGIN*2, h - MARGIN*2);
      
      float x = (float)(player.now.getTimeInMillis() - player.firstDate.getTime()) / (player.lastDate.getTime() - player.firstDate.getTime());
      fill(255);
      rect(MARGIN, MARGIN, (w - MARGIN*2) * x, h - MARGIN*2);
    }
  }
}

class PlayButton extends View {
  final static int MARGIN = 6;
  
  PlayButton(float x_, float y_, float w_, float h_)
  {
    super(x_, y_, w_, h_);
  }
  
  void drawContent()
  {
    fill(viewBackgroundColor, 220);
    noStroke();
//    stroke(0);
    rect(0, 0, w, h);
    
    fill(255);
    float l = h - MARGIN*2;
    if (playing) {
      rect(w/2 - l/2, h/2 - l/2, l, l);
    } else {
      beginShape();
      vertex(w/2 - l/4, h/2 + l/2);
      vertex(w/2 - l/4, h/2 - l/2);
      vertex(w/2 - l/4 + (sqrt(3)/2)*l, h/2);
      endShape(CLOSE);
    }
  }
  
  boolean contentClicked(float lx, float ly)
  {
    if (playing) stopPlaying();
    else startPlaying();      
    return true;
  }
}

