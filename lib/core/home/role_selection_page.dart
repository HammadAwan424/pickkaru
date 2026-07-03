import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../student/student_core/services/student_service.dart';
import '../../driver/driver_core/services/driver_service.dart';
import '../enums.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  roles _role = roles.student;
  bool _loading = false;

  Future<void> _handleCompleteSetup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No authenticated user found.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final username = user.email?.split('@').first ?? user.uid;
      final displayName = user.displayName ?? '';
      
      if (_role == roles.student) {
        await StudentService().createStudentAccount(
          uid: user.uid,
          username: username,
          displayName: displayName,
        );
      } else {
        await DriverService().createDriverAccount(
          uid: user.uid,
          username: username,
          displayName: displayName,
        );
      }
      // Riverpod's stream listener in the router gate will automatically
      // detect this new user record and route them to their homepage.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete setup: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Clean off-white background
      appBar: AppBar(
        title: const Text(
          'Role Selection',
          style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Prevent going back since they must select a role
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Select Your Role',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Identify yourself to configure your Pickkaru coordinates.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              
              // Selection Cards
              Row(
                children: [
                  // Student Card
                  Expanded(
                    child: _RoleSelectionCard(
                      title: 'Student',
                      description: 'I want to ride to school',
                      icon: Icons.backpack_rounded, // school bag illustrative icon
                      isSelected: _role == roles.student,
                      activeColor: const Color(0xFF4F46E5), // Indigo Active accent
                      onTap: () {
                        setState(() => _role = roles.student);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Driver Card
                  Expanded(
                    child: _RoleSelectionCard(
                      title: 'Driver',
                      description: 'I am driving students',
                      icon: Icons.explore_rounded, // steering/explore path illustrative icon
                      isSelected: _role == roles.driver,
                      activeColor: const Color(0xFF0D9488), // Teal Active accent
                      onTap: () {
                        setState(() => _role = roles.driver);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              // Elevated Save Action Card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ],
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488), // Teal Primary Accent
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Highly rounded
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFF0D9488).withValues(alpha: 0.3),
                      ),
                      onPressed: _loading ? null : _handleCompleteSetup,
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
                              'Complete Setup',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleSelectionCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _RoleSelectionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  State<_RoleSelectionCard> createState() => _RoleSelectionCardState();
}

class _RoleSelectionCardState extends State<_RoleSelectionCard> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) => setState(() => _isTapped = false),
      onTapCancel: () => setState(() => _isTapped = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isTapped ? 0.95 : (widget.isSelected ? 1.02 : 1.0),
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: widget.isSelected ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected ? widget.activeColor : Colors.grey.shade300,
              width: widget.isSelected ? 2.5 : 1.2,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.activeColor.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Role Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? widget.activeColor.withValues(alpha: 0.1)
                      : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isSelected ? widget.activeColor.withValues(alpha: 0.2) : Colors.grey.shade200,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  size: 38,
                  color: widget.isSelected ? widget.activeColor : Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: widget.isSelected ? widget.activeColor : const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                widget.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
