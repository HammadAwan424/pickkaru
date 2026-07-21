import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/student/student_core/services/student_service.dart';
import 'package:pickkaru/core/auth/auth_provider.dart';
import 'package:pickkaru/student/student_core/providers/student_provider.dart';
import 'package:pickkaru/driver/driver_core/providers/driver_provider.dart';
import '../../core/auth/auth_service.dart';
import 'location_picker_screen.dart';

class StudentSettingsPage extends ConsumerStatefulWidget {
  const StudentSettingsPage({super.key});

  @override
  ConsumerState<StudentSettingsPage> createState() => _StudentSettingsPageState();
}

class _StudentSettingsPageState extends ConsumerState<StudentSettingsPage> {
  final _displayNameController = TextEditingController();
  bool _initialized = false;

  // map related state
  String _savedAddress = "No location configured yet";
  double? _lat;
  double? _lng;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _save(String uid, String currentDisplayName, String assignedDriverId) async {
    final studentService = ref.read(studentServiceProvider);
    final newDisplayName = _displayNameController.text.trim();
    
    if (newDisplayName != currentDisplayName) {
      await studentService.updateDisplayName(
        uid: uid,
        assignedDriverId: assignedDriverId,
        newDisplayName: newDisplayName,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(requireUserProvider);
    final student = ref.watch(requireStudentProvider);

    if (!_initialized) {
      _displayNameController.text = user.displayName;
      _initialized = true;
    }

    return _buildForm(user.uid, user.displayName, student.assignedDriverId);
  }

  Widget _buildForm(String uid, String currentDisplayName, String assignedDriverId) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text('Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _displayNameController,
            decoration: const InputDecoration(labelText: 'Display name'),
          ),


          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.blue),
            title: const Text("Default Delivery/Target Location"),
            subtitle: Text(_savedAddress),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              // Navigate and wait for user action
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      LocationPickerScreen(),
                ),
              );

              // Handle the data returned from the picker
              if (result != null && result is Map<String, dynamic>) {
                setState(() {
                  _lat = result['latitude'];
                  _lng = result['longitude'];
                  _savedAddress = result['address'];
                });

                // TODO: Persist coordinates locally or push to Backend/Firebase here
              }
            },
          ),
          if (_lat != null && _lng != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Lat: $_lat, Lng: $_lng",
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _save(uid, currentDisplayName, assignedDriverId),
            child: const Text('Save'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => ref.read(authServiceProvider).signOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}