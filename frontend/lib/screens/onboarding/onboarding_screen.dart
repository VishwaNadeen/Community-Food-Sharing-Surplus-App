import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'onboarding_content.dart';

/// How the user left the onboarding slides.
enum OnboardingResult {
  /// "Get Started": open the sign-up screen.
  signUp,

  /// "Skip" or "I already have an account": open the login screen.
  logIn,
}

// Secondary text with readable contrast on white.
const Color _bodyText = Color(0xFF5B616B);

/// Four swipeable slides introducing FoodLink's roles: Food Donor,
/// Recipient, Volunteer and NGO. Shown once, on first launch.
///
/// The slides are only informational. Choosing a role happens at sign-up,
/// and the backend decides what each account may do.
class OnboardingScreen extends StatefulWidget {
  final ValueChanged<OnboardingResult> onFinished;
  final List<OnboardingSlide> slides;

  const OnboardingScreen({
    super.key,
    required this.onFinished,
    this.slides = kOnboardingSlides,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  bool get _isLastPage => _page == widget.slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slide = widget.slides[_page];

    // System back goes to the previous slide instead of closing the app.
    return PopScope(
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _page > 0) _goTo(_page - 1);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                showSkip: !_isLastPage,
                onSkip: () => widget.onFinished(OnboardingResult.logIn),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.slides.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (_, index) => _SlideView(
                    slide: widget.slides[index],
                    isActive: index == _page,
                  ),
                ),
              ),
              _BottomControls(
                count: widget.slides.length,
                page: _page,
                accent: slide.accent,
                isLastPage: _isLastPage,
                onBack: _page == 0 ? null : () => _goTo(_page - 1),
                onNext: () => _goTo(_page + 1),
                onGetStarted: () => widget.onFinished(OnboardingResult.signUp),
                onLogIn: () => widget.onFinished(OnboardingResult.logIn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar: logo, name, tagline and Skip
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool showSkip;
  final VoidCallback onSkip;

  const _TopBar({required this.showSkip, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/icon/app_icon.jpg',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 40,
                height: 40,
                color: AppTheme.lightGreen,
                child: const Icon(
                  Icons.eco_rounded,
                  color: AppTheme.primaryGreenDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FoodLink',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkText,
                  ),
                ),
                Text(
                  kOnboardingTagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _bodyText,
                  ),
                ),
              ],
            ),
          ),
          // Keep the space so the header does not jump on the last slide.
          Visibility(
            visible: showSkip,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                minimumSize: const Size(64, 48),
                foregroundColor: _bodyText,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Skip'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// One slide
// ─────────────────────────────────────────────────────────────────────────────

class _SlideView extends StatelessWidget {
  final OnboardingSlide slide;
  final bool isActive;

  const _SlideView({required this.slide, required this.isActive});

  // Below this height there is not enough room for a stretching picture,
  // so a fixed-height picture and a scrollable page are used instead.
  static const double _compactHeight = 440;

  Widget _picture({double? height}) {
    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: slide.accentLight,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      // Subtle zoom-in when the slide becomes active.
      child: AnimatedScale(
        scale: isActive ? 1 : 1.06,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        child: _SlideArt(slide: slide),
      ),
    );
  }

  Widget _text() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoleChip(slide: slide),
          const SizedBox(height: 8),
          Text(
            slide.headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 25,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.4, color: _bodyText),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final feature in slide.features)
                _FeatureChip(feature: feature, slide: slide),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Normal phones: the picture fills all space left above the text,
        // so the text always sits just above the buttons.
        if (constraints.maxHeight >= _compactHeight) {
          return Column(
            children: [
              Expanded(child: _picture()),
              _text(),
            ],
          );
        }

        // Very small screens or large text: scroll instead of overflowing.
        return SingleChildScrollView(
          child: Column(
            children: [
              _picture(height: (constraints.maxHeight * 0.5).clamp(150, 260)),
              _text(),
            ],
          ),
        );
      },
    );
  }
}

/// The slide picture, filling its area edge to edge, or an icon
/// illustration when the image file has not been added.
class _SlideArt extends StatelessWidget {
  final OnboardingSlide slide;

  const _SlideArt({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: '${slide.roleName} illustration',
      child: Image.asset(
        slide.imageAsset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => LayoutBuilder(
          builder: (context, constraints) => Center(
            child: _IconIllustration(
              slide: slide,
              size: (constraints.maxHeight * 0.7).clamp(110.0, 230.0),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconIllustration extends StatelessWidget {
  final OnboardingSlide slide;
  final double size;

  const _IconIllustration({required this.slide, required this.size});

  Widget _bubble(IconData icon, double bubbleSize) {
    return Container(
      width: bubbleSize,
      height: bubbleSize,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: slide.accent.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: slide.accent, size: bubbleSize * 0.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bubble = size * 0.26;

    return SizedBox(
      width: size + bubble * 0.6,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: slide.accent.withValues(alpha: 0.20),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(slide.icon, color: slide.accent, size: size * 0.32),
          ),
          if (slide.decorations.isNotEmpty)
            Positioned(
              top: 0,
              right: 0,
              child: _bubble(slide.decorations[0], bubble),
            ),
          if (slide.decorations.length > 1)
            Positioned(
              bottom: size * 0.04,
              left: 0,
              child: _bubble(slide.decorations[1], bubble * 0.9),
            ),
          if (slide.decorations.length > 2)
            Positioned(
              bottom: 0,
              right: size * 0.08,
              child: _bubble(slide.decorations[2], bubble * 0.75),
            ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final OnboardingSlide slide;

  const _RoleChip({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: slide.accentLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'For ${slide.roleName}s',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: slide.accent,
        ),
      ),
    );
  }
}

/// Small rounded tag with an icon, e.g. "Post food".
class _FeatureChip extends StatelessWidget {
  final OnboardingFeature feature;
  final OnboardingSlide slide;

  const _FeatureChip({required this.feature, required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: slide.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(feature.icon, color: slide.accent, size: 18),
          const SizedBox(width: 6),
          Text(
            feature.text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page dots and buttons
// ─────────────────────────────────────────────────────────────────────────────

class _BottomControls extends StatelessWidget {
  final int count;
  final int page;
  final Color accent;
  final bool isLastPage;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onGetStarted;
  final VoidCallback onLogIn;

  const _BottomControls({
    required this.count,
    required this.page,
    required this.accent,
    required this.isLastPage,
    required this.onBack,
    required this.onNext,
    required this.onGetStarted,
    required this.onLogIn,
  });

  static final ButtonStyle _primaryStyle = FilledButton.styleFrom(
    backgroundColor: AppTheme.primaryGreenDark,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(54),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicator: the current dot is wider.
          Semantics(
            label: 'Slide ${page + 1} of $count',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < count; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == page ? 26 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == page ? accent : AppTheme.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (isLastPage) ...[
            FilledButton(
              onPressed: onGetStarted,
              style: _primaryStyle,
              child: const Text('Get Started'),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: onLogIn,
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: AppTheme.primaryGreenDark,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('I already have an account'),
            ),
          ] else
            Row(
              children: [
                // Keeps "Next" in the same place on every slide.
                SizedBox(
                  width: 96,
                  child: onBack == null
                      ? null
                      : TextButton.icon(
                          onPressed: onBack,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 54),
                            foregroundColor: _bodyText,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Back'),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onNext,
                    style: _primaryStyle,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Next'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
