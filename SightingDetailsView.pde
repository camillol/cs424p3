class SightingDetailsView extends View {

  boolean showView = false;
  List<Sighting> sightings;
  Place place;
  ScrollList sightingSList;

  SightingDetailsView(float x_, float y_, float w_, float h_)
  {
    super(x_, y_, w_, h_);
    
    sightingSList = new ScrollList(5,5,200,180);
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
    fill(viewBackgroundColor,220);
    stroke(viewBackgroundColor,220);
    rect(0,0, w, h);
    if (place!=null){
      fill(boldTextColor);
       text(place.name + " (Total # of Sightings = " + place.sightingCount + ")",(w+230-textWidth(place.name + " (Total # of Sightings = " + place.sightingCount + ")"))/2,5);
       Sighting newSighting = sightings.get(sightingSList.selectedIndex-1);   
     fill(textColor);  
       text(newSighting.description,230,25, w - 260,80);
    }
  }
}

