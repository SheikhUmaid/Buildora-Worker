import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/data.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/contact.dart';
import '../../widgets/media.dart';
import '../requests/reply_sheet.dart';
import 'invite_sheet.dart';

/// Engineer's project page with Updates / Requests / Info tabs.
class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});
  final String projectId;

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  int _tab = 0;
  int _requestFilter = 0;

  String get _id => widget.projectId;

  Future<void> _refresh() async {
    ref.invalidate(projectUpdatesProvider(_id));
    ref.invalidate(requestsProvider);
    final _ = await ref.refresh(projectDetailProvider(_id).future);
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(projectDetailProvider(_id));
    final project = detail.value?.project;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: project?.name ?? 'Project',
              trailing: project == null ? null : CircleIconButton(icon: Icons.more_horiz, tooltip: 'Project options', onTap: () => showProjectOptions(context, ref, project)),
            ),
            Expanded(
              child: AsyncBody(loading: Skeleton.detail(), 
                value: detail,
                onRetry: () => ref.invalidate(projectDetailProvider(_id)),
                data: (d) => RefreshIndicator(onRefresh: _refresh, child: _body(d)),
              ),
            ),
            if (project != null && !project.isCompleted)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: AppButton(
                  label: project.updatedToday ? 'Post another update' : "Post today's update",
                  alignStart: true,
                  trailingArrow: true,
                  onPressed: () => context.push('/post-update?projectId=${project.id}'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body(ProjectDetail d) {
    final p = d.project;
    final latest = d.latestUpdate;
    final photos = [...?latest?.photos];
    if (photos.isEmpty && p.coverImage.isNotEmpty) photos.add(p.coverImage);
    final client = p.primaryClient;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        PhotoCarousel(
          photos: photos,
          heroTag: HeroTags.project(p.id),
          height: 220,
          showArrows: true,
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.updatedToday ? 'Today' : Fmt.dayShort(DateTime.now()), style: const TextStyle(fontSize: 15)),
              Text(p.updatedToday ? 'Updated' : 'No update', style: AppText.small),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            StatusBadge(p.status),
            const Spacer(),
            if (p.location.isNotEmpty) Flexible(child: LocationText(p.location, size: 14)),
          ],
        ),
        const SizedBox(height: 18),
        ProgressRow(progress: p.progress),
        const SizedBox(height: 18),
        AppButton(label: 'Update progress', style: AppButtonStyle.outline, onPressed: () => showProgressSheet(context, ref, p)),
        const SizedBox(height: 20),
        const Text('Client', style: AppText.muted),
        const SizedBox(height: 10),
        if (client == null)
          SurfaceCard(
            onTap: () => showInviteSheet(context, p),
            child: Row(
              children: [
                const Icon(Icons.person_add_alt_outlined),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Invite your client', style: TextStyle(fontSize: 16)),
                      Text('Code ${p.inviteCode ?? ''}', style: AppText.small),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          )
        else
          for (final c in p.clients)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SurfaceCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Avatar(name: c.name, size: 44),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name, style: const TextStyle(fontSize: 17)),
                              if (c.phone.isNotEmpty) Text(c.phone, style: AppText.small),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (c.phone.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      ContactButtons(phone: c.phone, whatsappMessage: 'Hi ${c.name.split(' ').first}, update on ${p.name}: '),
                    ],
                  ],
                ),
              ),
            ),
        const SizedBox(height: 20),
        PillTabs(tabs: ['Updates', p.openRequests > 0 ? 'Requests (${p.openRequests})' : 'Requests', 'Info'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
        const SizedBox(height: 20),
        switch (_tab) {
          0 => _UpdatesTab(project: p),
          1 => _RequestsTab(projectId: p.id, filter: _requestFilter, onFilter: (i) => setState(() => _requestFilter = i)),
          _ => _InfoTab(project: p),
        },
      ],
    );
  }
}

// ======================================================================= Tabs

