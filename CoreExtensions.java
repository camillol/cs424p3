import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.Enumeration;
import java.util.Iterator;
import java.util.Vector;
import processing.core.*;
class CoreExtensions {
  public static PApplet applet;
    // FROM: http://progcookbook.blogspot.com/2006/02/text-wrapping-function-for-java.html
    static String[] wrapText(String text, int len) {
        // return empty array for null text
        if (text == null) {
            return new String[] {};
        }
        // return text if len is zero or less
        if (len <= 0) {
            return new String[] { text };
        }
        // return text if less than length
        if (text.length() <= len) {
            return new String[] { text };
        }
        char[]         chars = text.toCharArray();
        Vector<String> lines = new Vector<String>();
        StringBuffer   line  = new StringBuffer();
        StringBuffer   word  = new StringBuffer();
        for (int i = 0; i < chars.length; i++) {
            word.append(chars[i]);
            if (chars[i] == ' ') {
                if ((line.length() + word.length()) > len) {
                    lines.add(line.toString());
                    line.delete(0, line.length());
                }
                line.append(word);
                word.delete(0, word.length());
            }
        }
        // handle any extra chars in current word
        if (word.length() > 0) {
            if ((line.length() + word.length()) > len) {
                lines.add(line.toString());
                line.delete(0, line.length());
            }
            line.append(word);
        }
        // handle extra line
        if (line.length() > 0) {
            lines.add(line.toString());
        }
        String[] ret = new String[lines.size()];
        int      c   = 0;    // counter
        for (Enumeration<String> e = lines.elements(); e.hasMoreElements(); c++) {
            ret[c] = (String) e.nextElement();
        }
        return ret;
    }
    public static boolean between(int a, int l, int b) {
        return (a >= l) && (a <= b);
    }
    // http://www.java2s.com/Code/JavaAPI/java.util/ArrayListiterator.htm
    public static String join(Collection s, String delimiter) {
        StringBuffer buffer = new StringBuffer();
        Iterator     iter   = s.iterator();
        while (iter.hasNext()) {
            buffer.append(iter.next());
            if (iter.hasNext()) {
                buffer.append(delimiter);
            }
        }
        return buffer.toString();
    }
    public static <T> ArrayList<T> filter(ArrayList<T> target, Predicate<T> predicate) {
    ArrayList<T> result = new ArrayList<T>();
    for (T element: target) {
        if (predicate.apply(element)) {
            result.add(element);
        }
    }
    return result;
	}
}

interface Predicate<T> {boolean apply(T type);}
	
