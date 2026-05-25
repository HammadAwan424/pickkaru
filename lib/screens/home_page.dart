import 'package:flutter/material.dart';
import '../services/firebase_signup_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _usernameCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  final _driverIdCtrl = TextEditingController();
  String _role = 'student';
  bool _loading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _secretCtrl.dispose();
    _driverIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final username = _usernameCtrl.text.trim();
    final secret = _secretCtrl.text.trim();
    final driverId = _driverIdCtrl.text.trim().isEmpty ? null : _driverIdCtrl.text.trim();
    if (username.isEmpty || secret.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter username and secret')));
      return;
    }

    setState(() => _loading = true);
    try {
      final svc = FirebaseSignupService();
      await svc.signUpWithUsername(username: username, secret: secret, role: _role, assignedDriverId: driverId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signup complete')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signup failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final svc = FirebaseSignupService();
      await svc.signInWithGoogle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed in with Google')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google sign-in failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pickkaru — Signup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _secretCtrl,
              decoration: const InputDecoration(labelText: 'Secret Code (password)'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Role:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _role,
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                    DropdownMenuItem(value: 'driver', child: Text('Driver')),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? 'student'),
                )
              ],
            ),
            if (_role == 'student') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _driverIdCtrl,
                decoration: const InputDecoration(labelText: 'Assigned Driver ID (optional)'),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signup,
                    child: _loading ? const CircularProgressIndicator() : const Text('Sign up'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in with Google'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
