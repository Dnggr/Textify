import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import '../models/draw_action.dart';
import '../widgets/drawing_painter.dart';
import '../widgets/color_picker_row.dart';

/// Full-screen image editor.
///
/// Tabs:
///   1. Crop  — uses native image_cropper (uCrop)
///   2. Draw  — custom canvas with pen, eraser, undo, redo, color picker
///
/// Returns the edited File via Navigator.pop(editedFile)
/// or pops with null if user cancels.
class ImageEditorScreen extends StatefulWidget {
  final File imageFile;
  final String imageLabel; // e.g. "Screenshot 3"

  const ImageEditorScreen({
    super.key,
    required this.imageFile,
    required this.imageLabel,
  });

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late File _currentFile; // Updated after crop

  // ── Drawing state ───────────────────────────────────────────────────
  final List<DrawAction> _completedActions = [];
  final List<DrawAction> _redoStack = [];
  DrawAction? _currentAction;

  Color _penColor = Colors.red;
  double _strokeWidth = 4.0;
  bool _isEraser = false;

  // Used to capture the drawing canvas as an image
  final GlobalKey _canvasKey = GlobalKey();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentFile = widget.imageFile;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Crop ─────────────────────────────────────────────────────────────

  Future<void> _openCrop() async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _currentFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: widget.imageLabel,
          toolbarColor: const Color(0xFF0A0A0F),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFF00E5FF),
          backgroundColor: const Color(0xFF0A0A0F),
          dimmedLayerColor: Colors.black87,
          cropGridColor: Colors.white24,
          cropFrameColor: const Color(0xFF00E5FF),
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _currentFile = File(croppedFile.path);
        // Clear draw history since the image changed
        _completedActions.clear();
        _redoStack.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image cropped ✓'),
            backgroundColor: Color(0xFF1A1A2E),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  // ── Drawing ──────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails details) {
    final RenderBox renderBox =
        _canvasKey.currentContext!.findRenderObject() as RenderBox;
    final localPos = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      _currentAction = DrawAction(
        points: [localPos],
        color: _isEraser ? Colors.transparent : _penColor,
        strokeWidth: _isEraser ? _strokeWidth * 3 : _strokeWidth,
        isEraser: _isEraser,
      );
      _redoStack.clear(); // New stroke clears redo history
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentAction == null) return;
    final RenderBox renderBox =
        _canvasKey.currentContext!.findRenderObject() as RenderBox;
    final localPos = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      _currentAction = DrawAction(
        points: [..._currentAction!.points, localPos],
        color: _currentAction!.color,
        strokeWidth: _currentAction!.strokeWidth,
        isEraser: _currentAction!.isEraser,
      );
    });
  }

  void _onPanEnd(DragEndDetails _) {
    if (_currentAction == null) return;
    setState(() {
      _completedActions.add(_currentAction!);
      _currentAction = null;
    });
  }

  void _undo() {
    if (_completedActions.isEmpty) return;
    setState(() {
      _redoStack.add(_completedActions.removeLast());
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() {
      _completedActions.add(_redoStack.removeLast());
    });
  }

  // ── Save: flatten drawing onto image ─────────────────────────────────

  Future<void> _saveAndReturn() async {
    setState(() => _isSaving = true);

    try {
      File finalFile = _currentFile;

      // If user drew anything, flatten the canvas onto the image
      if (_completedActions.isNotEmpty) {
        finalFile = await _flattenDrawingOntoImage();
      }

      if (mounted) Navigator.pop(context, finalFile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Captures the RepaintBoundary wrapping the canvas+image and saves it
  /// to a temp file. This merges the drawing onto the image permanently.
  Future<File> _flattenDrawingOntoImage() async {
    final boundary =
        _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/textify_draw_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────
            _buildTopBar(),

            // ── Tab bar (Crop / Draw) ────────────────────────────────
            _buildTabBar(),

            // ── Tab content ──────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCropTab(),
                  _buildDrawTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Cancel
          GestureDetector(
            onTap: () => Navigator.pop(context, null),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white54, size: 18),
            ),
          ),

          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Text(
              widget.imageLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Save button
          GestureDetector(
            onTap: _isSaving ? null : _saveAndReturn,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF00E5FF).withOpacity(0.15),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withOpacity(0.5),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Color(0xFF00E5FF), strokeWidth: 2),
                    )
                  : const Text(
                      'DONE',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF00E5FF).withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFF00E5FF).withOpacity(0.4), width: 1),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFF00E5FF),
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.crop_rounded, size: 16), text: 'CROP'),
          Tab(icon: Icon(Icons.edit_rounded, size: 16), text: 'DRAW'),
        ],
      ),
    );
  }

  // ── Crop Tab ─────────────────────────────────────────────────────────

  Widget _buildCropTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Image preview
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _currentFile,
                fit: BoxFit.contain,
                key: ValueKey(_currentFile.path), // Force rebuild after crop
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Crop button
          GestureDetector(
            onTap: _openCrop,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF00E5FF).withOpacity(0.1),
                border:
                    Border.all(color: const Color(0xFF00E5FF).withOpacity(0.4)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.crop_rounded, color: Color(0xFF00E5FF), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'OPEN CROP EDITOR',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Tap to open the full-screen crop editor.\nDrag corners to crop, pinch to zoom.',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 11,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Draw Tab ─────────────────────────────────────────────────────────

  Widget _buildDrawTab() {
    return Column(
      children: [
        // Drawing toolbar
        _buildDrawToolbar(),

        // Canvas: image + drawing layer stacked
        Expanded(
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: RepaintBoundary(
              key: _canvasKey,
              child: Stack(
                children: [
                  // Base image
                  Positioned.fill(
                    child: Image.file(
                      _currentFile,
                      fit: BoxFit.contain,
                    ),
                  ),
                  // Drawing canvas (transparent background, sits on top)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: DrawingPainter(
                        completedActions: _completedActions,
                        currentAction: _currentAction,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Color picker row at the bottom
        ColorPickerRow(
          selectedColor: _penColor,
          onColorSelected: (color) {
            setState(() {
              _penColor = color;
              _isEraser = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDrawToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          // Stroke width options
          _toolButton(
            icon: Icons.remove_rounded,
            label: 'Thin',
            isActive: _strokeWidth == 2.0 && !_isEraser,
            onTap: () => setState(() {
              _strokeWidth = 2.0;
              _isEraser = false;
            }),
          ),
          _toolButton(
            icon: Icons.circle,
            label: 'Med',
            isActive: _strokeWidth == 4.0 && !_isEraser,
            onTap: () => setState(() {
              _strokeWidth = 4.0;
              _isEraser = false;
            }),
            iconSize: 10,
          ),
          _toolButton(
            icon: Icons.circle,
            label: 'Thick',
            isActive: _strokeWidth == 8.0 && !_isEraser,
            onTap: () => setState(() {
              _strokeWidth = 8.0;
              _isEraser = false;
            }),
            iconSize: 16,
          ),

          const SizedBox(width: 8),
          Container(width: 1, height: 24, color: Colors.white12),
          const SizedBox(width: 8),

          // Eraser
          _toolButton(
            icon: Icons.auto_fix_normal_rounded,
            label: 'Eraser',
            isActive: _isEraser,
            activeColor: const Color(0xFFFF9500),
            onTap: () => setState(() => _isEraser = !_isEraser),
          ),

          const Spacer(),

          // Undo
          _toolButton(
            icon: Icons.undo_rounded,
            label: 'Undo',
            isActive: false,
            isDisabled: _completedActions.isEmpty,
            onTap: _undo,
          ),
          // Redo
          _toolButton(
            icon: Icons.redo_rounded,
            label: 'Redo',
            isActive: false,
            isDisabled: _redoStack.isEmpty,
            onTap: _redo,
          ),
        ],
      ),
    );
  }

  Widget _toolButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    Color activeColor = const Color(0xFF00E5FF),
    bool isDisabled = false,
    double iconSize = 18,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isActive ? activeColor.withOpacity(0.15) : Colors.transparent,
          border: Border.all(
            color: isActive ? activeColor.withOpacity(0.5) : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: isDisabled
              ? Colors.white12
              : isActive
                  ? activeColor
                  : Colors.white54,
        ),
      ),
    );
  }
}
