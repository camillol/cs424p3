
color vScrollColor = 255;
color buttonsvScrollColor = 255;

class VScroll extends View {
  int currentLine;
  int linesCount;
  int linesXSpace;
  float _y = 0;
  float _h = 12;
  
  VScroll(float x_, float y_, float w_, float h_)
  {
    super(x_, y_, w_, h_);
    linesCount = currentLine = 1;
  }
  
  void setCurrentLine (int _value){
    currentLine = 0;
    _y=0;
  }
  
  void drawContent()
  {
    if (linesCount > linesXSpace){
      noFill();
      stroke(vScrollColor);
      line(0, 0,0,h);
      fill(vScrollColor);
     // float _y = map(currentLine*linesXSpace,0,linesCount,0,linesXSpace);
     // float _h = map(linesXSpace,linesXSpace,linesCount,5,h);
      rect(0,constrain(_y-6,0,h-12), w, _h);
    }
  }

  boolean contentPressed(float lx, float ly)
  {
    _y = ly;
    if (linesCount > linesXSpace){

      currentLine = constrain(int(map(ly,0,h,0,linesCount-1)),0,linesCount-1);
   
    }
    return true;
  }
  
  boolean contentDragged(float lx, float ly)
  {
    _y = ly;
    if (linesCount > linesXSpace){
      currentLine = constrain(int(map(ly,0,h,0,linesCount-1)),0,linesCount-1);

    }
    return true;
  }
}

