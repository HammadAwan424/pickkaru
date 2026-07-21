enum LegType {
  student,
  driver,
  fixed;

  String get firestoreValue => name;
  static LegType fromFirestore(String value) => LegType.values.byName(value);
}

enum TripLegDirection {
  pickup,
  dropoff;

  String get firestoreValue => name;
  static TripLegDirection fromFirestore(String value) => TripLegDirection.values.byName(value);
}
