class TripExecutionState {
  final DateTime startedAt;
  final DateTime? completedAt;
  final String startedBy;

  const TripExecutionState({
    required this.startedAt,
    this.completedAt,
    required this.startedBy,
  });

  factory TripExecutionState.fromMap(Map<String, dynamic> map) {
    return TripExecutionState(
      startedAt: DateTime.parse(map['startedAt'] as String),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt'] as String) : null,
      startedBy: map['startedBy'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'startedAt': startedAt.toIso8601String(),
    if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    'startedBy': startedBy,
  };
}

class TripRunDay {
  final String dateString;
  final Map<String, TripExecutionState> trips;

  const TripRunDay({
    required this.dateString,
    required this.trips,
  });

  factory TripRunDay.fromMap(Map<String, dynamic> map, String id) {
    final rawTrips = map['trips'] as Map<String, dynamic>? ?? {};
    return TripRunDay(
      dateString: id,
      trips: rawTrips.map(
        (k, v) => MapEntry(k, TripExecutionState.fromMap(v as Map<String, dynamic>)),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trips': trips.map((k, v) => MapEntry(k, v.toMap())),
    };
  }
}
