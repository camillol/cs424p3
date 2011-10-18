class SettingsView extends View {
  HSlider yearSlider;
  HSlider monthSlider;
  HSlider timeSlider;
  Checkbox yearCheckbox, monthCheckbox, timeCheckbox;
  Checkbox UFOType1,UFOType2,UFOType3,UFOType4,UFOType5,UFOType6,UFOType7,UFOType8;
  Checkbox showAirport;
  
  int CHECKBOX_X = 450;
  int CHECKBOX_Y = 10;
  int CHECKBOX_W = 300;
  
  boolean showView;
  float heightView ;
  String title;
  
  SettingsView(float x_, float y_, float w_, float h_)
  {
    super(x_, y_, w_, h_);
    heightView = h;
    textFont(font,normalFontSize);
    
    monthCheckbox = new Checkbox(10,40,12,12,"Month:");
    this.subviews.add(monthCheckbox);
    
    timeCheckbox = new Checkbox(10,70,12,12,"Time:");
    this.subviews.add(timeCheckbox);
    
    yearSlider = new HSlider(75,10,0,0,yearLabels,"",3);
    this.subviews.add(yearSlider);

    monthSlider = new HSlider(75,40,0,0,monthLabels,"",2);
    this.subviews.add(monthSlider);

    timeSlider = new HSlider(75,70,0,0,timeLabels,"",2);
    this.subviews.add(timeSlider);
    
    UFOType1 = new Checkbox(CHECKBOX_X + 10 ,CHECKBOX_Y + 9 ,12,12,"UFOType 1","blue.png");
    this.subviews.add(UFOType1);
    
    UFOType2 = new Checkbox(CHECKBOX_X + 10 ,CHECKBOX_Y + 29,12,12,"UFOType 2","green.png");
    this.subviews.add(UFOType2);
    
    UFOType3 = new Checkbox(CHECKBOX_X + 10 ,CHECKBOX_Y + 49,12,12,"UFOType 3","gray.png");
    this.subviews.add(UFOType3);
    
    UFOType4 = new Checkbox(CHECKBOX_X + 10 ,CHECKBOX_Y + 69,12,12,"UFOType 4","orange.png");
    this.subviews.add(UFOType4);
    
    UFOType5 = new Checkbox(CHECKBOX_X + 170 ,CHECKBOX_Y + 9,12,12,"UFOType 5","purple.png");
    this.subviews.add(UFOType5);
    
    UFOType6 = new Checkbox(CHECKBOX_X + 170 ,CHECKBOX_Y + 29,12,12,"UFOType 6","red.png");
    this.subviews.add(UFOType6);
    
    UFOType7 = new Checkbox(CHECKBOX_X + 170,CHECKBOX_Y + 49,12,12,"UFOType 7","yellow.png");
    this.subviews.add(UFOType7);
    
    showAirport = new Checkbox(800,10,12,12,"Show airports","plane.png");
    this.subviews.add(showAirport);
    
    showView = false;
  }
  
   void drawContent()
  {
    fill(viewBackgroundColor,220);
    stroke(viewBackgroundColor,220);
    rect(0,0, w, h-25);
    rect(0,h-25,95,25);
    textFont(font,normalFontSize);
    textAlign(LEFT,TOP);
    fill(textColor);
    text((showView)?"Hide Settings":"Show Settings",5,h-20);
  
    text("Year: ",10,10);
    textAlign(LEFT,CENTER);
    title = " Type of UFO ";
    text(title,CHECKBOX_X,CHECKBOX_Y);
    stroke(textColor);
    line(CHECKBOX_X + textWidth(title)+5,CHECKBOX_Y,CHECKBOX_X+CHECKBOX_W,CHECKBOX_Y);
    line(CHECKBOX_X,CHECKBOX_Y,CHECKBOX_X,h-30);
    line(CHECKBOX_X,h-30,CHECKBOX_X+CHECKBOX_W,h-30);
    line(CHECKBOX_X+CHECKBOX_W,CHECKBOX_Y,CHECKBOX_X+CHECKBOX_W,h-30);
    
    textAlign(LEFT,TOP);
    title = "MAP " + ((yearSlider.minIndex()!=yearSlider.maxIndex())?("From: "+yearLabelsToPrint[yearSlider.minIndex()] + " To: " + yearLabelsToPrint[yearSlider.maxIndex()]):("Year: "+yearLabelsToPrint[yearSlider.minIndex()]));
    title = title + ((monthCheckbox.value)?((monthSlider.minIndex()!=monthSlider.maxIndex())?(" - " + monthLabelsToPrint[monthSlider.minIndex()] + " to " + monthLabelsToPrint[monthSlider.maxIndex()]):(" - " +  monthLabelsToPrint[monthSlider.minIndex()])):(""));
    title = title +  ((timeCheckbox.value)?((timeSlider.minIndex()!=timeSlider.maxIndex())?(" - " + timeLabels[timeSlider.minIndex()] + ":00 to " + timeLabels[timeSlider.maxIndex()] +":00"):(" - " + timeLabels[timeSlider.minIndex()])+":00"):(""));   
    text(title,(width-textWidth(title))/2,h-20);
 
       
  }
  
  boolean contentPressed(float lx, float ly)
  {
    if(lx > 0 && lx <lx+95 && ly>h-25 && ly < h){
        this.y = (showView)?(-heightView+25):0;
        showView = !showView;    
    }
        
    return true;
  }
}

