import java.awt.Graphics2D;
import java.awt.Shape;
import java.util.jar.*;

/* timing utilities */
float lastTime;

float stopWatch()
{
  float x = lastTime;
  lastTime = millis();
  return lastTime - x;
}

/* graphics utilities */
Graphics2D g2;
Shape[] clipStack;
int clipIdx;

void setupG2D()
{
  g2 = ((PGraphicsJava2D)g).g2;
  clipStack = new Shape[32];
  clipIdx = 0;
}

/* I can't believe this is not part of the Processing API! */
void clipRect(int x, int y, int w, int h)
{
  g2.clipRect(x, y, w, h);
}

void clipRect(float x, float y, float w, float h)
{
  g2.clipRect((int)x, (int)y, (int)w, (int)h);
}

void noClip()
{
  g2.setClip(null);
}

void pushClip()
{
  clipStack[clipIdx++] = g2.getClip();
}

void popClip()
{
  g2.setClip(clipStack[--clipIdx]);
  clipStack[clipIdx] = null;
}


/* about paths:
  inside IDE:  sketchPath:    /Users/camillo/UIC/CS424 visualization/p3/cs424p3
               dataPath(""):  /Users/camillo/UIC/CS424 visualization/p3/cs424p3/data/  

  application: sketchPath:    /Users/camillo/UIC/CS424 visualization/p3/cs424p3/application.macosx
               dataPath(""):  /Users/camillo/UIC/CS424 visualization/p3/cs424p3/application.macosx/data/

  applet:      sketchPath:    null
               dataPath(""):  null
*/

/* data utilities */
String[] listDataSubdir(String subdir)
{
  String[] items = null;
  /* dataPath does not work for application, either. it's only useful in the IDE */
/*  if (sketchPath != null) {
    println(dataPath(subdir));
    File dir = new File(dataPath(subdir));
    items = dir.list();
    println(items);
  } else */
  
  ClassLoader cl = getClass().getClassLoader();
  URL url = cl.getResource("META-INF/MANIFEST.MF");  /* just a random file that's known to exist */
  if (url == null) {  /* running in IDE */
    File dir = new File(dataPath(subdir));
    items = dir.list();
  } else try {  /* applet OR application */
    JarURLConnection conn = (JarURLConnection)url.openConnection();
    JarFile jar = conn.getJarFile();
    Enumeration e = jar.entries();
    String re = "data/" + subdir + "/(.*)";
    /* note that jars don't have directory entries, or at least Processing's don't */
    Set<String> itemSet = new LinkedHashSet<String>();
    while (e.hasMoreElements()) {
      JarEntry entry = (JarEntry)e.nextElement();
      String[] groups = match(entry.getName(), re);
      if (groups == null) continue;
      String[] comps = split(groups[1], "/");
      itemSet.add(comps[0]);
    }
    /*Iterator it = itemSet.iterator();
    while (it.hasNext()) {
      println(it.next());
    }*/
    items = (String[])itemSet.toArray(new String[0]);
  } catch (IOException e) {
    println(e);
  }
  return items;
}

boolean dataFileExists(String path)
{
  InputStream is = createInput(path);
  if (is == null) return false;
  else {
    try { is.close(); }
    catch (IOException e) {}
    return true;
  }
}

