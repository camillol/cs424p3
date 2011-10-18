color checkboxColor = 255;

class Checkbox extends View {
  boolean value;
  color ckbColor = -1;
  String imageName = "";
  PImage icon;
  String title;
  
  Checkbox(float x_, float y_, float w_, float h_,String text_, String image_)
  {
    super(x_, y_, w_, h_);
    value = false;
    imageName = image_;
    icon = loadImage(imageName);
    title = text_;
  }
  
  Checkbox(float x_, float y_, float w_, float h_, String text_,color color_)
  {
    super(x_, y_, w_, h_);
    value = false;
    ckbColor = color_;
    title = text_;
  }
  
  Checkbox(float x_, float y_, float w_, float h_, String text_)
  {
    super(x_, y_, w_, h_);
    value = false;
    title = text_;
  }
  
  void drawContent()
  {
    strokeWeight(1);

    if (value){
      stroke((ckbColor== -1)?checkboxColor:ckbColor);
      noFill();
      rect(0, 0, w, h);
      fill((ckbColor== -1)?checkboxColor:ckbColor);
      rect(2, 2, w-4, h-4);
    }
    else{
      stroke((ckbColor== -1)?checkboxColor:ckbColor);
      noFill();
      rect(0, 0, w, h);
    }
   fill(textColor);
   textFont(font,normalFontSize);
   textAlign(LEFT,TOP);
   if (imageName.length() > 0){
     text(title, w + w + 10, 0);
     imageMode(CORNERS);
     image(icon, w + 5, 0,w+5+w,h);
     imageMode(CENTER);
     
   }
   else{
     text(title, w + 5, 0);
   }
    
  }
  
  boolean contentPressed(float lx, float ly)
  {
    value = !value;
    return true;
  }
  
  void setValue(Boolean _value){
    value = _value;
  }
}
