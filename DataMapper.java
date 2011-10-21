import de.bezier.data.sql.*;
import processing.core.PApplet;
import java.sql.ResultSetMetaData;
public abstract class DataMapper {
  public static SQLite db;
  public static PApplet parent;
  public static void connect(PApplet parent){
    DataMapper.parent = parent;
    db = new SQLite(parent, "ufo.db");
    db.connect();
  }
  
  public static boolean columnExists(ResultSetMetaData meta, String name){
    try{
      for (int i = 1; i <=  meta.getColumnCount(); ++i)
        if(meta.getColumnName(i).equals(name))
          return true;
    }catch(Exception e){
      e.printStackTrace();
    }
    return false; 
  }
}
