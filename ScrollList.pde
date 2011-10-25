int vSpaceBtwLabels = 5;
color scrollListColor = #2D2A36;
color activeScrollListColor = 0;
color textActiveColor = #FFFF00;

class ScrollList extends View {
  ArrayList labels;
  int firstIndex = 0;
  int selectedIndex = 1;
  int selectedItem = 1;
  VScroll scroll;  
    
  ScrollList(float x_, float y_, float w_, float h_)
  {
    super(x_, y_, w_ , h_);
    labels=new ArrayList();
    
    scroll = new VScroll(w-12,0,12,h);
    this.subviews.add(scroll);
    scroll.linesXSpace = int(w/(textAscent() + textDescent()+ vSpaceBtwLabels));
  }
  
  void add(String _label){
    labels.add(_label);
    scroll.linesCount = labels.size();
  }
  
  void removeAll(){
    labels.clear();
    scroll.linesCount = 0;
    selectedIndex = 1;
    scroll.setCurrentLine(0);
  }
  
  void drawContent()
  {
      textAlign(LEFT,TOP);
      textFont(font,normalFontSize);
      stroke(textColor);
      fill(scrollListColor);
      rect(0,0,w,h);
      textFont(font,normalFontSize);
      float spaceBtwLabels =  textAscent() + textDescent()+ vSpaceBtwLabels;
      firstIndex = scroll.currentLine;
      selectedItem =  constrain(selectedItem,1,labels.size()-firstIndex);
      int _value = selectedItem + firstIndex;
      selectedIndex = (labels.size() >= _value)?constrain(_value,1,labels.size()):constrain(firstIndex,1,labels.size());
      for (int i = 0; i < h/spaceBtwLabels; i++) {
        float y = spaceBtwLabels*i;
         if (labels.size()>i+firstIndex){
             if ((selectedIndex-1)==i+firstIndex){
               fill(activeScrollListColor);
               rect(0,y,(labels.size()<=(h/(textAscent() + textDescent()+ vSpaceBtwLabels)))?w:w-12,textAscent() + textDescent()+ vSpaceBtwLabels);
               fill(textActiveColor);
            }
            else{
              fill(textColor);
            }
            String _str = (String)labels.get(firstIndex+i);
            text(str(i+firstIndex+1)+" - "+_str, x , y+ vSpaceBtwLabels);
         }
     }
  }
  
  boolean contentPressed(float lx, float ly)
  {
      textFont(font,normalFontSize);
      selectedItem = constrain(round(ly / (textAscent() + textDescent()+ vSpaceBtwLabels)),1,labels.size()-firstIndex);
      return true;
  }
  
  boolean contentDragged(float lx, float ly)
  {
      textFont(font,normalFontSize);
      selectedItem = constrain(round(ly / (textAscent() + textDescent()+ vSpaceBtwLabels)),1,labels.size()-firstIndex);
      return true;
  }
}

