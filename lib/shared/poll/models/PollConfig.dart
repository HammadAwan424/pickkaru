import 'package:pickkaru/shared/poll/models/PollPeriod.dart';

enum PollStatus {
  uninitiated,
  active,
  completed;

  String get firestoreValue => name;
  static PollStatus fromFirestore(String value) {
    return PollStatus.values.byName(value);
  }
}

class PollConfig {
  final PollPeriod period;
  final PollStatus status;
  final List<String>? checkpoints;

  const PollConfig({
    required this.period,
    required this.status,
    required this.checkpoints,
  });

  factory PollConfig.fromMap(Map<String, dynamic> map, {PollPeriod? fallbackPeriod}) {
    final periodValue = map['period'] as String?;
    final period = periodValue == null
        ? fallbackPeriod ?? PollPeriod.morning
        : PollPeriodFirestore.fromFirestore(periodValue);

    final statusValue = map['status'] as String?;
    final status = statusValue == null
        ? PollStatus.uninitiated
        : PollStatus.fromFirestore(statusValue);

    return PollConfig(
      period: period,
      status: status,
      checkpoints: map['checkpoints'] == null
          ? null
          : List<String>.from(map['checkpoints'] as List),
    );
  }

  factory PollConfig.empty(PollPeriod period) {
    return PollConfig(
      period: period,
      status: PollStatus.uninitiated,
      checkpoints: period == PollPeriod.evening ? <String>[] : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'period': period.firestoreId,
      'status': status.firestoreValue,
      'checkpoints': checkpoints,
    };
  }
}