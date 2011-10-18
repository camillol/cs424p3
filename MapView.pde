import processing.opengl.*;
import com.modestmaps.*;
import com.modestmaps.core.*;
import com.modestmaps.geo.*;
import com.modestmaps.providers.*;

class MapView extends View {
  InteractiveMap mmap;
  
  MapView(float x_, float y_, float w_, float h_)
  {
    super(x_, y_, w_, h_);
    mmap = new InteractiveMap(papplet, new Microsoft.HybridProvider(), w, h);
    mmap.setCenterZoom(new Location(45.536382, -106.644490), 4);
     airplaneImage.resize(20,20);
     
  }
  
  void drawContent()
  {
    mmap.draw();
    smooth();
    imageMode(CENTER);
    noStroke();
    fill(airportAreaColor,40);
    ellipse(300,250,80,80);
    image(airplaneImage,300,250);
  }
}

