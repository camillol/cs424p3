static class Animator {
  static List<Animator> allAnimators;  /* looks like we can use generics after al */
  
  final float attraction = 0.2;
  final float reached_threshold = 10e-3;
  
  float value;
  float target;
  float oldtarget;
  boolean targeting;
  float velocity;
  
  Animator()
  {
    if (allAnimators == null) allAnimators = new ArrayList();
    allAnimators.add(this);
    targeting = false;
  }
  
  Animator(float value_)
  {
    this();
    value = value_;
  }
  
  void close()
  {
    allAnimators.remove(this);
  }
  
  void set(float value_)
  {
    value = value_;
  }
  
  void target(float target_)
  {
    if (target_ != target) oldtarget = target;
    target = target_;
    targeting = (target != value);
  }
  
  void update()
  {
    if (!targeting) return;
    
    float a = attraction * (target - value);
    velocity = (velocity + a) / 2;
    value += velocity;
    
    if (abs(target - value) < reached_threshold) {
      value = target;
      targeting = false;
      velocity = 0;
    }
  }
  
  static void updateAll()
  {
    if (allAnimators != null) for (Animator animator : allAnimators) animator.update();
  }
}

