import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import 'location_picker_screen.dart';

class StudentSettingsPage extends ConsumerStatefulWidget {
  const StudentSettingsPage({super.key});

  @override
  ConsumerState<StudentSettingsPage> createState() => _StudentSettingsPageState();
}

class _StudentSettingsPageState extends ConsumerState<StudentSettingsPage> {
  final _displayNameController = TextEditingController();
  final _checkpointController = TextEditingController();
  bool _defaultMorning = false;
  bool _defaultEvening = false;
  bool _initialized = false;

  // map related state
  String _savedAddress = "No location configured yet";
  double? _lat;
  double? _lng;

  @override
  void dispose() {
    _displayNameController.dispose();
    _checkpointController.dispose();
    super.dispose();
  }

  Future<void> _save(String uid, String currentDisplayName, String assignedDriverId) async {
    final service = ref.read(studentServiceProvider);
    final newDisplayName = _displayNameController.text.trim();

    if (newDisplayName != currentDisplayName) {
      await service.updateDisplayName(
        uid: uid,
        assignedDriverId: assignedDriverId,
        newDisplayName: newDisplayName,
      );
    }

    await service.updateStudentDefaults(
      uid: uid,
      defaultMorning: _defaultMorning,
      defaultEvening: _defaultEvening,
      defaultCheckpoint: _checkpointController.text.trim().isEmpty
          ? null
          : _checkpointController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;

    final studentAsync = user == null ? null : ref.watch(studentProvider(user.uid));
    final student = studentAsync?.value;

    // initialize once when both models are available
    if (!_initialized && user != null && student != null) {
      _displayNameController.text = user.displayName;
      _defaultMorning = student.defaultMorning;
      _defaultEvening = student.defaultEvening;
      _checkpointController.text = student.defaultCheckpoint ?? '';
      _initialized = true;
    }

    final isReady = user != null && student != null;

    return isReady
        ? _buildForm(user.uid, user.displayName, student.assignedDriverId!) // guranteed to exist
        : const Center(child: CircularProgressIndicator());
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



          const SizedBox(height: 20),
          const Text('Defaults', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('Default Morning'),
            value: _defaultMorning,
            onChanged: (v) => setState(() => _defaultMorning = v),
          ),
          SwitchListTile(
            title: const Text('Default Evening'),
            value: _defaultEvening,
            onChanged: (v) => setState(() => _defaultEvening = v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _checkpointController,
            decoration: const InputDecoration(labelText: 'Default Checkpoint'),
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