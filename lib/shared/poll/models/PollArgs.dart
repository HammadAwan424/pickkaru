import 'package:equatable/equatable.dart';
import 'package:pickkaru/shared/poll/models/PollPeriod.dart';

class PollArgs extends Equatable {
  final String driverId;
  final PollPeriod period;

  const PollArgs({
    required this.driverId,
    required this.period,
  });

  String get pollConfigPath => 'polls/${driverId}_${period.firestoreId}';
  String get responsesPath => '$pollConfigPath/responses';

  @override
  List<Object?> get props => [driverId, period];
}