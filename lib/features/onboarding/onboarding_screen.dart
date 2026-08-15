import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

class _Slide {
  final IconData icon;
  final String Function(AppLocalizations) titleFor;
  const _Slide(this.icon, this.titleFor);
}

final _slides = [
  _Slide(Icons.menu_book_outlined, (l10n) => l10n.onboardingSlide1),
  _Slide(Icons.check_circle_outline, (l10n) => l10n.onboardingSlide2),
  _Slide(Icons.nightlight_outlined, (l10n) => l10n.onboardingSlide3),
];

/// Screen 2 — Onboarding: introduces the app's idea before entry.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              // Directional (not physical) alignment, so the skip button
              // sits at the reading-start side in every locale: right in
              // RTL (Arabic), left in LTR (English/German/Turkish).
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: widget.onFinished,
                child: Text(l10n.onboardingSkip),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.primaryEmerald.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(slide.icon,
                              size: 56, color: AppColors.primaryEmerald),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide.titleFor(l10n),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? AppColors.primaryEmerald
                        : AppColors.primaryEmerald.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_index == _slides.length - 1) {
                      widget.onFinished();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(
                    _index == _slides.length - 1 ? l10n.onboardingStart : l10n.onboardingNext,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
