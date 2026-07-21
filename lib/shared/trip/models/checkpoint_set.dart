import 'trip_enums.dart';

class Checkpoint {
  final String name;
  final double lat;
  final double lng;
  final int order;

  const Checkpoint({
    required this.name,
    required this.lat,
    required this.lng,
    required this.order,
  });

  factory Checkpoint.fromMap(Map<String, dynamic> map) {
    return Checkpoint(
      name: map['name'] as String? ?? '',
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'lat': lat,
    'lng': lng,
    'order': order,
  };
}

class CheckpointSet {
  final String id;
  final LegType legType;
  final Map<String, Checkpoint> checkpoints;
  final List<String> order;

  const CheckpointSet({
    required this.id,
    required this.legType,
    required this.checkpoints,
    required this.order,
  });

  factory CheckpointSet.fromMap(Map<String, dynamic> map, String id) {
    final rawCheckpoints = map['checkpoints'] as Map<String, dynamic>? ?? {};
    return CheckpointSet(
      id: id,
      legType: LegType.fromFirestore(map['legType'] as String),
      checkpoints: rawCheckpoints.map(
        (k, v) => MapEntry(k, Checkpoint.fromMap(v as Map<String, dynamic>)),
      ),
      order: List<String>.from(map['order'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'legType': legType.name,
    'checkpoints': checkpoints.map((k, v) => MapEntry(k, v.toMap())),
    'order': order,
  };
}
