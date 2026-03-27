import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'gallery_screen.dart';
import '../widgets/action_button.dart';

/// The main home screen of Textify.
/// Shows two primary actions: scan with camera, or pick from gallery.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();

    // Entry animation — everything fades + slides up on first load
    _animController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
          ),
        );

    // Auto-start the animation when screen loads
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top bar ──────────────────────────────────────────
                  _buildTopBar(),

                  const Spacer(flex: 2),

                  // ── Hero title block ─────────────────────────────────
                  _buildHeroTitle(),

                  const Spacer(flex: 3),

                  // ── Two main action buttons ──────────────────────────
                  _buildActionButtons(context),

                  const Spacer(flex: 2),

                  // ── Bottom hint ──────────────────────────────────────
                  _buildBottomHint(),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // App logo / wordmark
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'TEXT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
              TextSpan(
                text: 'IFY',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),

        // Version badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
            color: Colors.white.withOpacity(0.04),
          ),
          child: const Text(
            'v1.0',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Glowing accent line
        Container(
          width: 40,
          height: 2,
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF),
            borderRadius: BorderRadius.circular(1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.6),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'Scan.\nExtract.\nDone.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -1,
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Point your camera at any text, or upload a\nscreenshot — Textify extracts it instantly.',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 14,
            height: 1.6,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // ── Camera button ─────────────────────────────────────────
        Expanded(
          child: ActionButton(
            icon: Icons.camera_alt_rounded,
            label: 'CAMERA',
            subtitle: 'Point & scan\nany text',
            color: const Color(0xFF00E5FF),
            isLarge: true,
            onTap: () {
              Navigator.push(context, _buildPageRoute(const CameraScreen()));
            },
          ),
        ),

        const SizedBox(width: 16),

        // ── Gallery button ────────────────────────────────────────
        Expanded(
          child: ActionButton(
            icon: Icons.image_rounded,
            label: 'GALLERY',
            subtitle: 'Pick a photo\nor screenshot',
            color: const Color(0xFFB388FF),
            isLarge: true,
            onTap: () {
              Navigator.push(context, _buildPageRoute(const GalleryScreen()));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomHint() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 12,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(width: 6),
          Text(
            'Works 100% offline · No data sent anywhere',
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Smooth slide-from-right page transition
  PageRoute _buildPageRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
