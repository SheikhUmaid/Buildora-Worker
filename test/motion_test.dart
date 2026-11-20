import 'package:buildora_worker/core/theme.dart';
import 'package:buildora_worker/widgets/common.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget home) => MaterialApp(theme: AppTheme.light(), home: home);

void main() {
  testWidgets('skeletons lay out in fixed-height and scrolling parents', (tester) async {
    await tester.pumpWidget(_app(Scaffold(
      body: Column(
        children: [
          SizedBox(height: 200, child: Skeleton.detail()),
          Expanded(
            child: ListView(children: [Skeleton.projects(), Skeleton.updates(), Skeleton.requests(), Skeleton.tiles(), Skeleton.profile()]),
          ),
        ],
      ),
    )));
    await tester.pump(const Duration(milliseconds: 500)); // shimmer loops forever: no pumpAndSettle
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Loading'), findsWidgets);
  });

  testWidgets('hero flies from the visible tab while a hidden tab has the same tag', (tester) async {
    const tag = 'project-cover-1';
    Widget card(BuildContext context) => SurfaceCard(
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: AppHero(tag: tag, child: SizedBox(width: 300, height: 200, child: ColoredBox(color: Colors.orange)))),
          )),
          child: const AppHero(tag: tag, child: SizedBox(width: 100, height: 60, child: ColoredBox(color: Colors.black))),
        );

    await tester.pumpWidget(_app(Scaffold(
      body: Builder(
        builder: (context) => FadingTabsContainer(
          index: 0,
          // Both tabs show the same card; only the visible one may take part in the flight.
          children: [Center(child: card(context)), Center(child: card(context))],
        ),
      ),
    )));

    await tester.tap(find.byType(SurfaceCard).first, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.byType(ColoredBox).evaluate().where((e) => (e.widget as ColoredBox).color == Colors.orange), isNotEmpty);
  });

  testWidgets('chips and buttons scale down while pressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_app(Scaffold(
      body: Center(child: AppButton(label: 'Post', expand: false, onPressed: () => taps++)),
    )));
    final gesture = await tester.startGesture(tester.getCenter(find.text('Post')));
    await tester.pump(const Duration(milliseconds: 200));
    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale).first).scale;
    expect(scale, lessThan(1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale).first).scale, 1);
  });
}
