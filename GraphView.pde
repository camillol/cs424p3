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
    buckets = data.sightingCountsByMonth();
    maxTotal = 0;
    for (Bucket bucket : buckets) {
      int total = 0;
      for (int count : bucket.counts.values()) total += count;
      if (total > maxTotal) maxTotal = total;
    }
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
        SightingType st = entry.getKey();
        float barh = map(entry.getValue(), 0, maxTotal, 0, h) * st.activeAnimator.value;
        bary -= barh;
        fill(st.colr);
        rect(barx, bary, barw, barh);
      }
      barx += barw;
    }
  }
}
