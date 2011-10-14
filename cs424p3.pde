View rootView;

HBar hbar;
HBar hbar2;
Animator anim;

void setup()
{
  size(1024, 768);
  setupG2D();
  
  smooth();
  background(50);
  
  rootView = new View(0, 0, width, height);
  
  hbar = new HBar(100,100,200,20);
  rootView.subviews.add(hbar);

  hbar2 = new HBar(100,200,200,20);
  rootView.subviews.add(hbar2);
  
  anim = new Animator(0);
}

void draw()
{
  background(50);    /* seems to be needed to actually clear the frame */
  Animator.updateAll();
  
  anim.target(hbar.level);
  hbar2.level = anim.value;
  
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

