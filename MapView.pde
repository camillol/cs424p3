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
    imageMode(CORNER);  // modestmaps needs this
    mmap.draw();
    smooth();
    noStroke();

    Point2f p = mmap.locationPoint(new Location(41.881944, -87.627778));
    println(p);
    println(mmap.pointLocation(p));
    image(airplaneImage,p.x,p.y);
  }

  boolean mouseDragged(float px, float py)
  {
    mmap.mouseDragged();
    return true;
  }
}

