import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

// ------------------------------------------------------------------ Haptics

/// Haptic feedback used across the app.
/// - [light]: toggles, chips, tabs, selections, secondary buttons.
/// - [medium]: submit buttons and success.
/// - [error]: something went wrong.
class Haptics {
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void selection() => HapticFeedback.selectionClick();
  static void error() => HapticFeedback.heavyImpact();
}

/// Wraps a [ValueChanged] (switch, checkbox) so it gives a light tap first.
ValueChanged<T>? withHaptic<T>(ValueChanged<T>? onChanged) =>
    onChanged == null ? null : (v) {
      Haptics.light();
      onChanged(v);
    };

// ------------------------------------------------------------------ Press feedback

/// Scales its child down slightly while pressed.
///
/// [builder] receives a callback to hand to `InkWell.onHighlightChanged`, so the
/// scale follows the ripple exactly: it starts on touch and is cancelled when the
/// user scrolls instead of tapping.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.builder, this.scale = 0.97, this.enabled = true});
  final Widget Function(ValueChanged<bool> onHighlightChanged) builder;
  final double scale;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _onHighlight(bool value) {
    if (!mounted || value == _pressed) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: widget.enabled && _pressed ? widget.scale : 1,
      duration: Duration(milliseconds: _pressed ? 90 : 160),
      curve: Curves.easeOut,
      child: widget.builder(_onHighlight),
    );
  }
}

/// Press feedback for any widget with a plain tap handler (photos, thumbnails...):
/// slight scale-down plus a dark overlay while pressed.
class Tappable extends StatefulWidget {
  const Tappable({super.key, required this.child, this.onTap, this.radius = 0, this.haptic = false, this.scale = 0.97});
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final bool haptic;
  final double scale;

  @override
  State<Tappable> createState() => _TappableState();
}

class _TappableState extends State<Tappable> {
  bool _pressed = false;

  void _set(bool v) {
    if (mounted && v != _pressed) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: () {
        if (widget.haptic) Haptics.light();
        widget.onTap!();
      },
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: Duration(milliseconds: _pressed ? 90 : 160),
        curve: Curves.easeOut,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _pressed ? 1 : 0,
                  duration: const Duration(milliseconds: 120),
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(widget.radius)),
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

// ------------------------------------------------------------------ Page transitions

/// One page transition for the whole app: the new page slides in from the right
/// while fading in, and the old page drifts left underneath it.
class SlideFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const SlideFadePageTransitionsBuilder();

  static final _inSlide = Tween<Offset>(begin: const Offset(0.22, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic));
  static final _inFade = CurveTween(curve: const Interval(0, 0.6, curve: Curves.easeOut));
  static final _outSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(-0.08, 0)).chain(CurveTween(curve: Curves.easeOutCubic));

  @override
  Duration get transitionDuration => const Duration(milliseconds: 320);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 260);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: secondaryAnimation.drive(_outSlide),
      child: SlideTransition(
        position: animation.drive(_inSlide),
        child: FadeTransition(opacity: animation.drive(_inFade), child: child),
      ),
    );
  }
}

/// Slide + fade on Android; the native swipe-back slide on iOS.
const appPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: SlideFadePageTransitionsBuilder(),
    TargetPlatform.fuchsia: SlideFadePageTransitionsBuilder(),
    TargetPlatform.linux: SlideFadePageTransitionsBuilder(),
    TargetPlatform.windows: SlideFadePageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
  },
);

/// Fade route for overlays such as the fullscreen photo viewer (pairs well with Hero).
Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut), child: child),
    );

// ------------------------------------------------------------------ Bottom-tab container

/// Keeps every tab alive (like an IndexedStack) but cross-fades between them.
/// Hidden tabs have Hero and tickers disabled so their widgets never interfere
/// with the visible tab's page transitions.
class FadingTabsContainer extends StatelessWidget {
  const FadingTabsContainer({super.key, required this.index, required this.children});
  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          IgnorePointer(
            ignoring: i != index,
            child: AnimatedOpacity(
              opacity: i == index ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: ExcludeFocus(
                excluding: i != index,
                child: TickerMode(
                  enabled: i == index,
                  child: HeroMode(enabled: i == index, child: children[i]),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------------ Hero

/// Shared Hero tags so list cards and detail screens agree.
class HeroTags {
  static String project(String id) => 'project-cover-$id';
  static String update(String id) => 'update-photo-$id';
}

/// Hero that cross-fades from the source to the destination while it flies, so
/// it still looks smooth when the two pictures differ (e.g. a project cover
/// opening into the latest site photo). A null [tag] renders [child] as is.
class AppHero extends StatelessWidget {
  const AppHero({super.key, required this.tag, required this.child});
  final Object? tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = tag;
    if (t == null) return child;
    return Hero(tag: t, flightShuttleBuilder: _crossFadeShuttle, child: child);
  }
}

Widget _crossFadeShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final from = (fromHeroContext.widget as Hero).child;
  final to = (toHeroContext.widget as Hero).child;
  // Push: animation runs 0 -> 1; pop: 1 -> 0. Either way the source fades out.
  final fromOpacity = direction == HeroFlightDirection.push ? ReverseAnimation(animation) : animation;
  return Stack(
    fit: StackFit.expand,
    children: [
      to,
      FadeTransition(opacity: fromOpacity, child: from),
    ],
  );
}
