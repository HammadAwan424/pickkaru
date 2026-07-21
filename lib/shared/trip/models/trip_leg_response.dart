import 'trip_enums.dart';
import 'core_student_leg_data.dart';

typedef PickupStudentResponse = ({CoreStudentLegData coreData, bool boarded});
typedef DropoffStudentResponse = ({CoreStudentLegData coreData, bool droppedOff});

sealed class TripLegResponse {
  final String id;
  final LegType legType;
  final TripLegDirection leg;

  const TripLegResponse({
    required this.id,
    required this.legType,
    required this.leg,
  });

  Map<String, dynamic> _commonMap() => {
    'legType': legType.name,
    'leg': leg.name,
  };

  factory TripLegResponse.fromMap(Map<String, dynamic> map, String id) {
    final direction = TripLegDirection.fromFirestore(map['leg'] as String);
    return switch (direction) {
      TripLegDirection.pickup => PickupTripLegResponse.fromMap(map, id),
      TripLegDirection.dropoff => DropoffTripLegResponse.fromMap(map, id),
    };
  }

  Map<String, dynamic> toMap();
}

class PickupTripLegResponse extends TripLegResponse {
  final Map<String, PickupStudentResponse> students;

  const PickupTripLegResponse({
    required super.id,
    required super.legType,
    required this.students,
  }) : super(leg: TripLegDirection.pickup);

  factory PickupTripLegResponse.fromMap(Map<String, dynamic> map, String id) {
    final legType = LegType.fromFirestore(map['legType'] as String);
    final rawStudents = map['students'] as Map<String, dynamic>? ?? {};

    return PickupTripLegResponse(
      id: id,
      legType: legType,
      students: rawStudents.map((k, v) {
        final studentMap = v as Map<String, dynamic>;
        return MapEntry(
          k,
          (
            coreData: CoreStudentLegData.fromMap(studentMap, legType),
            boarded: studentMap['boarded'] as bool? ?? false,
          ),
        );
      }),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = _commonMap();
    map['students'] = students.map((k, v) {
      return MapEntry(k, {
        ...v.coreData.toMap(),
        'boarded': v.boarded,
      });
    });
    return map;
  }
}

class DropoffTripLegResponse extends TripLegResponse {
  final Map<String, DropoffStudentResponse> students;

  const DropoffTripLegResponse({
    required super.id,
    required super.legType,
    required this.students,
  }) : super(leg: TripLegDirection.dropoff);

  factory DropoffTripLegResponse.fromMap(Map<String, dynamic> map, String id) {
    final legType = LegType.fromFirestore(map['legType'] as String);
    final rawStudents = map['students'] as Map<String, dynamic>? ?? {};

    return DropoffTripLegResponse(
      id: id,
      legType: legType,
      students: rawStudents.map((k, v) {
        final studentMap = v as Map<String, dynamic>;
        return MapEntry(
          k,
          (
            coreData: CoreStudentLegData.fromMap(studentMap, legType),
            droppedOff: studentMap['droppedOff'] as bool? ?? false,
          ),
        );
      }),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = _commonMap();
    map['students'] = students.map((k, v) {
      return MapEntry(k, {
        ...v.coreData.toMap(),
        'droppedOff': v.droppedOff,
      });
    });
    return map;
  }
}
