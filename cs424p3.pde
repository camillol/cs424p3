View rootView;

void setup()
{
  size(1024, 768);
  setupG2D();
  
  smooth();
  background(0);
  
  rootView = new View(0, 0, width, height);
}

void draw()
{
  background(0);    /* seems to be needed to actually clear the frame */
  Animator.updateAll();
  
  rootView.draw();
}

void mousePressed()
{
  rootView.mousePressed(mouseX, mouseY);
}

void mouseDragged()
{
  rootView.mouseDragged(mouseX, mouseY);
}

void mouseClicked()
{
  rootView.mouseClicked(mouseX, mouseY);
}

