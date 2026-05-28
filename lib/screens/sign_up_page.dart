import 'package:flutter/material.dart';
import '../screens/student_driver_assignment_page.dart';
import '../services/firebase_signup_service.dart';
import '../models/enums.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _usernameCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  roles _role = roles.student;
  bool _loading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _secretCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final username = _usernameCtrl.text.trim();
    final secret = _secretCtrl.text.trim();
    if (username.isEmpty || secret.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter username and secret')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final svc = FirebaseSignupService();
      final uid = await svc.signUpWithUsername(
        username: username,
        secret: secret,
        role: _role,
      );

      if (!mounted) return;

      if (_role == roles.student) {
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => StudentDriverAssignmentPage(studentUid: uid),
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup complete')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _singUpWithGoogle() async {
    setState(() => _loading = true);
    try {
      final svc = FirebaseSignupService();
      await svc.signInWithGoogle(_role);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed in with Google')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
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
              decoration:
                  const InputDecoration(labelText: 'Secret Code (password)'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Role:'),
                const SizedBox(width: 12),
                DropdownButton<roles>(
                  value: _role,
                  items: const [
                    DropdownMenuItem(
                        value: roles.student, child: Text('Student')),
                    DropdownMenuItem(
                        value: roles.driver, child: Text('Driver')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _role = value);
                  },
                )
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signup,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Sign up'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _singUpWithGoogle,
                    icon: const Icon(Icons.login),
                    label: const Text('Google'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to welcome'),
            ),
          ],
        ),
      ),
    );
  }
}
