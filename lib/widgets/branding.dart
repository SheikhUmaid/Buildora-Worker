import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../app_role.dart';
import '../core/theme.dart';
import 'common.dart';

/// Brand mark + "Buildora" wordmark (+ optional badge such as "PRO").
class BuildoraLogo extends StatelessWidget {
  const BuildoraLogo({super.key, this.size = 28, this.light = false});
  final double size; // height of the mark
  final bool light; // white wordmark for dark backgrounds

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : AppColors.text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        BrandMark(size: size),
        SizedBox(width: size * 0.4),
        BrandWordmark(fontSize: size * 0.82, color: color),
      ],
    );
  }
}

/// "Buildora Insight" / "Buildora On-site": brand name in bold, app suffix in orange.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.fontSize = 22, this.color = AppColors.text});
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: kBrandName, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
        if (kAppSuffix.isNotEmpty)
          TextSpan(text: ' $kAppSuffix', style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.orange)),
      ]),
      maxLines: 1,
      style: TextStyle(fontSize: fontSize, letterSpacing: -0.5, height: 1),
    );
  }
}

/// Animated launch screen shown while the saved session is restored.
/// Matches the native splash (white background, centered mark) so the hand-off is seamless.
class BrandSplash extends StatefulWidget {
  const BrandSplash({super.key});
  @override
  State<BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends State<BrandSplash> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _c, curve: const Interval(0.3, 1, curve: Curves.easeOut));
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            ScaleTransition(
              scale: Tween(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack)),
              child: const BrandMark(size: 72),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: fade,
              child: const Column(
                children: [
                  BuildoraLogoText(),
                  SizedBox(height: 8),
                  Text(kAppTagline, style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Spacer(),
            FadeTransition(
              opacity: fade,
              child: const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.orange)),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

/// Wordmark only (used under the big mark on the splash).
class BuildoraLogoText extends StatelessWidget {
  const BuildoraLogoText({super.key, this.fontSize = 34});
  final double fontSize;
  @override
  Widget build(BuildContext context) => BrandWordmark(fontSize: fontSize);
}

/// "Buildora · v1.0.0 (1)" footer for the profile screens.
class AppVersionText extends StatelessWidget {
  const AppVersionText({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (_, snap) {
        final info = snap.data;
        return Column(
          children: [
            const Opacity(opacity: 0.5, child: BuildoraLogo(size: 16)),
            const SizedBox(height: 6),
            Text(info == null ? '' : 'Version ${info.version} (${info.buildNumber})', style: AppText.small),
          ],
        );
      },
    );
  }
}
