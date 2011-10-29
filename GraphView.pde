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
    rect(0,0,w,h);
    fill(255);
    textAlign(LEFT, TOP);
    text(label,0,0);
  }
  
  boolean contentClicked(float lx, float ly)
  {
    buttonClicked(this);
    return true;
  }
}

class Bucket {
  String label;
  Map<SightingType, Integer> counts;
  
  Bucket(String label)
  {
    this.label = label;
    counts = new HashMap<SightingType, Integer>();
  }
}

/*
  bucket sets we need to support:
  - distance from airport
  - population density
  - time of day
  - month
  - season??
*/

class GraphView extends View {
  List<Bucket> buckets;
  int maxTotal;
  
  GraphView(float x_, float y_, float w_, float h_)
  {
    super(x_, y_, w_, h_);
    fillBuckets();
  }
  
  void fillBuckets()
  {
    buckets = new ArrayList();
    
    /* let's just do months for a start */
    db.query("select cast(strftime('%m',occurred_at) as integer) as month, type_id, count(*) as sighting_count"
      + " from sightings join shapes on shape_id = shapes.id group by month, type_id;");
    
    int prev_m = -1;
    int total = maxTotal = 0;
    Bucket bucket = null;
    
    while (db.next()) {
      int m = db.getInt("month");
      SightingType type = sightingTypeMap.get(db.getInt("type_id"));
      int count = db.getInt("sighting_count");
      
      if (m != prev_m) {
        if (total > maxTotal) maxTotal = total;
        total = 0;
        bucket = new Bucket(str(m));
        buckets.add(bucket);
        prev_m = m;
      }
      bucket.counts.put(type, count);
      total += count;
    }
    if (total > maxTotal) maxTotal = total;
  }
  
  void drawContent()
  {
    fill(255,0,0,128);
    rect(0,0,w,h);
    
    float barw = w / buckets.size();
    
    float barx = 0;
    for (Bucket bucket : buckets) {
      float bary = h;
      for (Entry<SightingType,Integer> entry : bucket.counts.entrySet()) {
        float barh = map(entry.getValue(), 0, maxTotal, 0, h);
        bary -= barh;
        fill(entry.getKey().colr);
        rect(barx, bary, barw, barh);
      }
      barx += barw;
    }
  }
}
