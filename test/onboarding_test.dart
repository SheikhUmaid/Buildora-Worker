import 'package:buildora_worker/main.dart';
import 'package:buildora_worker/models/models.dart';
import 'package:buildora_worker/providers/auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SignedOut extends AuthNotifier {
  @override
  Future<AppUser?> build() async => null;
}

class _FirstLaunch extends OnboardingNotifier {
  @override
  Future<bool> build() async => false;

  @override
  Future<void> markSeen() async => state = const AsyncData(true);
}

Future<void> _launch(WidgetTester tester) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authProvider.overrideWith(_SignedOut.new),
      onboardingSeenProvider.overrideWith(_FirstLaunch.new),
    ],
    child: const BuildoraWorkerApp(),
  ));
  // Splash has a spinner, so pump frames instead of pumpAndSettle.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  testWidgets('Skip on onboarding opens the login screen', (tester) async {
    await _launch(tester);
    expect(find.text('Post progress in minutes'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Get Started on the last slide opens the login screen', (tester) async {
    await _launch(tester);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });
}
