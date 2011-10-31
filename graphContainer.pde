class GraphContainer extends View {
  
  float CHECKBOX_X ;
  float CHECKBOX_Y ;
  float CHECKBOX_W ;
  float CHECKBOX_H ;
  
  String title;
  Map<SightingType, Checkbox> typeCheckboxGraph;
  
  Animator graphAnimator;
  
  GraphContainer(float x_, float y_, float w_, float h_)
  {
    super(x_, y_, w_, h_);
    textFont(font,normalFontSize);
      
    graphView = new GraphView(0, 0, w - 160, h-5);
    this.subviews.add(graphView);
    
    graphModeList = new ListBox(w - 160, 0, 155, 160, graphView.modesDataSource());
    this.subviews.add(graphModeList);
    
    CHECKBOX_X = w - 160;
    CHECKBOX_Y = 220;
    CHECKBOX_W = 157;
    CHECKBOX_H = 150;  
    int i = 0;
    typeCheckboxGraph = new HashMap<SightingType, Checkbox>();
    
    for (SightingType st : sightingTypeMap.values()) {
      int y_delta = (i % 7) * 20;
      Checkbox cb = new Checkbox(CHECKBOX_X + 10,CHECKBOX_Y + 10 + y_delta,12,12, st.name, st.icon,st.colr);
      subviews.add(cb);
      typeCheckboxGraph.put(st,cb);
      i++;
    }
   
    graphAnimator = new Animator(graphView.h);  
  }
  
  void updateValuesGraph(){
      for (Entry<SightingType, Checkbox> entryG : typeCheckboxGraph.entrySet()) {
         for (Entry<SightingType, Checkbox> entryM : typeCheckboxMap.entrySet()) {
              if (entryM.getValue().title.equals(entryG.getValue().title)){
                  entryG.getValue().value = entryM.getValue().value;
              }
         }
      }
  }  
  
  void updateValuesMap(){
      for (Entry<SightingType, Checkbox> entryG : typeCheckboxGraph.entrySet()) {
         for (Entry<SightingType, Checkbox> entryM : typeCheckboxMap.entrySet()) {
              if (entryM.getValue().title.equals(entryG.getValue().title)){
                   entryM.getValue().value = entryG.getValue().value;
              }
         }
      }
  } 

   void drawContent()
  {
    textSize(normalFontSize);
    fill(viewBackgroundColor);
    stroke(viewBackgroundColor);
    rect(0,0, w, h);
    fill(textColor);
    textAlign(LEFT,TOP);
    title = " Type of UFO ";
    text(title,CHECKBOX_X,CHECKBOX_Y - 5);
    stroke(textColor);
    
    line(CHECKBOX_X + textWidth(title)+5,CHECKBOX_Y,CHECKBOX_X+CHECKBOX_W,CHECKBOX_Y);
    line(CHECKBOX_X,CHECKBOX_Y,CHECKBOX_X,CHECKBOX_H + CHECKBOX_Y);
    line(CHECKBOX_X,CHECKBOX_H + CHECKBOX_Y,CHECKBOX_X+CHECKBOX_W,CHECKBOX_H + CHECKBOX_Y);
    line(CHECKBOX_X+CHECKBOX_W,CHECKBOX_Y,CHECKBOX_X+CHECKBOX_W,CHECKBOX_H + CHECKBOX_Y);
     
     graphView.h = graphAnimator.value;      
  }
  
}

