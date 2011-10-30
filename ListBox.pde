interface ListDataSource {
  String getText(int index);
  Object get(int index);
  int count();
  boolean selected(int index);
}

class MissingListDataSource implements ListDataSource {
  String msg;
  
  MissingListDataSource(String msg_) { msg = msg_; }
  String getText(int index) { return msg; }
  Object get(int index) { return null; }
  int count() { return 1; }
  boolean selected(int index) { return false; }
}

class ListBox extends View {
  final int rowHeight = 20;
  final int barSize = 14;
  
  color bgColor = color(0);
  color fgColor = color(255);
  color selBgColor = color(128);
  color selFgColor = color(255);
  
  ListDataSource data;
  int scrollPos = 0;
  
  float thumbClickPos = -1;
  
  ListBox(float x_, float y_, float w_, float h_, ListDataSource data_)
  {
    super(x_,y_,w_,h_);
    data = data_;
  }
  
  int maxScroll()
  {
    return max(data.count() - int(h/rowHeight), 0);
  }
  
  void scrollTo(int index)
  {
    scrollPos = min(max(index, 0), maxScroll());
  }

  void drawContent()
  {
    strokeWeight(1);
    stroke(fgColor);
    fill(bgColor);
    rect(0,0,w,h);
    noStroke();
    
    textAlign(LEFT, CENTER);
    for(int i = scrollPos; i < scrollPos + (h/rowHeight) && i < data.count(); i++) {
      float rowy = (i-scrollPos) * rowHeight;
      if (data.selected(i)) {
        fill(selBgColor);
        rect(0, rowy, w, rowHeight);
        fill(selFgColor);
      } else {
        fill(fgColor);
      }
      text(data.getText(i), 8, rowy, w, rowHeight);
    }
    
    if (maxScroll() > 0) {
      pushMatrix();
      translate(w-barSize, 0);
      
      /* draw scrollbar */
      fill(bgColor);
      rect(0, 0, barSize, h);
      
      float thumbH = map(int(h/rowHeight), 0, data.count(), 0, h);
      float thumbY = map(scrollPos, 0, maxScroll(), 0, h-thumbH);
      fill(fgColor);
      rect(0, thumbY, barSize, thumbH);
      
      popMatrix();
    }
  }
  
  boolean contentPressed(float lx, float ly)
  {
    if (maxScroll() > 0 && lx >= w-barSize) {
      float thumbH = map(int(h/rowHeight), 0, data.count(), 0, h);
      float thumbY = map(scrollPos, 0, maxScroll(), 0, h-thumbH);
      thumbClickPos = (ly - thumbY) / thumbH;
    }
    return true;
  }
  
  boolean contentDragged(float lx, float ly)
  {
    if (thumbClickPos >= 0.0 && thumbClickPos <= 1.0) {
      float thumbH = map(int(h/rowHeight), 0, data.count(), 0, h);
      float thumbY = constrain(ly - thumbClickPos * thumbH, 0, h-thumbH);
      scrollPos = round(map(thumbY, 0, h-thumbH, 0, maxScroll()));
    }
    return true;
  }
  
  boolean contentClicked(float lx, float ly)
  {
    int index = constrain(int(ly/rowHeight) + scrollPos, 0, data.count()-1);
    listClicked(this, index, data.get(index));
    return true;
  }
}

