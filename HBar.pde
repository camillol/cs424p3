class HBar extends View {
  float level;
  
  HBar(float x_, float y_, float w_, float h_)
  {
    super(x_, y_, w_, h_);
    level = 0.5;
  }
  
  void drawContent()
  {
    noFill();
    stroke(0);
    rect(0, 0, w, h);
    fill(128);
    rect(0, 0, w*level, h);
  }
  
  boolean contentPressed(float lx, float ly)
  {
    level = lx/w;
    return true;
  }
  
  boolean contentDragged(float lx, float ly)
  {
    level = lx/w;
    return true;
  }
}

