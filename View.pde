class View {
  float x, y, w, h;
  ArrayList subviews;
  
  View(float x_, float y_, float w_, float h_)
  {
    x = x_;
    y = y_;
    w = w_;
    h = h_;
    subviews = new ArrayList();
  }
  
  void draw()
  {
    pushMatrix();
    translate(x, y);
    // draw out content, then our subviews on top
    drawContent();
    for (int i = 0; i < subviews.size(); i++) {
      View v = (View)subviews.get(i);
      v.draw();
    }
    popMatrix();
  }
  
  void drawContent()
  {
    // override this
    // when this is called, the coordinate system is local to the view,
    // i.e. 0,0 is the top left corner of this view
  }
  
  boolean contentPressed(float lx, float ly)
  {
    // override this
    // lx, ly are in the local coordinate system of the view,
    // i.e. 0,0 is the top left corner of this view
    // return false if the click is to "pass through" this view
    return true;
  }
  
  boolean contentDragged(float lx, float ly)
  {
    return true;
  }
  
  boolean contentClicked(float lx, float ly)
  {
    return true;
  }
  
  boolean contentMouseWheel(float lx, float ly, int delta)
  {
    return false;
  }

  boolean ptInRect(float px, float py, float rx, float ry, float rw, float rh)
  {
    return px >= rx && px <= rx+rw && py >= ry && py <= ry+rh;
  }

  boolean mousePressed(float px, float py)
  {
    if (!ptInRect(px, py, x, y, w, h)) return false;
    float lx = px - x;
    float ly = py - y;
    // check our subviews first
    for (int i = subviews.size()-1; i >= 0; i--) {
      View v = (View)subviews.get(i);
      if (v.mousePressed(lx, ly)) return true;
    }
    return contentPressed(lx, ly);
  }

  boolean mouseDragged(float px, float py)
  {
    if (!ptInRect(px, py, x, y, w, h)) return false;
    float lx = px - x;
    float ly = py - y;
    // check our subviews first
    for (int i = subviews.size()-1; i >= 0; i--) {
      View v = (View)subviews.get(i);
      if (v.mouseDragged(lx, ly)) return true;
    }
    return contentDragged(lx, ly);
  }

  boolean mouseClicked(float px, float py)
  {
    if (!ptInRect(px, py, x, y, w, h)) return false;
    float lx = px - x;
    float ly = py - y;
    // check our subviews first
    for (int i = subviews.size()-1; i >= 0; i--) {
      View v = (View)subviews.get(i);
      if (v.mouseClicked(lx, ly)) return true;
    }
    return contentClicked(lx, ly);
  }
  
  boolean mouseWheel(float px, float py, int delta)
  {
    if (!ptInRect(px, py, x, y, w, h)) return false;
    float lx = px - x;
    float ly = py - y;
    // check our subviews first
    for (int i = subviews.size()-1; i >= 0; i--) {
      View v = (View)subviews.get(i);
      if (v.mouseWheel(lx, ly, delta)) return true;
    }
    return contentMouseWheel(lx, ly, delta);
  }
}

