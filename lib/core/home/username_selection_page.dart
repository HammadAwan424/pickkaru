import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../user/user_service.dart';

class UsernameSelectionPage extends StatefulWidget {
  const UsernameSelectionPage({super.key});

  @override
  State<UsernameSelectionPage> createState() => _UsernameSelectionPageState();
}

class _UsernameSelectionPageState extends State<UsernameSelectionPage> {
  final _usernameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _usernameCtrl.text = user.email?.split('@').first ?? '';
      _displayNameCtrl.text = user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _displayNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final username = _usernameCtrl.text.trim();
    final displayName = _displayNameCtrl.text.trim();

    if (username.isEmpty || displayName.isEmpty) {
      setState(() => _errorMessage = 'Please fill out all fields');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await UserService().createInitialProfile(
        uid: user.uid,
        username: username.toLowerCase(),
        displayName: displayName,
      );
      // Profile created successfully, router will automatically redirect
    } catch (e) {
      setState(() {
        if (e.toString().contains('username-taken')) {
          _errorMessage = 'This username is already taken. Please choose another.';
        } else {
          _errorMessage = 'Failed to create profile: $e';
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          'Create Profile',
          style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome to Pickkaru!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Let\'s set up your profile so others can find you.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),
              TextField(
                controller: _displayNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'e.g. John Doe',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'e.g. john_doe',
                  prefixText: '@ ',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                ),
                onPressed: _loading ? null : _handleSave,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
