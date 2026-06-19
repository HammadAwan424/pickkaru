// IGNORE THIS RIGHT NOW

// import 'package:flutter/foundation.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// import 'models/poll.dart';
// import 'models/enums.dart';
// import 'driver/providers/driver_provider.dart';
// import 'driver/poll/poll_service.dart';
// import 'student/overrides/override_service.dart';
// import 'core/auth/auth_provider.dart';
// import 'student/providers/student_provider.dart';

// // ── Daily Board Provider ──

// @immutable
// class DailyBoardArgs {
//   final String driverId;
//   final PollPeriod period;
//   final DateTime date;

//   const DailyBoardArgs({
//     required this.driverId,
//     required this.period,
//     required this.date,
//   });

//   @override
//   bool operator ==(Object other) {
//     return other is DailyBoardArgs &&
//         other.driverId == driverId &&
//         other.period == period &&
//         other.date.year == date.year &&
//         other.date.month == date.month &&
//         other.date.day == date.day;
//   }

//   @override
//   int get hashCode => Object.hash(
//         driverId,
//         period,
//         date.year,
//         date.month,
//         date.day,
//       );
// }






// // ── Poll Actions ──

// final pollActionsProvider = Provider<PollActions>((ref) {
//   return PollActions(ref);
// });

// class PollActions {
//   PollActions(this._ref);

//   final Ref _ref;

//   Future<void> startRide({
//     required String driverId,
//     required PollPeriod period,
//   }) {
//     return _ref.read(pollServiceProvider).startRide(
//           driverId: driverId,
//           period: period,
//         );
//   }

//   Future<void> completeRide({
//     required String driverId,
//     required PollPeriod period,
//     required DateTime date,
//   }) {
//     return _ref.read(pollServiceProvider).completeRide(
//           driverId: driverId,
//           period: period,
//           date: date,
//         );
//   }

//   Future<void> initializeDailyBoard({
//     required String driverId,
//     required PollPeriod period,
//     required DateTime date,
//   }) {
//     return _ref.read(pollServiceProvider).initializeDailyBoard(
//           driverId: driverId,
//           period: period,
//           date: date,
//         );
//   }

//   Future<void> updateStudentBoarded({
//     required String driverId,
//     required PollPeriod period,
//     required String studentId,
//     required DateTime date,
//     required bool boarded,
//   }) {
//     return _ref.read(pollServiceProvider).updateStudentBoarded(
//           driverId: driverId,
//           period: period,
//           studentId: studentId,
//           date: date,
//           boarded: boarded,
//         );
//   }

//   Future<void> updateStudentResponse({
//     required String driverId,
//     required PollPeriod period,
//     required String studentId,
//     required DateTime date,
//     bool? answer,
//     bool updateAnswer = true,
//     String? checkpoint,
//     bool updateCheckpoint = false,
//   }) {
//     return _ref.read(pollServiceProvider).updateStudentResponse(
//           driverId: driverId,
//           period: period,
//           studentId: studentId,
//           date: date,
//           answer: answer,
//           updateAnswer: updateAnswer,
//           checkpoint: checkpoint,
//           updateCheckpoint: updateCheckpoint,
//         );
//   }

//   Future<void> markStudentBoarded({
//     required String driverId,
//     required PollPeriod period,
//     required String studentId,
//     required DateTime date,
//   }) {
//     return _ref.read(pollServiceProvider).updateStudentBoarded(
//           driverId: driverId,
//           period: period,
//           studentId: studentId,
//           date: date,
//           boarded: true,
//         );
//   }

//   Future<String?> markNextStudentApproaching({
//     required String driverId,
//     required PollPeriod period,
//     required DateTime date,
//   }) async {
//     final driver = _ref.read(driverProvider(driverId)).value;
//     if (driver == null) {
//       throw StateError('Driver is not loaded.');
//     }

//     final poll = _readDailyBoard(
//       driverId: driverId,
//       period: period,
//       date: date,
//     );

//     final approachingStudentIds = poll.approachingStudentIds.toSet();
//     for (final studentId in driver.assignedStudents) {
//       final response = poll.responses[studentId];
//       final votedNo = response?.answer == false;
//       final boarded = response?.boarded == true;
//       final approaching = approachingStudentIds.contains(studentId);

//       if (!votedNo && !boarded && !approaching) {
//         await _ref.read(pollServiceProvider).addApproachingStudent(
//               driverId: driverId,
//               period: period,
//               studentId: studentId,
//               date: date,
//             );
//         return studentId;
//       }
//     }

//     return null;
//   }



//   Future<void> initializeDailyPoll({
//     required String driverId,
//     required PollPeriod period,
//     required String date,
//     required Map<String, bool> studentDefaults,
//     required Map<String, String?> studentDefaultCheckpoints,
//     required Map<String, PrivateOverride> todayOverrides,
//   }) {
//     return _ref.read(pollServiceProvider).initializeDailyPoll(
//           driverId: driverId,
//           period: period,
//           date: date,
//           studentDefaults: studentDefaults,
//           studentDefaultCheckpoints: studentDefaultCheckpoints,
//           todayOverrides: todayOverrides,
//         );
//   }

//   Poll _readDailyBoard({
//     required String driverId,
//     required PollPeriod period,
//     required DateTime date,
//   }) {
//     final poll = _ref
//         .read(dailyBoardProvider(DailyBoardArgs(
//           driverId: driverId,
//           period: period,
//           date: date,
//         )))
//         .value;

//     if (poll == null) {
//       throw StateError('Daily board is not loaded.');
//     }

//     return poll;
//   }
// }
