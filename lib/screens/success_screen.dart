import 'package:flutter/material.dart';

class SuccessScreen extends StatelessWidget {
  final int xpEarned;
  final int gemsEarned;

  const SuccessScreen({
    super.key,
    required this.xpEarned,
    required this.gemsEarned,
  });

  @override
  Widget build(BuildContext context) {
    const neonCyan = Color(0xFF22D3EE);
    const primaryColor = Color(0xFFA855F7);
    const backgroundDark = Color(0xFF0F0814);

    return Scaffold(
      backgroundColor: backgroundDark,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: neonCyan.withValues(alpha: 0.1),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Success Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: neonCyan, width: 4),
                      boxShadow: [
                        BoxShadow(color: neonCyan.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 5),
                      ],
                    ),
                    child: const Icon(Icons.check_circle_outline, color: neonCyan, size: 80),
                  ),
                  const SizedBox(height: 48),
                  
                  const Text(
                    'DARE COMPLETED!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You absolutely crushed it.',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  
                  const SizedBox(height: 64),
                  
                  // Reward Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'REWARDS EARNED',
                          style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildRewardItem('+$xpEarned', 'XP', neonCyan),
                            Container(width: 1, height: 40, color: Colors.white10),
                            _buildRewardItem('+$gemsEarned', 'Gems', Colors.pinkAccent, hasDiamond: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Continue Button
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 64),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                      shadowColor: primaryColor.withValues(alpha: 0.5),
                    ),
                    child: const Text('CONTINUE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem(String value, String label, Color color, {bool hasDiamond = false}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (hasDiamond) ...[
              const SizedBox(width: 4),
              const Icon(Icons.diamond, color: Colors.pinkAccent, size: 20),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
