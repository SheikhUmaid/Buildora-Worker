import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/branding.dart';

class OnboardingSlide {
  const OnboardingSlide({required this.title, required this.body, required this.art});
  final String title;
  final String body;
  final Widget art;
}

/// Three-slide intro with Skip / Next / Get Started.
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key, required this.slides, required this.onDone});
  final List<OnboardingSlide> slides;
  final VoidCallback onDone;

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == widget.slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
              child: Row(
                children: [
                  const BuildoraLogo(size: 22),
                  const Spacer(),
                  if (!last) TextButton(onPressed: widget.onDone, child: const Text('Skip', style: TextStyle(color: AppColors.textMuted))),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final s = widget.slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Center(child: s.art)),
                        Text(s.title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: -0.6)),
                        const SizedBox(height: 12),
                        Text(s.body, style: const TextStyle(fontSize: 16, color: AppColors.textMuted, height: 1.4)),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: last
                  ? AppButton(label: 'Get Started', orangeArrow: true, onPressed: widget.onDone)
                  : Row(
                      children: [
                        for (var i = 0; i < widget.slides.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 6),
                            width: i == _index ? 22 : 7,
                            height: 7,
                            decoration: BoxDecoration(color: i == _index ? AppColors.black : AppColors.surfaceDark, borderRadius: BorderRadius.circular(4)),
                          ),
                        const Spacer(),
                        AppButton(
                          label: 'Next',
                          expand: false,
                          orangeArrow: true,
                          height: 54,
                          onPressed: () => _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ Slide art

Widget _photo(String asset, {double? width, double? height, double radius = 16}) => ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset('assets/branding/$asset.jpg', width: width, height: height, fit: BoxFit.cover),
    );

BoxDecoration _cardShadow([Color color = AppColors.white, double radius = 24]) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 12))],
    );

/// Slide 1: a project card with a real site photo and progress.
class OnboardingArtCard extends StatelessWidget {
  const OnboardingArtCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      padding: const EdgeInsets.all(14),
      decoration: _cardShadow(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _photo('onboarding_site', height: 150, width: double.infinity),
          const SizedBox(height: 14),
          const Text('Skyline Villa', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          const Text('Whitefield, Bengaluru', style: AppText.small),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(value: 0.62, minHeight: 6, color: AppColors.black, backgroundColor: AppColors.surfaceDark),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              CircleAvatar(radius: 3.5, backgroundColor: AppColors.orange),
              SizedBox(width: 6),
              Text('Updated today', style: AppText.small),
              Spacer(),
              Text('62%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Slide 2: a dated timeline of photo updates.
class OnboardingArtTimeline extends StatelessWidget {
  const OnboardingArtTimeline({super.key});
  @override
  Widget build(BuildContext context) {
    Widget row(String asset, String day, String note, bool first) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 5, backgroundColor: first ? AppColors.orange : AppColors.surfaceDark),
              const SizedBox(width: 14),
              Container(
                width: 240,
                padding: const EdgeInsets.all(10),
                decoration: _cardShadow(AppColors.white, 18),
                child: Row(
                  children: [
                    _photo(asset, width: 56, height: 56, radius: 12),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(day, style: AppText.small),
                          const SizedBox(height: 2),
                          Text(note, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row('onboarding_detail', 'Today', 'Column shuttering done for ground floor', true),
        row('onboarding_site', 'Yesterday', 'First floor slab curing', false),
        row('onboarding_home', 'Sep 2023', 'Handover of Palm Court homes', false),
      ],
    );
  }
}

/// Slide 3 (client): the quick actions on an update.
class OnboardingArtActions extends StatelessWidget {
  const OnboardingArtActions({super.key});
  @override
  Widget build(BuildContext context) {
    Widget pill(IconData icon, String text, {bool dark = false}) => Container(
          width: 250,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: _cardShadow(dark ? AppColors.black : AppColors.white, 30),
          child: Row(
            children: [
              Icon(icon, size: 19, color: dark ? Colors.white : AppColors.text),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: dark ? Colors.white : AppColors.text))),
              if (dark) const CircleAvatar(radius: 12, backgroundColor: AppColors.orange, child: Icon(Icons.check, size: 15, color: Colors.white)),
            ],
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _photo('onboarding_detail', width: 250, height: 110, radius: 20),
        const SizedBox(height: 16),
        pill(Icons.help_outline, 'Ask a question'),
        pill(Icons.edit_outlined, 'Request a change'),
        pill(Icons.thumb_up_alt_outlined, 'Looks good', dark: true),
      ],
    );
  }
}

/// Slide 3 (contractor): a featured portfolio project.
class OnboardingArtPortfolio extends StatelessWidget {
  const OnboardingArtPortfolio({super.key});
  @override
  Widget build(BuildContext context) {
    const star = Icon(Icons.star_rounded, size: 16, color: Color(0xFFF5B90F));
    return Container(
      width: 270,
      decoration: _cardShadow(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.asset('assets/branding/onboarding_home.jpg', height: 170, width: double.infinity, fit: BoxFit.cover),
              ),
              const Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(radius: 16, backgroundColor: Colors.white, child: Icon(Icons.star_rounded, size: 20, color: Color(0xFFF5B90F))),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Palm Court Row Houses', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('Bengaluru · Completed 30 Sep 2023', style: AppText.small),
                SizedBox(height: 10),
                Row(children: [star, star, star, star, star, SizedBox(width: 6), Flexible(child: Text('Client review', overflow: TextOverflow.ellipsis, style: AppText.small))]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
