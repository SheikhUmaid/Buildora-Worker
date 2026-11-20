import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme.dart';

/// Gray shimmering placeholders shown while data loads, shaped like the real content.
///
/// Use the presets ([Skeleton.projects], [Skeleton.updates], [Skeleton.requests],
/// [Skeleton.tiles], [Skeleton.detail], [Skeleton.profile]) or compose your own from
/// [SkeletonBox] / [SkeletonLine] inside a [Skeleton].
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 20)});

  final Widget child;
  final EdgeInsets padding;

  /// Project cards: cover image, name, location, badge, progress.
  factory Skeleton.projects({int count = 2, EdgeInsets padding = const EdgeInsets.fromLTRB(20, 8, 20, 20)}) =>
      Skeleton(padding: padding, child: _repeat(count, const _ProjectCardSkeleton(), gap: 16));

  /// Timeline of update cards (dot + date + card with two photos).
  factory Skeleton.updates({int count = 3, EdgeInsets padding = const EdgeInsets.fromLTRB(20, 8, 20, 20)}) =>
      Skeleton(padding: padding, child: _repeat(count, const _UpdateSkeleton(), gap: 4));

  /// Request cards.
  factory Skeleton.requests({int count = 3, EdgeInsets padding = const EdgeInsets.fromLTRB(20, 8, 20, 20)}) =>
      Skeleton(padding: padding, child: _repeat(count, const _RequestSkeleton(), gap: 14));

  /// Rows with an avatar and two lines (managers, notifications).
  factory Skeleton.tiles({int count = 6, EdgeInsets padding = const EdgeInsets.fromLTRB(20, 8, 20, 20)}) =>
      Skeleton(padding: padding, child: _repeat(count, const _TileSkeleton(), gap: 12));

  /// Detail page: big photo, title, a few info rows, a card.
  factory Skeleton.detail({EdgeInsets padding = const EdgeInsets.fromLTRB(20, 8, 20, 20)}) =>
      Skeleton(padding: padding, child: const _DetailSkeleton());

  /// Profile page: avatar, name, stats, cards.
  factory Skeleton.profile({EdgeInsets padding = const EdgeInsets.fromLTRB(20, 8, 20, 20)}) =>
      Skeleton(padding: padding, child: const _ProfileSkeleton());

  static Widget _repeat(int count, Widget item, {required double gap}) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < count; i++) ...[if (i > 0) SizedBox(height: gap), item],
        ],
      );

  @override
  Widget build(BuildContext context) {
    // Never scrolls; clips when the space is smaller than the placeholder.
    return Semantics(
      label: 'Loading',
      child: SingleChildScrollView(
        primary: false,
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        child: Shimmer.fromColors(
          baseColor: AppColors.surfaceDark,
          highlightColor: const Color(0xFFF8F8F6),
          period: const Duration(milliseconds: 1300),
          child: ExcludeSemantics(child: child),
        ),
      ),
    );
  }
}

/// A standalone shimmering block (image placeholders while a photo downloads).
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({super.key, this.width, this.height});
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: AppColors.surfaceDark,
        highlightColor: const Color(0xFFF8F8F6),
        period: const Duration(milliseconds: 1300),
        child: Container(width: width, height: height, color: Colors.white),
      );
}

/// A solid rounded block inside a [Skeleton].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height, this.radius = 12, this.circle = false});
  final double? width;
  final double? height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// A text-line placeholder. [widthFactor] is a fraction of the available width.
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, this.widthFactor = 1, this.height = 12});
  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widthFactor,
        child: SkeletonBox(height: height, radius: height / 2),
      );
}

/// Outline matching [SurfaceCard], drawn in the shimmer color.
class _CardFrame extends StatelessWidget {
  const _CardFrame({required this.child, this.padding = const EdgeInsets.all(12), this.radius = 24});
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 1.5),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      );
}

class _ProjectCardSkeleton extends StatelessWidget {
  const _ProjectCardSkeleton();
  @override
  Widget build(BuildContext context) => const _CardFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(aspectRatio: 16 / 9, child: SkeletonBox(radius: 18)),
            Padding(
              padding: EdgeInsets.fromLTRB(4, 16, 4, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(widthFactor: 0.55, height: 16),
                  SizedBox(height: 10),
                  SkeletonLine(widthFactor: 0.35),
                  SizedBox(height: 14),
                  SkeletonBox(width: 86, height: 24, radius: 12),
                  SizedBox(height: 18),
                  SkeletonLine(height: 6),
                  SizedBox(height: 14),
                  SkeletonLine(widthFactor: 0.4, height: 10),
                ],
              ),
            ),
          ],
        ),
      );
}

