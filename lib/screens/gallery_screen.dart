import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/ocr_service.dart';
import 'result_screen.dart';

/// Gallery screen — lets user pick an image from their phone's gallery
/// (photos, screenshots, downloads, etc.) and runs OCR on it.
///
/// This screen immediately launches the image picker on open.
/// While processing, it shows a loading UI. On success, navigates to ResultScreen.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();

  File? _selectedImage;
  bool _isProcessing = false;
  bool _hasPickedImage = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Immediately open gallery when user lands on this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickImage();
    });
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // Opens the native image picker
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // Full quality = better OCR accuracy
      );

      // User cancelled without picking anything
      if (pickedFile == null) {
        if (mounted && !_hasPickedImage) {
          Navigator.pop(context); // Go back to home
        }
        return;
      }

      setState(() {
        _selectedImage = File(pickedFile.path);
        _hasPickedImage = true;
        _isProcessing = true;
        _errorMessage = null;
      });

      // Run OCR
      final String extractedText = await _ocrService.extractText(
        pickedFile.path,
      );

      // Navigate to result screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              extractedText: extractedText,
              imageFile: _selectedImage!,
              sourceLabel: 'GALLERY SCAN',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Failed to process image:\n$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar ───────────────────────────────────────────
              Row(
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
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'GALLERY SCAN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),

              // ── Main content ──────────────────────────────────────
              Expanded(child: _buildMainContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    // Show error state
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 56,
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            _buildRetryButton(),
          ],
        ),
      );
    }

    // Show processing / loading state
    if (_isProcessing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Preview of the selected image
            if (_selectedImage != null)
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFB388FF).withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB388FF).withOpacity(0.15),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              ),

            const SizedBox(height: 36),

            // Pulsing progress indicator
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: Color(0xFFB388FF),
                strokeWidth: 2,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'READING TEXT...',
              style: TextStyle(
                color: Color(0xFFB388FF),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'This may take a moment on first run',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Default: Show pick image prompt
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFB388FF).withOpacity(0.3),
              ),
              color: const Color(0xFFB388FF).withOpacity(0.06),
            ),
            child: const Icon(
              Icons.photo_library_rounded,
              color: Color(0xFFB388FF),
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'SELECT AN IMAGE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a photo or screenshot\nfrom your gallery',
            style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildRetryButton(),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFB388FF).withOpacity(0.5)),
          color: const Color(0xFFB388FF).withOpacity(0.08),
        ),
        child: const Text(
          'Open Gallery',
          style: TextStyle(
            color: Color(0xFFB388FF),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
