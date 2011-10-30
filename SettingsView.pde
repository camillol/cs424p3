class SettingsView extends View {
  HSlider yearSlider;
  HSlider monthSlider;
  HSlider timeSlider;
  Checkbox yearCheckbox, monthCheckbox, timeCheckbox;
  Map<SightingType, Checkbox> typeCheckboxMap;
  Checkbox showAirport;
  Checkbox showMilitaryBases;
  Checkbox showWeatherStation;
  PlayButton play;
  
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
    
    yearSlider = new HSlider(80,10,0,0,yearLabels,"",3);
    this.subviews.add(yearSlider);

    monthSlider = new HSlider(80,40,0,0,monthLabels,"",2);
    this.subviews.add(monthSlider);

    timeSlider = new HSlider(80,70,0,0,timeLabels,"",2);
    this.subviews.add(timeSlider);
    
    int i = 0;
    typeCheckboxMap = new HashMap<SightingType, Checkbox>();
    for (SightingType st : sightingTypeMap.values()) {
      int x_delta = (i / 4) * 160;
      int y_delta = (i % 4) * 20;
      Checkbox cb = new Checkbox(CHECKBOX_X + 10 + x_delta ,CHECKBOX_Y + 9 + y_delta, 12, 12, st.name, st.icon);
      cb.value = true;
      typeCheckboxMap.put(st, cb);
      subviews.add(cb);
      i++;
    }
    
    showAirport = new Checkbox(780,10,12,12,"Show airports",airplaneImage);
    this.subviews.add(showAirport);
    
    showMilitaryBases = new Checkbox(780,30,12,12,"Show military bases",militaryBaseImage);
    this.subviews.add(showMilitaryBases);
    
    showWeatherStation = new Checkbox(780,50,12,12,"Show weather stations",weatherStationImage);
    this.subviews.add(showWeatherStation);
    
    play =  new PlayButton(w-105,h-20,100,20);
    this.subviews.add(play);
    
    showView = false;
  }
  
   void drawContent()
  {
    textSize(normalFontSize);
    fill(viewBackgroundColor,220);
    stroke(viewBackgroundColor,220);
    rect(0,0, w, h-25);
    textFont(font,normalFontSize);
    rect(0,h-25,textWidth("Show Settings")+10,25);
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
    
    textSize(largeFontSize);
    fill(boldTextColor);
    textAlign(LEFT,TOP);
    title = "< MAP " + ((yearSlider.minIndex()!=yearSlider.maxIndex())?("From: "+yearLabelsToPrint[yearSlider.minIndex()] + " To: " + yearLabelsToPrint[yearSlider.maxIndex()]):("Year: "+yearLabelsToPrint[yearSlider.minIndex()]));
    title = title + ((monthCheckbox.value)?((monthSlider.minIndex()!=monthSlider.maxIndex())?(" - " + monthLabelsToPrint[monthSlider.minIndex()] + " to " + monthLabelsToPrint[monthSlider.maxIndex()]):(" - " +  monthLabelsToPrint[monthSlider.minIndex()])):(""));
    title = title +  ((timeCheckbox.value)?(" - " + timeLabels[timeSlider.minIndex()] + ":00 to " + timeLabels[timeSlider.maxIndex()] +":59"):(""));   
    title = title + " >";
    title = title + ((play.value)?(" Showing: "+str(2000+minYearIndex)):"");
    text(title,(w-textWidth(title))/2,h-20);   
   
  }
  
  boolean contentPressed(float lx, float ly)
  {
    if(lx > 0 && lx < textWidth("Show Settings")+10 && ly>h-25 && ly < h){
        settingsAnimator.target((showView)?(-heightView+25):0);
        showView = !showView;    
    }
    return true;
  }
 
}

