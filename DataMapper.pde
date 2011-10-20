
public abstract class DataMapper {
  public static SQLite db;
  public static PApplet parent;
  public static void connect(PApplet parent){
    DataMapper.parent = parent;
    db = new SQLite(parent, "ufo.db");
    db.connect();
  }
}
