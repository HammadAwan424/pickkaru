import 'trip_enums.dart';
import 'core_student_leg_data.dart';

typedef PendingData = ({CoreStudentLegData coreData, String effectiveFrom});

class ConfigStudentEntry {
  final CoreStudentLegData active;
  final PendingData pending;

  ConfigStudentEntry._({required this.active, required this.pending});

  factory ConfigStudentEntry.fromMap(Map<String, dynamic> map, LegType legType) {
    final activeMap = map['active'] as Map<String, dynamic>? ?? {};
    final pendingMap = map['pending'] as Map<String, dynamic>? ?? {};
    return ConfigStudentEntry._(
      active: CoreStudentLegData.fromMap(activeMap, legType),
      pending: (
        coreData: CoreStudentLegData.fromMap(pendingMap, legType),
        effectiveFrom: pendingMap['effectiveFrom'] as String? ?? '',
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'active': active.toMap(),
    'pending': {
      ...pending.coreData.toMap(),
      'effectiveFrom': pending.effectiveFrom,
    },
  };
}

class TripLegConfig {
  final String id;
  final LegType legType;
  final TripLegDirection leg;
  final String configType;
  final Map<String, ConfigStudentEntry> students;

  const TripLegConfig({
    required this.id,
    required this.legType,
    required this.leg,
    required this.configType,
    required this.students,
  });

  factory TripLegConfig.fromMap(Map<String, dynamic> map, String id) {
    final legType = LegType.fromFirestore(map['legType'] as String);
    final rawStudents = map['students'] as Map<String, dynamic>? ?? {};

    return TripLegConfig(
      id: id,
      legType: legType,
      leg: TripLegDirection.fromFirestore(map['leg'] as String),
      configType: map['configType'] as String? ?? 'defaults',
      students: rawStudents.map(
        (k, v) => MapEntry(k, ConfigStudentEntry.fromMap(v as Map<String, dynamic>, legType)),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'legType': legType.name,
      'leg': leg.name,
      'configType': configType,
      'students': students.map((k, v) => MapEntry(k, v.toMap())),
    };
  }
}
