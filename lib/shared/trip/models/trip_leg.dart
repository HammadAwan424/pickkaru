import 'trip_enums.dart';

class LocationPoint {
  final String name;
  final double lat;
  final double lng;

  const LocationPoint({required this.name, required this.lat, required this.lng});

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      name: map['name'] as String,
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'lat': lat,
    'lng': lng,
  };
}

sealed class TripLeg {
  final LegType legType;
  const TripLeg({required this.legType});

  Map<String, dynamic> _commonMap() => {
    'legType': legType.name,
  };

  factory TripLeg.fromMap(Map<String, dynamic> map) {
    final type = LegType.fromFirestore(map['legType'] as String);
    return switch (type) {
      LegType.fixed => FixedTripLeg.fromMap(map),
      LegType.driver => DriverTripLeg.fromMap(map),
      LegType.student => StudentTripLeg.fromMap(map),
    };
  }
  
  Map<String, dynamic> toMap();
}

class FixedTripLeg extends TripLeg {
  final LocationPoint destination;

  const FixedTripLeg({required this.destination}) : super(legType: LegType.fixed);

  factory FixedTripLeg.fromMap(Map<String, dynamic> map) {
    return FixedTripLeg(destination: LocationPoint.fromMap(map['destination'] as Map<String, dynamic>));
  }

  @override
  Map<String, dynamic> toMap() => {
    ..._commonMap(),
    'destination': destination.toMap(),
  };
}

class DriverTripLeg extends TripLeg {
  final String checkpointSetId;

  const DriverTripLeg({required this.checkpointSetId}) : super(legType: LegType.driver);

  factory DriverTripLeg.fromMap(Map<String, dynamic> map) {
    return DriverTripLeg(checkpointSetId: map['checkpointSetId'] as String);
  }

  @override
  Map<String, dynamic> toMap() => {
    ..._commonMap(),
    'checkpointSetId': checkpointSetId,
  };
}

class StudentTripLeg extends TripLeg {
  final String checkpointSetId;

  const StudentTripLeg({required this.checkpointSetId}) : super(legType: LegType.student);

  factory StudentTripLeg.fromMap(Map<String, dynamic> map) {
    return StudentTripLeg(checkpointSetId: map['checkpointSetId'] as String);
  }

  @override
  Map<String, dynamic> toMap() => {
    ..._commonMap(),
    'checkpointSetId': checkpointSetId,
  };
}
