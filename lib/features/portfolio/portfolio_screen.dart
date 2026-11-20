import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import '../../widgets/media.dart';
import '../shared/case_study_view.dart';

/// "Built by you" portfolio: Completed / Ongoing / Hidden.
class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});
  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(portfolioProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AsyncBody(loading: Skeleton.projects(), 
          value: value,
          onRetry: () => ref.invalidate(portfolioProvider),
          data: (data) {
            final (stats, all) = data;
            final list = switch (_tab) {
              0 => all.where((p) => p.status == 'completed' && !p.hidden).toList(),
              1 => all.where((p) => p.status != 'completed' && !p.hidden).toList(),
              _ => all.where((p) => p.hidden).toList(),
            };
            return RefreshIndicator(
              onRefresh: () => ref.refresh(portfolioProvider.future),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  const Text('Built by you', style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
                  const Text('Portfolio', style: AppText.h1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: StatTile(boxed: true, value: Fmt.pad2((stats['activeProjects'] as num?)?.toInt() ?? 0), label: 'Active projects')),
                      const SizedBox(width: 8),
                      Expanded(child: StatTile(boxed: true, value: '${stats['updatesPosted'] ?? 0}', label: 'Updates posted')),
                      const SizedBox(width: 8),
                      Expanded(child: StatTile(boxed: true, value: '${stats['yearsExperience'] ?? 0}', label: 'Years exp')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  PillTabs(tabs: const ['Completed', 'Ongoing', 'Hidden'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
                  const SizedBox(height: 20),
                  if (list.isEmpty)
                    EmptyState(
                      icon: Icons.work_outline,
                      title: switch (_tab) { 0 => 'No completed projects yet', 1 => 'No ongoing projects', _ => 'Nothing hidden' },
                      message: _tab == 0 ? 'Mark a project as completed to showcase it here.' : null,
                    ),
                  for (final p in list) Padding(padding: const EdgeInsets.only(bottom: 16), child: _PortfolioCardView(card: p)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PortfolioCardView extends ConsumerWidget {
  const _PortfolioCardView({required this.card});
  final PortfolioCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(repoProvider);
    return SurfaceCard(
      padding: EdgeInsets.zero,
      radius: 24,
      onTap: () => context.push('/portfolio/${card.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), child: NetImage(card.coverImage)),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _RoundToggle(
                        icon: card.featured ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: card.featured ? const Color(0xFFF5B90F) : AppColors.text,
                        tooltip: card.featured ? 'Unpin from featured' : 'Pin to featured',
                        onTap: () => repo.updatePortfolio(card.id, {'featured': !card.featured}),
                      ),
                      const SizedBox(width: 8),
                      _RoundToggle(
                        icon: card.visibleToClients ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        tooltip: card.visibleToClients ? 'Visible to clients' : 'Hidden from clients',
                        onTap: () => repo.updatePortfolio(card.id, {'visibleToClients': !card.visibleToClients}),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  [
                    if (card.location.isNotEmpty) card.location.split(',').last.trim(),
                    if (card.completedAt != null) 'Completed ${Fmt.date(card.completedAt)}' else '${card.progress}% · ${Fmt.statusLabel(card.status)}',
                  ].join(' · '),
                  style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundToggle extends StatelessWidget {
  const _RoundToggle({required this.icon, required this.onTap, required this.tooltip, this.color = AppColors.text});
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, size: 20, color: color))),
        ),
      );
}

// ======================================================================= Case study editor

class CaseStudyEditorScreen extends ConsumerWidget {
  const CaseStudyEditorScreen({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(caseStudyProvider(projectId));
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PageHeader(title: 'Case study'),
            Expanded(
              child: AsyncBody(loading: Skeleton.detail(), 
                value: value,
                onRetry: () => ref.invalidate(caseStudyProvider(projectId)),
                data: (s) => _Editor(study: s),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Editor extends ConsumerWidget {
  const _Editor({required this.study});
  final CaseStudy study;

  Future<void> _run(BuildContext context, Future<void> Function() action, [String? done]) async {
    try {
      await action();
      if (done != null && context.mounted) showSnack(context, done);
    } catch (e) {
      if (context.mounted) showSnack(context, errorText(e), error: true);
    }
  }

  Future<void> _editStory(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: study.story);
    final save = await showAppSheet<bool>(
      context,
      title: 'The story',
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Challenge, what you built, and the result.', style: AppText.muted),
          const SizedBox(height: 12),
          AppTextField(controller: controller, maxLines: 8, minLines: 5, maxLength: 1500, textCapitalization: TextCapitalization.sentences),
          const SizedBox(height: 20),
          AppButton(label: 'Save story', onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    final text = controller.text.trim();
    controller.dispose();
    if (save == true && context.mounted) {
      await _run(context, () => ref.read(repoProvider).updatePortfolio(study.id, {'story': text}), 'Story saved');
    }
  }

  Future<void> _pickHighlights(BuildContext context, WidgetRef ref) async {
    final selected = [...study.highlights];
    final save = await showAppSheet<bool>(
      context,
      title: 'Choose highlights',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${selected.length}/12 selected · tap in order, first is the cover', style: AppText.muted),
            const SizedBox(height: 12),
            if (study.allPhotos.isEmpty) const Text('No site photos yet. Use "Add photos" to upload some.', style: AppText.muted),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [
                for (final p in {...study.highlights, ...study.allPhotos})
                  Tappable(
                    radius: 12,
                    haptic: true,
                    onTap: () => setState(() {
                      if (selected.contains(p)) {
                        selected.remove(p);
                      } else if (selected.length < 12) {
                        selected.add(p);
                      }
                    }),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        NetImage(p, radius: 10),
                        if (selected.contains(p))
                          Container(
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.orange, width: 3), color: Colors.black26),
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.all(6),
                            child: CircleAvatar(radius: 11, backgroundColor: AppColors.orange, child: Text('${selected.indexOf(p) + 1}', style: const TextStyle(fontSize: 11, color: Colors.white))),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            AppButton(label: 'Save highlights', onPressed: () => Navigator.pop(ctx, true)),
          ],
        ),
      ),
    );
    if (save == true && context.mounted) {
      await _run(context, () => ref.read(repoProvider).updatePortfolio(study.id, {'highlights': selected}), 'Highlights saved');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = study;
    final repo = ref.read(repoProvider);
    void toggle(String key, bool value) => _run(context, () => repo.updatePortfolio(s.id, {key: value}));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        if (s.coverImage.isNotEmpty) ...[AspectRatio(aspectRatio: 1.6, child: NetImage(s.coverImage, radius: 20)), const SizedBox(height: 20)],
        CaseStudyHeader(study: s),
        SectionTitle('The story', trailing: TextButton(onPressed: () => _editStory(context, ref), child: const Text('Edit', style: TextStyle(color: AppColors.textMuted)))),
        Text(s.story.isEmpty ? 'Tell clients what made this project special.' : s.story, style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.textMuted)),
        SectionTitle('Highlights', trailing: TextButton(onPressed: () => _pickHighlights(context, ref), child: const Text('Choose', style: TextStyle(color: AppColors.textMuted)))),
        Text('${s.highlights.length}/12 selected · first photo is the cover', style: AppText.muted),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < s.highlights.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () => openPhotoViewer(context, s.highlights, i),
                        onLongPress: i == 0
                            ? null
                            : () {
                                Haptics.medium();
                                _run(context, () => repo.updatePortfolio(s.id, {'highlights': [s.highlights[i], ...s.highlights.where((h) => h != s.highlights[i])]}), 'Cover updated');
                              },
                        child: SizedBox(width: 110, height: 110, child: NetImage(s.highlights[i], radius: 14)),
                      ),
                      if (i == 0)
                        Positioned(
                          left: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(10)),
                            child: const Text('cover', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        ),
                    ],
                  ),
                ),
              Tappable(
                radius: 14,
                onTap: () async {
                  final picked = await pickPhotos(context, camera: false, max: 12 - s.highlights.length);
                  if (picked.isNotEmpty && context.mounted) await _run(context, () => repo.uploadPortfolioPhotos(s.id, picked), 'Photos added');
                },
                child: Container(
                  width: 110,
                  decoration: BoxDecoration(border: Border.all(color: AppColors.textFaint), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [const Icon(Icons.add_photo_alternate_outlined), const SizedBox(height: 4), const Text('Add photos'), Text('${s.highlights.length} / 12', style: AppText.small)],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (s.highlights.length > 1) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Long-press a photo to make it the cover', style: AppText.small)),
        const SectionTitle('Client feedback'),
        if (s.feedback.isEmpty) const Text('No reviews yet. Clients can rate a project once it is completed.', style: AppText.muted),
        for (final f in s.feedback)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FeedbackCard(
              feedback: f,
              trailing: Row(
                children: [
                  const Expanded(child: Text('Show on portfolio', style: TextStyle(fontSize: 15))),
                  Switch(value: f.showOnPortfolio, onChanged: withHaptic((v) => _run(context, () => repo.setFeedbackVisibility(s.id, f.id, v)))),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(20), color: AppColors.surface),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Privacy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
              _SwitchRow(label: 'Visible to clients', value: s.visibleToClients, onChanged: (v) => toggle('visibleToClients', v)),
              _SwitchRow(label: 'Show exact location', value: s.showExactLocation, onChanged: (v) => toggle('showExactLocation', v)),
              _SwitchRow(label: 'Show client name', value: s.showClientName, onChanged: (v) => toggle('showClientName', v)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppButton(
          label: s.featured ? 'Unpin from featured' : 'Pin to featured',
          style: AppButtonStyle.outline,
          onPressed: () => _run(context, () => repo.updatePortfolio(s.id, {'featured': !s.featured})),
        ),
        const SizedBox(height: 12),
        AppButton(label: 'Edit project', style: AppButtonStyle.outline, onPressed: () => context.push('/projects/${s.id}/edit')),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: s.hidden ? 'Unhide' : 'Hide',
                style: AppButtonStyle.outline,
                onPressed: () => _run(context, () => repo.updatePortfolio(s.id, {'hidden': !s.hidden}), s.hidden ? 'Back in your portfolio' : 'Hidden from portfolio'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Remove',
                style: AppButtonStyle.danger,
                onPressed: () async {
                  final ok = await confirmDialog(context,
                      title: 'Remove from portfolio?', message: 'The project itself is kept. It just will not appear in your portfolio.', confirmLabel: 'Remove', destructive: true);
                  if (!ok || !context.mounted) return;
                  await _run(context, () => repo.updatePortfolio(s.id, {'included': false}), 'Removed from portfolio');
                  if (context.mounted) context.pop();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Switch(value: value, onChanged: withHaptic(onChanged)),
        ],
      );
}
