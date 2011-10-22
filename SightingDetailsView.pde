class SightingDetailsView extends View {

  float heightView ;
  boolean showView = false;
  Sighting _sighting;
    
  SightingDetailsView(float x_, float y_, float w_, float h_)
  {
    super(x_, y_, w_, h_);
  
  }
  
   void drawContent()
  {
    if (showView){
      fill(viewBackgroundColor,220);
      stroke(viewBackgroundColor,220);
      rect(0,0, w, h);
      text(_sighting.description_short,5,5);
    }
        
  }
}

