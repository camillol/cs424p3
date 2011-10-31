import java.util.Map.*;  /* workaround for Processing not recognizing Map.Entry<> generic */

class Button extends View {
  String label;
  
  Button(float x_, float y_, float w_, float h_, String label)
  {
    super(x_, y_, w_, h_);
    this.label = label;
  }
  
  void drawContent()
  {
    fill(viewBackgroundColor);
    noStroke();
    rect(0,0,w,h);
    
    textAlign(CENTER, CENTER);
    fill(textColor);
    text(label,w/2,h/2);
  }
  
  boolean contentClicked(float lx, float ly)
  {
    buttonClicked(this);
    return true;
  }
}

color LABEL_COLOR = 255;

class GraphView extends View {
  final static float LABEL_HEIGHT = 20;
  
  List<Bucket> buckets;
  int maxTotal;
  
  List<String> modes = Arrays.asList("Year","Month", "Time of day", "Airport distance", "Military Base dist.", "Weather St. dist.","Population density", "Season");
  String activeMode = "Year";
  
  GraphView(float x_, float y_, float w_, float h_)
  {
    super(x_, y_, w_, h_);
    fillBuckets();
  }
  
  ListDataSource modesDataSource()
  {
    return new ListDataSource() {
      public String getText(int index) { return modes.get(index); }
      public Object get(int index) { return modes.get(index); }
      public int count() { return modes.size(); }
      public boolean selected(int index) { return get(index).equals(activeMode); }
    };
  }
  
  void setActiveMode(String mode)
  {
    activeMode = mode;
    fillBuckets();
  }
  
  void fillBuckets()
  {
    if (activeMode.equals("Year")) buckets = data.sightingCountsByYear();
    else if (activeMode.equals("Month")) buckets = data.sightingCountsByMonth();
    else if (activeMode.equals("Time of day")) buckets = data.sightingCountsByHour();
    maxTotal = 0;
    for (Bucket bucket : buckets) {
      int total = 0;
      for (int count : bucket.counts.values()) total += count;
      if (total > maxTotal) maxTotal = total;
    }
  }
  
  void drawContent()
  {
    fill(backgroundColor);
    rect(0,0,w,h);
    
    float barw = w / buckets.size();
    
    float barx = 0;
    float barmaxh = h - LABEL_HEIGHT;
    textAlign(CENTER, CENTER);
    for (Bucket bucket : buckets) {
      float bary = barmaxh;
      fill(LABEL_COLOR);
      text(bucket.label, barx, barmaxh, barw, LABEL_HEIGHT);
      for (Entry<SightingType,Integer> entry : bucket.counts.entrySet()) {
        SightingType st = entry.getKey();
        float barh = map(entry.getValue(), 0, maxTotal, 0, barmaxh) * st.activeAnimator.value;
        bary -= barh;
        fill(st.colr);
        rect(barx, bary, barw, barh);
      }
      barx += barw;
    }
  }
}
