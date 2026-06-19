import 'package:flutter_test/flutter_test.dart';
import 'package:pickkaru/driver/driver_core/driver.dart';
import 'package:pickkaru/shared/poll/models/DailyPollBoard.dart';

void main() {
  group('Model Tests', () {
    test('DriverModel parsing works and includes timeZoneName', () {
      final map = {
        'assignedStudents': ['student1', 'student2'],
        'refreshTime': '18:30',
        'timeZoneName': 'Asia/Karachi',
      };
      
      final driver = DriverModel.fromMap('driver123', map);
      
      expect(driver.uid, 'driver123');
      expect(driver.assignedStudents, ['student1', 'student2']);
      expect(driver.refreshTime, '18:30');
      expect(driver.timeZoneName, 'Asia/Karachi');
      
      final outMap = driver.toMap();
      expect(outMap['timeZoneName'], 'Asia/Karachi');
    });

    test('PrivateOverride parsing works', () {
      final map = {
        'morning': {'answer': true},
        'evening': {'answer': false, 'checkpoint': 'Stop A'},
      };

      final override = PrivateOverride.fromMap(map);

      expect(override.morningAnswer, true);
      expect(override.eveningAnswer, false);
      expect(override.eveningCheckpoint, 'Stop A');

      final outMap = override.toMap();
      expect(outMap['morning']['answer'], true);
      expect(outMap['evening']['answer'], false);
      expect(outMap['evening']['checkpoint'], 'Stop A');
    });
  });
}
