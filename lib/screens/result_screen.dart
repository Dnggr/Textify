import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../widgets/text_result_card.dart';
import '../widgets/action_button.dart';

/// Shows the result of an OCR scan.
///
/// Displays:
///   - A thumbnail of the scanned image
///   - The source label (CAMERA SCAN or GALLERY SCAN)
///   - The extracted text in a scrollable, selectable card
///   - Action buttons: Copy, Share, Scan Again
class ResultScreen extends StatefulWidget {
  final String extractedText;
  final File imageFile;
  final String sourceLabel;

  const ResultScreen({
    super.key,
    required this.extractedText,
    required this.imageFile,
    required this.sourceLabel,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  bool _copied = false;

  bool get _isEmpty => widget.extractedText.trim().isEmpty;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _copyText() async {
    if (_isEmpty) return;
    await Clipboard.setData(ClipboardData(text: widget.extractedText));
    setState(() => _copied = true);

    // Reset the "Copied!" state after 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _shareText() async {
    if (_isEmpty) return;
    await Share.share(
      widget.extractedText,
      subject: 'Text extracted by Textify',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            children: [
              // ── Top bar ────────────────────────────────────────────
              _buildTopBar(context),

              // ── Scrollable content ─────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image thumbnail + stats row
                      _buildImageRow(),

                      const SizedBox(height: 24),

                      // Character / word count
                      _buildStats(),

                      const SizedBox(height: 16),

                      // The extracted text card
                      TextResultCard(
                        text: widget.extractedText,
                        isEmpty: _isEmpty,
                      ),

                      const SizedBox(height: 24),

                      // Action buttons: Copy + Share
                      if (!_isEmpty) _buildActionRow(),

                      const SizedBox(height: 16),

                      // Scan Again button
                      _buildScanAgainButton(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(
                Icons.home_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.sourceLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                'Result',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Success / empty indicator badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _isEmpty
                  ? Colors.red.withOpacity(0.15)
                  : Colors.green.withOpacity(0.15),
              border: Border.all(
                color: _isEmpty
                    ? Colors.red.withOpacity(0.3)
                    : Colors.green.withOpacity(0.3),
              ),
            ),
            child: Text(
              _isEmpty ? 'No Text' : 'Text Found',
              style: TextStyle(
                color: _isEmpty ? Colors.redAccent : Colors.greenAccent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageRow() {
    return Row(
      children: [
        // Image thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white12),
            ),
            child: Image.file(widget.imageFile, fit: BoxFit.cover),
          ),
        ),

        const SizedBox(width: 16),

        // Source details
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Source image',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.imageFile.path.split('/').last,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats() {
    if (_isEmpty) return const SizedBox.shrink();

    final words = widget.extractedText
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final chars = widget.extractedText.length;
    final lines = widget.extractedText.trim().split('\n').length;

    return Row(
      children: [
        _statChip('$words', 'words'),
        const SizedBox(width: 10),
        _statChip('$chars', 'chars'),
        const SizedBox(width: 10),
        _statChip('$lines', 'lines'),
      ],
    );
  }

  Widget _statChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white10),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: ' $label',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        // Copy button
        ActionButton(
          icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
          label: _copied ? 'COPIED!' : 'COPY',
          color: _copied ? Colors.greenAccent : const Color(0xFF00E5FF),
          onTap: _copyText,
        ),

        const SizedBox(width: 12),

        // Share button
        ActionButton(
          icon: Icons.share_rounded,
          label: 'SHARE',
          color: const Color(0xFFB388FF),
          onTap: _shareText,
        ),
      ],
    );
  }

  Widget _buildScanAgainButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh_rounded, color: Colors.white54, size: 18),
            SizedBox(width: 8),
            Text(
              'SCAN AGAIN',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