/// Day-by-day timeline including days without an update ("No update").
class _UpdatesTab extends ConsumerWidget {
  const _UpdatesTab({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(projectUpdatesProvider(project.id));
    return value.when(
      skipLoadingOnRefresh: true,
      loading: () => LoadingView(skeleton: Skeleton.updates(padding: EdgeInsets.zero)),
      error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(projectUpdatesProvider(project.id))),
      data: (updates) {
        final byDay = <DateTime, List<SiteUpdate>>{};
        for (final u in updates) {
          byDay.putIfAbsent(DateTime(u.date.year, u.date.month, u.date.day), () => []).add(u);
        }
        final today = DateTime.now();
        final start = project.startDate ?? today;
        // Show recent days (max 30) plus every older day that has an update.
        final days = <DateTime>{};
        for (var i = 0; i < 30; i++) {
          final d = DateTime(today.year, today.month, today.day - i);
          if (d.isBefore(DateTime(start.year, start.month, start.day))) break;
          days.add(d);
        }
        days.addAll(byDay.keys);
        final sorted = days.toList()..sort((a, b) => b.compareTo(a));
        if (sorted.isEmpty) return const EmptyState(icon: Icons.photo_library_outlined, title: 'No updates yet');
        return Column(
          children: [
            for (var i = 0; i < sorted.length; i++)
              TimelineEntry(
                label: Fmt.dayShort(sorted[i]),
                sublabel: byDay[sorted[i]] == null ? 'No update' : null,
                highlight: byDay[sorted[i]] != null && i == 0,
                isLast: i == sorted.length - 1,
                child: byDay[sorted[i]] == null
                    ? null
                    : Column(
                        children: [
                          for (final u in byDay[sorted[i]]!)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _CompactUpdate(update: u, onTap: () => context.push('/updates/${u.id}')),
                            ),
                        ],
                      ),
              ),
          ],
        );
      },
    );
  }
}

