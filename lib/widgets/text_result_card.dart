import 'package:flutter/material.dart';

/// Displays the extracted OCR text in a styled, scrollable, selectable card.
/// The text is selectable so users can manually highlight and copy parts.
class TextResultCard extends StatelessWidget {
  final String text;
  final bool isEmpty;

  const TextResultCard({super.key, required this.text, required this.isEmpty});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEmpty
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFF00E5FF).withOpacity(0.3),
          width: 1,
        ),
        color: Colors.white.withOpacity(0.04),
      ),
      child: isEmpty ? _buildEmptyState() : _buildTextContent(),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.text_fields_rounded, color: Colors.white24, size: 48),
          SizedBox(height: 16),
          Text(
            'NO TEXT DETECTED',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try again with better lighting\nor a clearer image',
            style: TextStyle(color: Colors.white12, fontSize: 12, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small header label
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E5FF),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'EXTRACTED TEXT',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),

          // The actual selectable text
          SelectableText(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.7,
              fontFamily: 'monospace',
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
