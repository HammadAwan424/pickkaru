import 'package:flutter/material.dart';

class RideStatusBanner extends StatelessWidget {
  const RideStatusBanner({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.green.shade200),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.route, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ride is active — driver is on the way.',
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Track ride — coming soon'),
                ),
              );
            },
            icon: const Icon(Icons.map, size: 18),
            label: const Text('Track Ride'),
          ),
        ],
      ),
    );
  }
}
