import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/scan_item.dart';
import '../services/ocr_service.dart';

/// Shows the OCR results for all scanned images.
///
/// Features:
/// - Per-image result cards (collapsible)
/// - Combined text view
/// - Save options: Copy to clipboard OR export as named .txt file
class BatchResultScreen extends StatefulWidget {
  final List<ScanItem> items;
  final Map<String, String> ocrResults; // imagePath → text

  const BatchResultScreen({
    super.key,
    required this.items,
    required this.ocrResults,
  });

  @override
  State<BatchResultScreen> createState() => _BatchResultScreenState();
}

class _BatchResultScreenState extends State<BatchResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _copied = false;

  // Set of expanded item IDs in the "Per Image" tab
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Start with all expanded
    _expandedIds.addAll(widget.items.map((i) => i.id));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  String _getTextForItem(ScanItem item) =>
      widget.ocrResults[item.imageFile.path] ?? '';

  String get _combinedText {
    final orderedPaths = widget.items.map((i) => i.imageFile.path).toList();
    return OcrService.combineResults(orderedPaths, widget.ocrResults);
  }

  int get _totalWords {
    return widget.items.fold(0, (sum, item) {
      final text = _getTextForItem(item).trim();
      if (text.isEmpty) return sum;
      return sum + text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    });
  }

  int get _successCount =>
      widget.items.where((i) => _getTextForItem(i).trim().isNotEmpty).length;

  // ── Actions ───────────────────────────────────────────────────────────

  Future<void> _copyAll() async {
    await Clipboard.setData(ClipboardData(text: _combinedText));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _exportAsTxt() async {
    // Step 1: Ask user for a file name
    final nameController = TextEditingController(
      text: 'textify_scan_${DateTime.now().day}_${DateTime.now().month}',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'SAVE AS .TXT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'File name',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'my_scan',
                hintStyle: const TextStyle(color: Colors.white24),
                suffixText: '.txt',
                suffixStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You\'ll choose the save location\nin the next step.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                height: 1.6,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Choose Location',
                style: TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final fileName = nameController.text.trim().isEmpty
        ? 'textify_scan'
        : nameController.text.trim();

    // Step 2: Open native file save dialog (lets user pick folder + confirm name)
    try {
      final bytes = utf8.encode(_combinedText);

      final String? savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save extracted text',
        fileName: '$fileName.txt',
        bytes: Uint8List.fromList(bytes),
        allowedExtensions: ['txt'],
        type: FileType.custom,
      );

      if (savedPath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.greenAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Saved to $savedPath',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1A2E1A),
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (savedPath == null && mounted) {
        // User cancelled — silently ignore
      }
    } catch (e) {
      // Fallback: save to Downloads directory manually
      await _fallbackSaveToDownloads(fileName);
    }
  }

  /// Fallback for devices where FilePicker.saveFile isn't fully supported.
  /// Saves to the app's documents directory and notifies the user.
  Future<void> _fallbackSaveToDownloads(String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName.txt');
      await file.writeAsString(_combinedText);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to app storage: ${file.path}'),
            backgroundColor: const Color(0xFF1A1A2E),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  Future<void> _shareAll() async {
    await Share.share(_combinedText, subject: 'Textify OCR results');
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildStatsRow(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPerImageTab(),
                  _buildCombinedTab(),
                ],
              ),
            ),
            _buildSaveBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
              child:
                  const Icon(Icons.home_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BATCH RESULTS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'OCR complete',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          // Share button
          GestureDetector(
            onTap: _shareAll,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFB388FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFFB388FF).withOpacity(0.3)),
              ),
              child: const Icon(Icons.share_rounded,
                  color: Color(0xFFB388FF), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          _statChip('$_successCount/${widget.items.length}', 'scanned'),
          const SizedBox(width: 8),
          _statChip('$_totalWords', 'words'),
          const SizedBox(width: 8),
          _statChip('${_combinedText.length}', 'chars'),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white10),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: ' $label',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF00E5FF).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFF00E5FF).withOpacity(0.35), width: 1),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFF00E5FF),
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
        tabs: [
          Tab(text: 'PER IMAGE (${widget.items.length})'),
          const Tab(text: 'COMBINED'),
        ],
      ),
    );
  }

  // ── Per-image tab ─────────────────────────────────────────────────────

  Widget _buildPerImageTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final text = _getTextForItem(item);
        final isEmpty = text.trim().isEmpty;
        final isExpanded = _expandedIds.contains(item.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isEmpty
                  ? Colors.white10
                  : const Color(0xFF00E5FF).withOpacity(0.2),
            ),
            color: Colors.white.withOpacity(0.03),
          ),
          child: Column(
            children: [
              // Header row (always visible)
              GestureDetector(
                onTap: () => setState(() {
                  if (isExpanded) {
                    _expandedIds.remove(item.id);
                  } else {
                    _expandedIds.add(item.id);
                  }
                }),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          item.imageFile,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Title + word count
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Screenshot ${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              isEmpty
                                  ? 'No text found'
                                  : '${text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} words · ${text.length} chars',
                              style: TextStyle(
                                color: isEmpty
                                    ? Colors.red.shade300
                                    : Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Expand/collapse icon
                      Icon(
                        isExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Expandable text content
              if (isExpanded && !isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 10),
                      SelectableText(
                        text,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.6,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Combined tab ──────────────────────────────────────────────────────

  Widget _buildCombinedTab() {
    final text = _combinedText;
    final isEmpty = text.trim().isEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isEmpty
                ? Colors.white10
                : const Color(0xFF00E5FF).withOpacity(0.25),
          ),
          color: Colors.white.withOpacity(0.03),
        ),
        child: isEmpty
            ? const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No text was extracted from any image.',
                    style: TextStyle(color: Colors.white24, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : SelectableText(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.7,
                  fontFamily: 'monospace',
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }

  // ── Save bar ──────────────────────────────────────────────────────────

  Widget _buildSaveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
        color: const Color(0xFF0A0A0F),
      ),
      child: Row(
        children: [
          // Copy to clipboard
          Expanded(
            child: GestureDetector(
              onTap: _combinedText.isEmpty ? null : _copyAll,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _copied
                      ? Colors.green.withOpacity(0.15)
                      : const Color(0xFF00E5FF).withOpacity(0.1),
                  border: Border.all(
                    color: _copied
                        ? Colors.greenAccent.withOpacity(0.4)
                        : const Color(0xFF00E5FF).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _copied ? Icons.check_rounded : Icons.copy_rounded,
                      color: _copied
                          ? Colors.greenAccent
                          : const Color(0xFF00E5FF),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _copied ? 'COPIED!' : 'COPY ALL',
                      style: TextStyle(
                        color: _copied
                            ? Colors.greenAccent
                            : const Color(0xFF00E5FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Export as .txt
          Expanded(
            child: GestureDetector(
              onTap: _combinedText.isEmpty ? null : _exportAsTxt,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFB388FF).withOpacity(0.1),
                  border: Border.all(
                      color: const Color(0xFFB388FF).withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_alt_rounded,
                        color: Color(0xFFB388FF), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'SAVE .TXT',
                      style: TextStyle(
                        color: Color(0xFFB388FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
