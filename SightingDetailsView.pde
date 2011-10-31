static float MULTIPLICATOR_VALUE = 0.5556; 

class SightingDetailsView extends View {

  boolean showView = false;
  List<Sighting> sightings;
  Place place;
  ScrollList sightingSList;
  MultiLineText multiLineText;

  SightingDetailsView(float x_, float y_, float w_, float h_)
  {
    super(x_, y_, w_, h_);
    
    sightingSList = new ScrollList(5,15,200,175);
    this.subviews.add(sightingSList);
    
    multiLineText = new MultiLineText(230,79, w - 250,120);
    this.subviews.add(multiLineText);
    
  }
  
  void setSightings(List<Sighting> _sightings){
    sightings = _sightings;
    sightingSList.removeAll();
    for (int i = 0;i<sightings.size();i++){
        sightingSList.add(shortDateFormat.format(sightings.get(i).localTime));
    }
  }
  
  void drawContent()
  {  
    textFont(font2,normalFontSize); 
    fill(viewBackgroundColor,230);
    stroke(viewBackgroundColor,230);
    rect(0,0, w, h);
    textAlign(LEFT,TOP);
    if (place!=null && sightings.size()>0){
      fill(boldTextColor);
      textSize(normalFontSize);
      text(place.name + " (Total # of Sightings = " + place.sightingCount + ")",(w+230-textWidth(place.name + " (Total # of Sightings = " + place.sightingCount + ")"))/2,5); 
      Sighting newSighting = sightings.get(sightingSList.selectedIndex-1);   
      fill(textColor);  
      text("Local time: "+ dateTimeFormat.format(newSighting.localTime),230,25);
      text("Reported time: " + dateFormat.format(newSighting.reportedTime),600,25);
      String typeOfUFO = "Type of UFO: "+(newSighting.type).name;
      text(typeOfUFO, 230,42);
      text("Shape: " +newSighting.shapeName,600,42);
      text("Weather Condition: "+ newSighting.weather,230,59);
      text("Temperature: " + newSighting.temperature + " °F  /  " + str(int((MULTIPLICATOR_VALUE * (newSighting.temperature - 32))))+" °C",600,59);
     // text("Full description: " + newSighting.description,230,79, w - 250,120);
      //imageMode(CORNER);
     // image((newSighting.type).icon,235 + textWidth(typeOfUFO),42,12,12);
      
      if (!(multiLineText.value).equals("Full description: " + newSighting.description) && newSighting.description.length() > 0){
        multiLineText.setValue("Full description: " + newSighting.description);   
      }
      
      noStroke();
      fill((newSighting.type).colr);
      ellipse(235 + textWidth(typeOfUFO) + 6 ,42 + 6,12,12);
 
    }
    textSize(smallFontSize);
    noFill();
    stroke(textColor);
    rect(w-46,4, 8, 9);
    fill(textColor);
    text("x",w-45,4);
    text("Close",w-35,5);
    textFont(font,normalFontSize); 
  }
  
   boolean contentClicked(float lx, float ly)
  {
    if(lx > w-46 && lx < w - 5  && ly> 4 && ly < 16){
        detailsAnimator.target(height);
    }   
    return true;
  }

}


class MultiLineText extends View {
  
  String value = "";
  VScroll tScroll;  
  int firstIndex = 0;
  float tWidth = 0;
  
  MultiLineText(float x_, float y_, float w_, float h_)
  {
    super(x_, y_, w_ , h_);

    tScroll = new VScroll(w-12,0,12,h);
    this.subviews.add(tScroll);
    
  }
    
  void setValue(String value){
    this.value = value;
    int nol = int(textWidth(value)/w);
    int noltw = int(h / (textAscent() + textDescent())) ;
   
    if (nol > noltw)
        tWidth = w-20;
    else
        tWidth = w;
    tScroll.linesXSpace = noltw;
    tScroll.linesCount =  int(textWidth(value) / tWidth);   
    tScroll.setCurrentLine(0);
  }
  
  void drawContent()
  {
      textFont(font2,normalFontSize);
      textAlign(LEFT,TOP);
      stroke(textColor);
      fill(scrollListColor);
      float vSpaceBtwLines =  textAscent() + textDescent();
      int charactersByLine = int(tWidth/textWidth("w"));
   //   println("current line " +tScroll.currentLine);
      firstIndex = tScroll.currentLine * int(tWidth/textWidth("w"));
    //  println(value.length() + " " + charactersByLine);

      fill(textColor);
      for (int i = 0; i < tScroll.linesXSpace; i++) {
         float y = vSpaceBtwLines*i;  
         if (value.length() > 0 && firstIndex + (i*charactersByLine) <= constrain(firstIndex + (i*charactersByLine) + charactersByLine,1,value.length()-1)){       
            String _str = trim(value.substring(firstIndex + (i*charactersByLine) , constrain(firstIndex + (i*charactersByLine) + charactersByLine,1,value.length()-1)));
            text(_str, 0 , y);
         }
      }
      textFont(font,normalFontSize);
  }
  
}

