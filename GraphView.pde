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
  
  List<String> modes = Arrays.asList("Year", "Season","Month", "Time of day", "Airport distance", "Military Base distance", "Weather Station dist.","County Population dens.");
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
    else if (activeMode.equals("Season")) buckets = data.sightingCountsBySeason();
    else if (activeMode.equals("Month")) buckets = data.sightingCountsByMonth();
    else if (activeMode.equals("Time of day")) buckets = data.sightingCountsByHour();
    else if (activeMode.equals("Airport distance")) buckets = data.sightingCountsByAirportDistance();
    else if (activeMode.equals("Military Base distance")) buckets = data.sightingCountsByMilitaryBaseDistance();
    else if (activeMode.equals("Weather Station dist.")) buckets = data.sightingCountsByWeatherStDistance();
    else if (activeMode.equals("County Population dens.")) buckets = data.sightingCountsByPopulationDensity();
    
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
    fill(backgroundColor);
    stroke(textColor);
    rect (0,h+5,w,110);
    fill(textColor);
    
    float[] activeModeLegend =  getLegendLabels(activeMode);
    if (activeModeLegend != null){
      if (!activeMode.equals("County Population dens."))
         text("Measurement unit = Km", w/2,h+20);
      else 
         text("Population density by County", w/2,h+20);
      textAlign(LEFT,TOP);
      text("[1] < " + nfc(activeModeLegend[0],2),10,h+35);

      for (int i = 1; i <  activeModeLegend.length;i++) {
        int y_delta = (i % 5) * 15;
        int x_delta = (i / 5) * 300;
        text("["+(i+1) + "] >= " + nfc(activeModeLegend[i-1],2) + " and < " + nfc(activeModeLegend[i],2), 10 + x_delta ,h + 35 + y_delta);
      }
      text("["+(activeModeLegend.length+1)+"] >= " + nfc(activeModeLegend[activeModeLegend.length-1],2), 10 + ((activeModeLegend.length / 5) * 300),h + 35 + ((activeModeLegend.length % 5) * 15));
    }
  }
}
