import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../student_core/services/student_service.dart';
import 'package:pickkaru/core/auth/auth_provider.dart';
import 'package:pickkaru/student/student_core/providers/student_provider.dart';
import 'package:pickkaru/driver/driver_core/providers/driver_provider.dart';

class StudentDriverAssignmentPage extends ConsumerStatefulWidget {
  final String studentUid;
  const StudentDriverAssignmentPage({super.key, required this.studentUid});

  @override
  ConsumerState<StudentDriverAssignmentPage> createState() =>
      _StudentDriverAssignmentPageState();
}

class _StudentDriverAssignmentPageState
    extends ConsumerState<StudentDriverAssignmentPage> {
  final _driverIdCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _driverIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _assignDriver() async {
    final driverId = _driverIdCtrl.text.trim();
    if (driverId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter the assigned driver ID')));
      return;
    }

    setState(() => _loading = true);
    try {
      final user = ref.read(requireUserProvider);
      final displayName = user.displayName;
      await ref.read(studentServiceProvider).assignDriverToStudent(
        displayName: displayName,
        studentUid: widget.studentUid,
        driverId: driverId,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver assigned successfully')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('Driver does not exist')
          ? 'The driver ID entered does not exist'
          : 'Driver assignment failed: $e';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Driver ID')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the ID of the driver assigned to you so we can link your account.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _driverIdCtrl,
              decoration: const InputDecoration(labelText: 'Driver ID'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _assignDriver,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Assign Driver'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
