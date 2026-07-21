import 'trip_enums.dart';

sealed class CoreStudentLegData {
  final bool vote;

  const CoreStudentLegData({required this.vote});

  Map<String, dynamic> _commonMap() => {
    'vote': vote,
  };

  factory CoreStudentLegData.fromMap(Map<String, dynamic> map, LegType legType) {
    return switch (legType) {
      LegType.student || LegType.fixed => SimpleStudentLegData.fromMap(map),
      LegType.driver => DriverStudentLegData.fromMap(map),
    };
  }

  Map<String, dynamic> toMap();
}

class SimpleStudentLegData extends CoreStudentLegData {
  const SimpleStudentLegData({required super.vote});

  factory SimpleStudentLegData.fromMap(Map<String, dynamic> map) {
    return SimpleStudentLegData(vote: map['vote'] as bool? ?? false);
  }

  @override
  Map<String, dynamic> toMap() => _commonMap();
}

class DriverStudentLegData extends CoreStudentLegData {
  final String checkpoint;

  const DriverStudentLegData({required super.vote, required this.checkpoint});

  factory DriverStudentLegData.fromMap(Map<String, dynamic> map) {
    return DriverStudentLegData(
      vote: map['vote'] as bool? ?? false,
      checkpoint: map['checkpoint'] as String,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
    ..._commonMap(),
    'checkpoint': checkpoint,
  };
}
