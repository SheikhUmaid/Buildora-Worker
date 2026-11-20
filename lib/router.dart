import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'features/auth/auth_screens.dart';
import 'features/home/home_screen.dart';
import 'features/laborers/laborers_screen.dart';
import 'features/portfolio/portfolio_screen.dart';
import 'features/post_update/post_update_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/project/project_detail_screen.dart';
import 'features/project/project_form_screen.dart';
import 'features/requests/reply_sheet.dart';
import 'features/requests/requests_tab.dart';
import 'features/shared/account_screens.dart';
import 'features/shared/onboarding_view.dart';
import 'features/site/site_posts_screen.dart';
import 'features/updates/update_detail_screen.dart';
import 'providers/auth.dart';
import 'providers/data.dart';
import 'widgets/common.dart';
import 'widgets/branding.dart';

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authProvider, (_, _) => notifyListeners());
    ref.listen(onboardingSeenProvider, (_, _) => notifyListeners());
  }
}

const _publicRoutes = {'/onboarding', '/login', '/signup', '/labour-login', '/forgot-password'};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final seen = ref.read(onboardingSeenProvider);
      final loc = state.matchedLocation;
      if (auth.isLoading || seen.isLoading) return loc == '/splash' ? null : '/splash';

      final user = auth.value;
      if (user == null) {
        if (seen.value != true) return loc == '/onboarding' ? null : '/onboarding';
        // Onboarding finished (Skip / Get Started): move on to login.
        if (loc == '/onboarding' || loc == '/splash') return '/login';
        return _publicRoutes.contains(loc) ? null : '/login';
      }
      // Laborers only get the site posting screens.
      if (user.isLaborer) {
        final allowed = loc == '/site' || loc.startsWith('/updates/');
        return allowed ? null : '/site';
      }
      if (_publicRoutes.contains(loc) || loc == '/splash' || loc == '/site') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const _Splash()),
      GoRoute(path: '/onboarding', builder: (_, _) => const _Onboarding()),
      GoRoute(path: '/login', builder: (_, _) => const AuthScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const AuthScreen(signup: true)),
      GoRoute(path: '/labour-login', builder: (_, _) => const LabourLoginScreen()),
      GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: '/site', builder: (_, _) => const SitePostsScreen()),
      StatefulShellRoute(
        // Tabs stay alive but cross-fade when switching (see FadingTabsContainer).
        navigatorContainerBuilder: (context, shell, children) => FadingTabsContainer(index: shell.currentIndex, children: children),
        builder: (context, state, shell) => _Shell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/requests', builder: (_, _) => const RequestsTab())]),
          StatefulShellBranch(routes: [GoRoute(path: '/portfolio', builder: (_, _) => const PortfolioScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())]),
        ],
      ),
      GoRoute(path: '/projects/new', builder: (_, _) => const ProjectFormScreen()),
      GoRoute(path: '/projects/:id', builder: (_, s) => ProjectDetailScreen(projectId: s.pathParameters['id']!)),
      GoRoute(path: '/projects/:id/edit', builder: (_, s) => ProjectFormScreen(projectId: s.pathParameters['id'])),
      GoRoute(path: '/post-update', builder: (_, s) => PostUpdateScreen(projectId: s.uri.queryParameters['projectId'])),
      GoRoute(path: '/updates/:id', builder: (_, s) => UpdateDetailScreen(updateId: s.pathParameters['id']!)),
      GoRoute(path: '/requests/:id', builder: (_, s) => RequestReplyScreen(requestId: s.pathParameters['id']!)),
      GoRoute(path: '/portfolio/:id', builder: (_, s) => CaseStudyEditorScreen(projectId: s.pathParameters['id']!)),
      GoRoute(path: '/laborers', builder: (_, _) => const LaborersScreen()),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: '/profile/edit', builder: (_, _) => const EngineerEditProfileScreen()),
      GoRoute(path: '/profile/password', builder: (_, _) => const ChangePasswordScreen()),
    ],
  );
});

class _Splash extends ConsumerWidget {
  const _Splash();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth.hasError) {
      return Scaffold(body: ErrorView(error: auth.error!, onRetry: () => ref.invalidate(authProvider)));
    }
    return const BrandSplash();
  }
}

class _Onboarding extends ConsumerWidget {
  const _Onboarding();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnboardingView(
      onDone: () => ref.read(onboardingSeenProvider.notifier).markSeen(),
      slides: const [
        OnboardingSlide(
          title: 'Post progress in minutes',
          body: "Site photos, a short note, and today's team. Ready before you leave site.",
          art: OnboardingArtCard(),
        ),
        OnboardingSlide(
          title: 'Keep every client informed',
          body: 'A clear daily record of your work, with every client request in one place.',
          art: OnboardingArtTimeline(),
        ),
        OnboardingSlide(
          title: 'Build your portfolio as you work',
          body: 'From first foundations to final handover. Your best work, all together.',
          art: OnboardingArtPortfolio(),
        ),
      ],
    );
  }
}

class _Shell extends ConsumerWidget {
  const _Shell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newRequests = (ref.watch(dashboardProvider).value?['newRequests'] as num?)?.toInt() ?? 0;
    final unread = ref.watch(unreadCountProvider);
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: FloatingNavBar(
        index: shell.currentIndex,
        badges: {1: newRequests, 3: unread},
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        items: const [
          NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
          NavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'Requests'),
          NavItem(Icons.work_outline, Icons.work, 'Portfolio'),
          NavItem(Icons.person_outline, Icons.person, 'Profile'),
        ],
      ),
    );
  }
}
