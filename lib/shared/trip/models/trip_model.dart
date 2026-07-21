import 'trip_leg.dart';

class TripModel {
  final String id;
  final String name;
  final int sequence;
  final bool disabled;
  final TripLeg pickup;
  final TripLeg dropoff;
  final List<String> participants;

  const TripModel({
    required this.id,
    required this.name,
    required this.sequence,
    required this.disabled,
    required this.pickup,
    required this.dropoff,
    required this.participants,
  });

  factory TripModel.fromMap(Map<String, dynamic> map, String id) {
    return TripModel(
      id: id,
      name: map['name'] as String? ?? '',
      sequence: map['sequence'] as int? ?? 0,
      disabled: map['disabled'] as bool? ?? false,
      pickup: TripLeg.fromMap(map['pickup'] as Map<String, dynamic>),
      dropoff: TripLeg.fromMap(map['dropoff'] as Map<String, dynamic>),
      participants: List<String>.from(map['participants'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'sequence': sequence,
    'disabled': disabled,
    'pickup': pickup.toMap(),
    'dropoff': dropoff.toMap(),
    'participants': participants,
  };
}