class _UpdateSkeleton extends StatelessWidget {
  const _UpdateSkeleton();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: EdgeInsets.only(top: 2, right: 12), child: SkeletonBox(width: 11, height: 11, circle: true)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(widthFactor: 0.3, height: 11),
                  SizedBox(height: 12),
                  _CardFrame(
                    radius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 110,
                          child: Row(children: [
                            Expanded(child: SkeletonBox(radius: 14)),
                            SizedBox(width: 8),
                            Expanded(child: SkeletonBox(radius: 14)),
                          ]),
                        ),
                        SizedBox(height: 12),
                        SkeletonLine(widthFactor: 0.8),
                        SizedBox(height: 8),
                        SkeletonLine(widthFactor: 0.45, height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _RequestSkeleton extends StatelessWidget {
  const _RequestSkeleton();
  @override
  Widget build(BuildContext context) => const _CardFrame(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              SkeletonBox(width: 36, height: 36, circle: true),
              SizedBox(width: 10),
              Expanded(child: SkeletonLine(widthFactor: 0.5, height: 14)),
              SkeletonBox(width: 56, height: 20, radius: 10),
            ]),
            SizedBox(height: 16),
            SkeletonLine(widthFactor: 0.4, height: 10),
            SizedBox(height: 12),
            SkeletonLine(),
            SizedBox(height: 8),
            SkeletonLine(widthFactor: 0.7),
            SizedBox(height: 20),
            SkeletonLine(widthFactor: 0.3, height: 12),
          ],
        ),
      );
}

class _TileSkeleton extends StatelessWidget {
  const _TileSkeleton();
  @override
  Widget build(BuildContext context) => const _CardFrame(
        radius: 20,
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SkeletonBox(width: 44, height: 44, circle: true),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(widthFactor: 0.55, height: 14),
                  SizedBox(height: 8),
                  SkeletonLine(widthFactor: 0.8, height: 10),
                ],
              ),
            ),
          ],
        ),
      );
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SkeletonBox(height: 240, radius: 24),
          const SizedBox(height: 16),
          const Center(child: SkeletonBox(width: 70, height: 7, radius: 4)),
          const SizedBox(height: 24),
          const SkeletonLine(widthFactor: 0.6, height: 20),
          const SizedBox(height: 12),
          const SkeletonLine(widthFactor: 0.4),
          const SizedBox(height: 20),
          const Row(children: [
            SkeletonBox(width: 90, height: 28, radius: 14),
            SizedBox(width: 10),
            SkeletonBox(width: 70, height: 28, radius: 14),
          ]),
          const SizedBox(height: 24),
          const SkeletonLine(height: 6),
          const SizedBox(height: 28),
          for (var i = 0; i < 3; i++) ...[
            const Row(children: [
              Expanded(child: SkeletonLine(widthFactor: 0.5)),
              Expanded(child: Align(alignment: Alignment.centerRight, child: SkeletonLine(widthFactor: 0.6))),
            ]),
            const SizedBox(height: 22),
          ],
          const SkeletonBox(height: 90, radius: 20),
        ],
      );
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const Center(child: SkeletonBox(width: 88, height: 88, circle: true)),
          const SizedBox(height: 16),
          const Center(child: SizedBox(width: 160, child: SkeletonLine(height: 18))),
          const SizedBox(height: 10),
          const Center(child: SizedBox(width: 110, child: SkeletonLine(height: 11))),
          const SizedBox(height: 28),
          const Row(children: [
            Expanded(child: SkeletonBox(height: 64, radius: 14)),
            SizedBox(width: 10),
            Expanded(child: SkeletonBox(height: 64, radius: 14)),
            SizedBox(width: 10),
            Expanded(child: SkeletonBox(height: 64, radius: 14)),
          ]),
          const SizedBox(height: 24),
          for (var i = 0; i < 4; i++) ...[const SkeletonBox(height: 54, radius: 20), const SizedBox(height: 12)],
        ],
      );
}
