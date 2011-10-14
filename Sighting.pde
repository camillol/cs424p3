/* a sighting is owned by a place */
class Sighting {
  String description;
  SightingType type;
  float airportDist;
  float militaryDist;
  Date localTime;
}


class SightingType {
  PImage icon;
  color colr;
  String name;
}


class Place {
  int type;  /* city, airport, military base */
  Location loc;
  String name;
}


