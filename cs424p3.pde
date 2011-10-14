View rootView;

void setup()
{
  size(1024, 768);
  setupG2D();
  
  smooth();
  background(50);
  
  rootView = new View(0, 0, width, height);
  
  View hbar = new HBar(100,100,200,20);
  rootView.subviews.add(hbar);

  View hbar2 = new HBar(100,200,200,20);
  rootView.subviews.add(hbar2);
}

void draw()
{
  background(50);    /* seems to be needed to actually clear the frame */
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

