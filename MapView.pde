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
    imageMode(CORNER);  // modestmaps needs this - I sent a patch, but who knows when it'll be committed
    mmap.draw();
    smooth();
    noStroke();

    Point2f p = mmap.locationPoint(new Location(41.881944, -87.627778));
    println(p);
    println(mmap.pointLocation(p));
    image(airplaneImage,p.x,p.y);
  }

  boolean contentMouseWheel(float lx, float ly, int delta)
  {
    float sc = 1.0;
    if (delta < 0) {
      sc = 1.05;
    }
    else if (delta > 0) {
      sc = 1.0/1.05;
    }
    float mx = lx - w/2;
    float my = ly - h/2;
    mmap.tx -= mx/mmap.sc;
    mmap.ty -= my/mmap.sc;
    mmap.sc *= sc;
    mmap.tx += mx/mmap.sc;
    mmap.ty += my/mmap.sc;

    return true;
  }

  boolean mouseDragged(float px, float py)
  {
    mmap.mouseDragged();
    return true;
  }
}

