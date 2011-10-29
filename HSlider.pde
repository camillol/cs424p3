int spaceBtwLines = 10;
int markSize = 10;
color sliderColor = 150;
color activeSliderColor = 255;

class HSlider extends View {
  private float value;
  private int index_1;
  private int index_2;
  private String minLabel;
  private String maxLabel;
  String[] labels;
  private String title;
  
  private boolean movingMin;
  private boolean movingMax;
  private int charactersToShow;

  
  HSlider(float x_, float y_, float w_, float h_,String[] _labels,String _title,int _chr)
  {
    super(x_, y_, (int(textWidth(_title))  + (_labels.length*spaceBtwLines)), (textAscent() + textDescent() + markSize+2));
    index_1 = 0;
    index_2 = _labels.length-1;
    labels = _labels;
    title = _title;
    charactersToShow = _chr;
  }
  
  HSlider(float x_, float y_, float w_, float h_,String[] _labels,int _chr)
  {
    super(x_, y_, (_labels.length*spaceBtwLines), (textAscent() + textDescent() + markSize+2));
    index_1 = 0;
    index_2 = _labels.length-1;
    labels = _labels;
    title = "";
    charactersToShow = _chr;
  }
  
  void drawContent()
  {
   
      textAlign(LEFT,CENTER);
      textFont(font,normalFontSize);
      fill(textColor);
      text(title, 0, 0);
    
      textFont(font,smallFontSize);
      for (int i = 0; i < labels.length; i++) {
        float x = int(textWidth(title)) + i*spaceBtwLines;
        if (i == index_1) {
          strokeWeight(2);
          stroke(activeSliderColor);
          line(x, 0, x, markSize);
          textAlign(CENTER, TOP);
          text(labels[index_1].substring(0,charactersToShow), x, markSize+2);
        } 
       else if (i == index_2) {
          strokeWeight(2);
          stroke(activeSliderColor);
          line(x, 0, x, markSize);
          textAlign(CENTER, TOP);
          text(labels[index_2].substring(0,charactersToShow), x, markSize+2);
        } 
        else {
          strokeWeight(1);
          stroke(sliderColor);
          line(x, 0, x,markSize-4);
        }
      }
  }
  
  boolean contentPressed(float lx, float ly)
  {
    
    value = constrain(int((lx - textWidth(title)) / spaceBtwLines),0,labels.length-1);
    if (value == index_1)
    {
       movingMin = true;
       movingMax = false;
    }
    else if (value == index_2){
      movingMax = true;
      movingMin = false;
    }
    else {
      movingMin = false;
      movingMax = false;
    }
    
    return true;
  }
  
  boolean contentDragged(float lx, float ly)
  {
    value = constrain(int((lx - textWidth(title)) / spaceBtwLines),0,labels.length-1);
    if (movingMin){        
        index_1 = int(value);
    }else if (movingMax){
        index_2 = int(value);
    }
    return true;
  }
  
  int minIndex(){
    if (index_1 > index_2){
        return index_2;
    }
    return index_1;
  }
  
  int maxIndex(){
    if (index_1 > index_2){
        return index_1;
    }
    return index_2;
  }
}