class _CompactUpdate extends StatelessWidget {
  const _CompactUpdate({required this.update, required this.onTap});
  final SiteUpdate update;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      radius: 12,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, height: 64, child: update.photos.isEmpty
                ? NetImage(null, radius: 10)
                : AppHero(tag: HeroTags.update(update.id), child: NetImage(update.photos.first, radius: 10))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(update.note.isEmpty ? 'Site photos' : update.note, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  [update.summary, if (update.byLaborer) 'by ${update.authorName}', if (update.requestCount > 0) Fmt.plural(update.requestCount, 'request')]
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                  style: AppText.small,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab({required this.projectId, required this.filter, required this.onFilter});
  final String projectId;
  final int filter;
  final ValueChanged<int> onFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (status: const [null, 'new', 'in_progress', 'done'][filter], projectId: projectId, updateId: null);
    final value = ref.watch(requestsProvider(query));
    return Column(
      children: [
        ChipFilterBar(padding: EdgeInsets.zero, options: const ['All', 'New', 'In progress', 'Done'], selected: filter, onSelected: onFilter),
        const SizedBox(height: 16),
        value.when(
          skipLoadingOnRefresh: true,
          loading: () => LoadingView(skeleton: Skeleton.requests(count: 2, padding: EdgeInsets.zero)),
          error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(requestsProvider(query))),
          data: (res) => res.requests.isEmpty
              ? const EmptyState(icon: Icons.chat_bubble_outline, title: 'No requests', message: 'Client questions and change requests show up here.')
              : Column(
                  children: [
                    for (final r in res.requests)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RequestCard(request: r, forEngineer: true, onTap: () => showReplySheet(context, ref, r.id)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _InfoTab extends ConsumerWidget {
  const _InfoTab({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = project;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InfoRow(label: 'Start date', value: Fmt.date(p.startDate)),
        InfoRow(label: 'Expected finish', value: Fmt.monthYear(p.expectedFinish)),
        if (p.isCompleted) InfoRow(label: 'Completed', value: Fmt.date(p.completedAt)),
        InfoRow(label: 'Budget', value: Fmt.budget(p.budget)),
        InfoRow(label: 'Budget visibility', value: p.budgetVisible ? 'Shared' : 'Private'),
        InfoRow(label: 'Location', value: p.location.isEmpty ? '—' : p.location),
        if (p.address.isNotEmpty) InfoRow(label: 'Address', value: p.address),
        InfoRow(label: 'Client', value: p.clients.isEmpty ? 'Not joined yet' : p.clientNames),
        InfoRow(label: 'Invite code', value: p.inviteCode ?? '—'),
        InfoRow(label: 'Updates · Photos', value: '${p.updatesCount} · ${p.photosCount}'),
        InfoRow(label: 'Peak laborers', value: '${p.peakLaborers}', divider: false),
        if (p.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(p.description, style: AppText.muted),
        ],
        const SizedBox(height: 20),
        if (!p.isCompleted)
          AppButton(
            label: 'Mark project as completed',
            style: AppButtonStyle.orange,
            alignStart: true,
            trailingArrow: true,
            onPressed: () async {
              final ok = await confirmDialog(context,
                  title: 'Mark as completed?', message: 'Progress will be set to 100% and your client will be notified. It will appear in your portfolio.', confirmLabel: 'Complete');
              if (!ok || !context.mounted) return;
              try {
                await ref.read(repoProvider).setProjectStatus(p.id, 'completed');
                if (context.mounted) showSnack(context, '${p.name} marked as completed');
              } catch (e) {
                if (context.mounted) showSnack(context, errorText(e), error: true);
              }
            },
          )
        else
          AppButton(label: 'Open portfolio case study', style: AppButtonStyle.outline, onPressed: () => context.push('/portfolio/${p.id}')),
      ],
    );
  }
}

// ======================================================================= Sheets

Future<void> showProgressSheet(BuildContext context, WidgetRef ref, Project p) async {
  var value = p.progress.toDouble();
  final save = await showAppSheet<bool>(
    context,
    title: 'Update progress',
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Project progress', style: TextStyle(fontSize: 18))),
              Text('${value.round()}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 100,
            onChanged: (v) {
              if (v ~/ 10 != value ~/ 10) Haptics.selection();
              setState(() => value = v);
            },
          ),
          const SizedBox(height: 16),
          AppButton(label: 'Save', onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    ),
  );
  if (save != true || !context.mounted) return;
  try {
    await ref.read(repoProvider).setProjectProgress(p.id, value.round());
  } catch (e) {
    if (context.mounted) showSnack(context, errorText(e), error: true);
  }
}

Future<void> showProjectOptions(BuildContext context, WidgetRef ref, Project p) async {
  final action = await showAppSheet<String>(
    context,
    title: 'Project options',
    builder: (ctx) {
      Widget item(String label, String value, {bool danger = false}) => InkWell(
            onTap: () => Navigator.pop(ctx, value),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Text(label, style: TextStyle(fontSize: 17, color: danger ? AppColors.red : AppColors.text)),
            ),
          );
      return Column(
        children: [
          item('Edit project', 'edit'),
          item('Change status', 'status'),
          item('Share invite code', 'invite'),
          if (p.clients.isNotEmpty) item('Manage clients', 'clients'),
          item('Managers on this project', 'laborers'),
          if (p.isCompleted) item('Portfolio case study', 'portfolio'),
          item('Delete project', 'delete', danger: true),
        ],
      );
    },
  );
  if (action == null || !context.mounted) return;
  final repo = ref.read(repoProvider);
  switch (action) {
    case 'edit':
      context.push('/projects/${p.id}/edit');
    case 'invite':
      await showInviteSheet(context, p);
    case 'laborers':
      context.push('/laborers');
    case 'portfolio':
      context.push('/portfolio/${p.id}');
    case 'status':
      final status = await showAppSheet<String>(
        context,
        title: 'Change status',
        builder: (ctx) => Column(
          children: [
            for (final s in const ['in_progress', 'on_hold', 'completed'])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(Fmt.statusLabel(s)),
                trailing: p.status == s ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, s),
              ),
          ],
        ),
      );
      if (status != null && status != p.status) {
        try {
          await repo.setProjectStatus(p.id, status);
        } catch (e) {
          if (context.mounted) showSnack(context, errorText(e), error: true);
        }
      }
    case 'clients':
      await showAppSheet<void>(
        context,
        title: 'Clients',
        builder: (ctx) => Column(
          children: [
            for (final c in p.clients)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Avatar(name: c.name),
                title: Text(c.name),
                subtitle: Text(c.email),
                trailing: TextButton(
                  onPressed: () async {
                    final ok = await confirmDialog(ctx, title: 'Remove ${c.name}?', message: 'They will no longer see this project.', confirmLabel: 'Remove', destructive: true);
                    if (!ok) return;
                    await repo.removeClient(p.id, c.id);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Remove', style: TextStyle(color: AppColors.red)),
                ),
              ),
          ],
        ),
      );
    case 'delete':
      final ok = await confirmDialog(context,
          title: 'Delete ${p.name}?', message: 'All updates, photos and requests for this project will be permanently deleted.', confirmLabel: 'Delete', destructive: true);
      if (!ok || !context.mounted) return;
      try {
        await repo.deleteProject(p.id);
        if (context.mounted) context.go('/home');
      } catch (e) {
        if (context.mounted) showSnack(context, errorText(e), error: true);
      }
  }
}
