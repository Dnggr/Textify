import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/scan_item.dart';
import '../services/ocr_service.dart';
import 'image_editor_screen.dart';
import 'batch_result_screen.dart';

/// Batch gallery screen — pick up to 15 images, reorder them,
/// edit individual images, then scan all at once.
///
/// Flow:
///   1. User picks 1–15 images
///   2. Sees grid with thumbnails + drag handles for reordering
///   3. Can tap edit icon on any image to open ImageEditorScreen
///   4. Taps "Scan All" → batch OCR → BatchResultScreen
class BatchGalleryScreen extends StatefulWidget {
  const BatchGalleryScreen({super.key});

  @override
  State<BatchGalleryScreen> createState() => _BatchGalleryScreenState();
}

class _BatchGalleryScreenState extends State<BatchGalleryScreen> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();

  List<ScanItem> _items = [];
  bool _isPickingImages = false;
  bool _isScanning = false;
  int _scannedCount = 0;

  static const int maxImages = 15;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickImages());
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  // ── Pick images ───────────────────────────────────────────────────────

  Future<void> _pickImages() async {
    if (_isPickingImages) return;
    setState(() => _isPickingImages = true);

    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 100,
        limit: maxImages, // Hard limit at 15
      );

      if (pickedFiles.isEmpty) {
        if (mounted && _items.isEmpty) Navigator.pop(context);
        return;
      }

      // Cap at maxImages even if the picker allows more
      final limited = pickedFiles.take(maxImages).toList();

      // If already have items, append (without exceeding max)
      final existing = _items.length;
      final canAdd = maxImages - existing;
      final toAdd = limited.take(canAdd).toList();

      final newItems = toAdd.asMap().entries.map((e) {
        return ScanItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_${e.key}',
          imageFile: File(e.value.path),
          order: existing + e.key + 1,
        );
      }).toList();

      setState(() => _items = [..._items, ...newItems]);

      if (pickedFiles.length > canAdd && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Max $maxImages images. Only first $canAdd were added.'),
            backgroundColor: const Color(0xFF1A1A2E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick images: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImages = false);
    }
  }

  // ── Reorder ───────────────────────────────────────────────────────────

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
      // Update order numbers to match new positions
      for (int i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(order: i + 1);
      }
    });
  }

  void _removeItem(String id) {
    setState(() {
      _items.removeWhere((item) => item.id == id);
      for (int i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(order: i + 1);
      }
    });
  }

  // ── Edit ─────────────────────────────────────────────────────────────

  Future<void> _editItem(ScanItem item) async {
    final editedFile = await Navigator.push<File?>(
      context,
      MaterialPageRoute(
        builder: (_) => ImageEditorScreen(
          imageFile: item.imageFile,
          imageLabel: 'Screenshot ${item.order}',
        ),
      ),
    );

    if (editedFile != null && mounted) {
      setState(() {
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _items[index] = _items[index].copyWith(
            imageFile: editedFile,
            extractedText: null, // Reset OCR since image changed
          );
        }
      });
    }
  }

  // ── Scan all ──────────────────────────────────────────────────────────

  Future<void> _scanAll() async {
    if (_items.isEmpty || _isScanning) return;
    setState(() {
      _isScanning = true;
      _scannedCount = 0;
    });

    try {
      final paths = _items.map((i) => i.imageFile.path).toList();
      final results = await _ocrService.extractTextBatch(
        paths,
        onProgress: (index) {
          if (mounted) setState(() => _scannedCount = index + 1);
        },
      );

      if (!mounted) return;

      // Navigate to batch result screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BatchResultScreen(
            items: _items,
            ocrResults: results,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan failed: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            if (_items.isEmpty)
              Expanded(child: _buildEmptyState())
            else ...[
              _buildCountBar(),
              Expanded(child: _buildImageGrid()),
              _buildBottomBar(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BATCH SCAN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'Up to 15 screenshots',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          // Add more button (only if under limit)
          if (_items.isNotEmpty && _items.length < maxImages)
            GestureDetector(
              onTap: _isPickingImages ? null : _pickImages,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFFB388FF).withOpacity(0.1),
                  border: Border.all(
                      color: const Color(0xFFB388FF).withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_rounded, color: Color(0xFFB388FF), size: 16),
                    SizedBox(width: 4),
                    Text(
                      'ADD',
                      style: TextStyle(
                        color: Color(0xFFB388FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCountBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Text(
            '${_items.length}/$maxImages images',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          const Text(
            'Hold & drag to reorder',
            style: TextStyle(color: Colors.white24, fontSize: 11),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.drag_indicator_rounded,
              color: Colors.white24, size: 14),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: _items.length,
      onReorder: _onReorder,
      proxyDecorator: (child, index, animation) {
        // Slightly scale up and add shadow while dragging
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Transform.scale(
            scale: 1.05,
            child: Material(
              color: Colors.transparent,
              elevation: 12,
              shadowColor: Colors.black54,
              child: child,
            ),
          ),
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final item = _items[index];
        return _buildItemCard(item, index);
      },
    );
  }

  Widget _buildItemCard(ScanItem item, int index) {
    return Container(
      key: ValueKey(item.id),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
        color: Colors.white.withOpacity(0.04),
      ),
      child: Row(
        children: [
          // Order badge + thumbnail
          Stack(
            children: [
              // Image thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(13),
                  bottomLeft: Radius.circular(13),
                ),
                child: Image.file(
                  item.imageFile,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              // Order number badge
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    '${item.order}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // File name + info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.imageFile.path.split('/').last,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Screenshot ${item.order}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Edit button
          GestureDetector(
            onTap: () => _editItem(item),
            child: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
              ),
              child: const Icon(Icons.edit_rounded,
                  color: Color(0xFF00E5FF), size: 16),
            ),
          ),

          // Remove button
          GestureDetector(
            onTap: () => _removeItem(item.id),
            child: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent, size: 16),
            ),
          ),

          // Drag handle
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.drag_indicator_rounded,
                color: Colors.white24, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: const Color(0xFFB388FF).withOpacity(0.3)),
              color: const Color(0xFFB388FF).withOpacity(0.06),
            ),
            child: const Icon(Icons.photo_library_rounded,
                color: Color(0xFFB388FF), size: 48),
          ),
          const SizedBox(height: 20),
          const Text(
            'NO IMAGES YET',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select up to 15 screenshots from your gallery',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: _isPickingImages ? null : _pickImages,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFB388FF).withOpacity(0.1),
                border:
                    Border.all(color: const Color(0xFFB388FF).withOpacity(0.4)),
              ),
              child: const Text(
                'Open Gallery',
                style: TextStyle(
                  color: Color(0xFFB388FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
        color: const Color(0xFF0A0A0F),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar while scanning
          if (_isScanning) ...[
            Row(
              children: [
                Text(
                  'Scanning $_scannedCount of ${_items.length}...',
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${((_scannedCount / _items.length) * 100).round()}%',
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _items.isEmpty ? 0 : _scannedCount / _items.length,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF00E5FF)),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Scan All button
          GestureDetector(
            onTap: _isScanning || _items.isEmpty ? null : _scanAll,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _isScanning
                    ? Colors.white10
                    : const Color(0xFF00E5FF).withOpacity(0.15),
                border: Border.all(
                  color: _isScanning
                      ? Colors.white12
                      : const Color(0xFF00E5FF).withOpacity(0.5),
                ),
                boxShadow: _isScanning
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withOpacity(0.15),
                          blurRadius: 16,
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isScanning)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Color(0xFF00E5FF), strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.document_scanner_rounded,
                        color: Color(0xFF00E5FF), size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _isScanning
                        ? 'SCANNING...'
                        : 'SCAN ALL ${_items.length} IMAGE${_items.length == 1 ? '' : 'S'}',
                    style: TextStyle(
                      color: _isScanning
                          ? Colors.white38
                          : const Color(0xFF00E5FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
