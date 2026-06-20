import 'package:flutter/material.dart';

class CustomChoiceButton extends StatelessWidget {
  const CustomChoiceButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    this.isLocked = false,
    required this.activeBgColor,
    required this.activeFgColor,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isLocked;
  final Color activeBgColor;
  final Color activeFgColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? (isLocked ? activeBgColor.withAlpha(153) : activeBgColor)
        : const Color(0xFFF3F4F6);
    final fgColor = isSelected
        ? (isLocked ? activeFgColor.withAlpha(153) : activeFgColor)
        : (isLocked ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563));

    return InkWell(
      onTap: isLocked ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isLocked ? activeBgColor.withAlpha(153) : activeBgColor)
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: isSelected && !isLocked
              ? [
                  BoxShadow(
                    color: activeBgColor.withAlpha(64),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fgColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
