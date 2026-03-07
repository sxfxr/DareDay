import 'package:flutter/material.dart';

class VerificationFailureScreen extends StatelessWidget {
  final int score;
  final String reasoning;
  final String dareTitle;

  const VerificationFailureScreen({
    super.key,
    required this.score,
    required this.reasoning,
    required this.dareTitle,
  });

  @override
  Widget build(BuildContext context) {
    const neonCyan = Color(0xFF22D3EE);
    const backgroundDark = Color(0xFF0F0814);

    return Scaffold(
      backgroundColor: backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Failure Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent, width: 4),
                  boxShadow: [
                    BoxShadow(color: Colors.redAccent.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 5),
                  ],
                ),
                child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 80),
              ),
              const SizedBox(height: 48),
              
              const Text(
                'VERIFICATION FAILED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'The AI didn\'t see you complete accurately.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Score & Reasoning Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'AI MATCH SCORE',
                          style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                        Text(
                          '$score%',
                          style: TextStyle(
                            color: score > 50 ? Colors.orangeAccent : Colors.redAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: score / 100,
                        backgroundColor: Colors.white10,
                        color: score > 50 ? Colors.orangeAccent : Colors.redAccent,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),
                    const Text(
                      'AI FEEDBACK',
                      style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      reasoning,
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Buttons
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA855F7),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('TRY AGAIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'GO BACK',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
