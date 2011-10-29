static float MULTIPLICATOR_VALUE = 0.5556; 

class SightingDetailsView extends View {

  boolean showView = false;
  List<Sighting> sightings;
  Place place;
  ScrollList sightingSList;

  SightingDetailsView(float x_, float y_, float w_, float h_)
  {
    super(x_, y_, w_, h_);
    
    sightingSList = new ScrollList(5,15,200,170);
    this.subviews.add(sightingSList);
    
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
    fill(viewBackgroundColor,230);
    stroke(viewBackgroundColor,230);
    rect(0,0, w, h);

    if (place!=null && sightings.size()>0){
      fill(boldTextColor);
      textSize(normalFontSize);
      text(place.name + " (Total # of Sightings = " + place.sightingCount + ")",(w+230-textWidth(place.name + " (Total # of Sightings = " + place.sightingCount + ")"))/2,5); 
      Sighting newSighting = sightings.get(sightingSList.selectedIndex-1);   
      fill(textColor);  
      text("Local time: "+ dateTimeFormat.format(newSighting.localTime),230,25);
      text("Reported time: " + dateFormat.format(newSighting.reportedTime),550,25);
      String typeOfUFO = "Type of UFO: "+(newSighting.type).name;
      text(typeOfUFO, 230,42);
      imageMode(CORNER);
      image((newSighting.type).icon,235 + textWidth(typeOfUFO),42,12,12);
      text("Shape: " +newSighting.shapeName,550,42);
      text("Weather Condition: "+ newSighting.weather,230,59);
      text("Temperature: " + newSighting.temperature + " °F  /  " + str(int((MULTIPLICATOR_VALUE * (newSighting.temperature - 32))))+" °C",550,59);
      text("Full description: " + newSighting.description,230,79, w - 250,120);
    }
    textSize(smallFontSize);
    noFill();
    stroke(textColor);
    rect(w-45,5, 8, 8);
    text("x",w-43,5);
    text("Close",w-35,5);
  }
  
   boolean contentClicked(float lx, float ly)
  {
    if(lx > w-45 && lx < w - 10  && ly> 5 && ly < 17){
        detailsAnimator.target(height);
    }
        
    return true;
  }
}

