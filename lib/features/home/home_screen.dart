import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/auth.dart';
import '../../providers/data.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/media.dart';
import '../shared/account_screens.dart';
import '../../widgets/branding.dart';

/// Engineer dashboard: stats, projects needing today's update, all projects.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _filter = 0;
  static const _filters = ['All', 'In progress', 'On hold', 'Completed'];
  static const _statusFor = [null, 'in_progress', 'on_hold', 'completed'];

  Future<void> _refresh() async {
    ref.invalidate(dashboardProvider);
    ref.invalidate(notificationsProvider);
    final _ = await ref.refresh(projectsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final projects = ref.watch(projectsProvider);
    final dash = ref.watch(dashboardProvider).value;
    final needs = (dash?['needsUpdate'] as List? ?? []).map((e) => Project.fromJson(e)).toList();
    int stat(String k) => (dash?[k] as num?)?.toInt() ?? 0;

    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 84),
        child: FloatingActionButton(
          heroTag: 'new-project',
          tooltip: 'New project',
          backgroundColor: AppColors.black,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          onPressed: () => context.push('/projects/new'),
          child: const Icon(Icons.add),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
            children: [
              Row(
                children: [
                  const BuildoraLogo(size: 22),
                  const Spacer(),
                  const NotificationBell(),
                  const SizedBox(width: 8),
                  Tappable(radius: 10, scale: 0.9, onTap: () => context.go('/profile'), child: Avatar(name: user?.name ?? '', size: 40, square: true)),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Good to see you', style: AppText.label),
              Text(user?.name ?? '', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              const Text('Your projects', style: AppText.h1),
              const SizedBox(height: 16),
              StatStrip(items: [
                (Fmt.pad2(stat('activeProjects')), 'Active projects'),
                (Fmt.pad2(stat('updatesThisWeek')), 'Updates this week'),
                ('${stat('totalUpdates')}', 'Total updates'),
              ]),
              if (stat('newRequests') > 0) ...[
                const SizedBox(height: 16),
                SurfaceCard(
                  color: AppColors.orangeSoft,
                  onTap: () => context.go('/requests'),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_chat_unread_outlined, color: AppColors.orange),
                      const SizedBox(width: 12),
                      Expanded(child: Text('${Fmt.plural(stat('newRequests'), 'new client request')} waiting', style: const TextStyle(color: AppColors.orange, fontSize: 15))),
                      const Icon(Icons.chevron_right, color: AppColors.orange),
                    ],
                  ),
                ),
              ],
              if (needs.isNotEmpty) ...[
                const SectionTitle("Needs today's update"),
                for (final p in needs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SurfaceCard(
                      padding: const EdgeInsets.all(12),
                      onTap: () => context.push('/projects/${p.id}'),
                      child: Row(
                        children: [
                          SizedBox(width: 56, height: 56, child: NetImage(p.coverImage, radius: 10)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(fontSize: 16)),
                                Text(p.location.split(',').first, style: AppText.small),
                              ],
                            ),
                          ),
                          AppButton(label: 'Post update', expand: false, height: 42, onPressed: () => context.push('/post-update?projectId=${p.id}')),
                        ],
                      ),
                    ),
                  ),
              ],
              const SectionTitle('All projects'),
              ChipFilterBar(padding: EdgeInsets.zero, options: _filters, selected: _filter, onSelected: (i) => setState(() => _filter = i)),
              const SizedBox(height: 16),
              projects.when(
                skipLoadingOnRefresh: true,
                loading: () => LoadingView(skeleton: Skeleton.projects(padding: EdgeInsets.zero)),
                error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(projectsProvider)),
                data: (all) {
                  if (all.isEmpty) {
                    return EmptyState(
                      icon: Icons.add_home_work_outlined,
                      title: 'Create your first project',
                      message: 'Add a site, then share its invite code with your client.',
                      action: AppButton(label: 'New project', expand: false, onPressed: () => context.push('/projects/new')),
                    );
                  }
                  final status = _statusFor[_filter];
                  final list = status == null ? all : all.where((p) => p.status == status).toList();
                  if (list.isEmpty) return const EmptyState(icon: Icons.filter_alt_off_outlined, title: 'Nothing here');
                  return Column(
                    children: [
                      for (final p in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ProjectCard(project: p, onTap: () => context.push('/projects/${p.id}')),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
