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
        Text(
          kAppName,
          style: TextStyle(fontSize: size * 0.82, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: color, height: 1),
        ),
        if (kAppBadge.isNotEmpty) ...[
          SizedBox(width: size * 0.25),
          Container(
            padding: EdgeInsets.symmetric(horizontal: size * 0.2, vertical: size * 0.06),
            decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(size)),
            child: Text(kAppBadge, style: TextStyle(fontSize: size * 0.34, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.6)),
          ),
        ],
      ],
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
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(kAppName, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, letterSpacing: -1)),
        if (kAppBadge.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(20)),
            child: Text(kAppBadge, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.8)),
          ),
        ],
      ],
    );
  }
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
