import 'package:flutter/material.dart';

class OnboardingStepDot extends StatelessWidget {
  final String label;
  final bool active;
  final bool done;

  const OnboardingStepDot({
    super.key,
    required this.label,
    required this.active,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final bg = (done || active) ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0);
    final fg = (done || active) ? Colors.white : const Color(0xFF8A8A8A);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: done
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
              ),
      ),
    );
  }
}

class OnboardingStepLine extends StatelessWidget {
  final bool done;
  const OnboardingStepLine({super.key, required this.done});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 1.5,
        color: done ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0),
      ),
    );
  }
}

class OnboardingStepCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const OnboardingStepCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(fontSize: 14, color: Color(0xFF5A5A5A), height: 1.55),
          ),
        ],
      ),
    );
  }
}

class OnboardingInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const OnboardingInfoRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF4CAF50)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF3A3A3A))),
      ],
    );
  }
}

class OnboardingPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const OnboardingPrimaryButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class OnboardingGuideRow extends StatelessWidget {
  final String number;
  final String text;

  const OnboardingGuideRow({super.key, required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(color: Color(0xFF1A1A1A), shape: BoxShape.circle),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF3A3A3A), height: 1.4),
          ),
        ),
      ],
    );
  }
}
