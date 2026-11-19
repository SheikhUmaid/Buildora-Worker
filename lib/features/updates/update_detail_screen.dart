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
import '../../widgets/thread.dart';
import '../requests/reply_sheet.dart';

/// Engineer / laborer view of a posted update, with edit & delete.
class UpdateDetailScreen extends ConsumerWidget {
  const UpdateDetailScreen({super.key, required this.updateId});
  final String updateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(updateDetailProvider(updateId));
    final me = ref.watch(authProvider).value;
    return Scaffold(
      body: SafeArea(
        child: AsyncBody(
          value: value,
          onRetry: () => ref.invalidate(updateDetailProvider(updateId)),
          data: (d) {
            final u = d.update;
            final canEdit = me != null && (me.isEngineer || u.authorId == me.id);
            final age = DateTime.now().difference(u.createdAt ?? u.date);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      const BackCircle(arrow: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(Fmt.day(u.date), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                            Text('${d.position} of ${d.total} · ${u.projectName}', style: AppText.small),
                          ],
                        ),
                      ),
                      if (canEdit) ...[
                        CircleIconButton(icon: Icons.edit_outlined, tooltip: 'Edit', onTap: () => showEditUpdateSheet(context, ref, u)),
                        const SizedBox(width: 8),
                        CircleIconButton(
                          icon: Icons.delete_outline,
                          tooltip: 'Delete',
                          onTap: () async {
                            final ok = await confirmDialog(context, title: 'Delete this update?', message: 'Photos and the note will be removed for everyone.', confirmLabel: 'Delete', destructive: true);
                            if (!ok || !context.mounted) return;
                            try {
                              await ref.read(repoProvider).deleteUpdate(u.id);
                              if (context.mounted) context.pop();
                            } catch (e) {
                              if (context.mounted) showSnack(context, errorText(e), error: true);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      if (u.photos.isNotEmpty) ...[PhotoCarousel(photos: u.photos, height: 280), const SizedBox(height: 20)],
                      UpdateNoteCard(update: u),
                      if (u.approvalCount > 0) ...[
                        const SizedBox(height: 12),
                        const Row(children: [
                          Icon(Icons.thumb_up_alt_outlined, size: 18, color: AppColors.green),
                          SizedBox(width: 8),
                          Text('Approved by client', style: TextStyle(color: AppColors.green)),
                        ]),
                      ],
                      if (me?.isEngineer == true && u.requestCount > 0) _UpdateRequests(updateId: u.id),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    children: [
                      Text(age.inHours >= 24 ? 'Posted more than 24 hours ago' : 'Posted ${Fmt.relative(u.createdAt)}', style: AppText.muted),
                      const SizedBox(height: 12),
                      AppButton(
                        label: me?.isLaborer == true ? 'Back to posts' : 'Back to project',
                        style: AppButtonStyle.outline,
                        onPressed: () => me?.isLaborer == true ? context.go('/site') : context.pushReplacement('/projects/${u.projectId}'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _UpdateRequests extends ConsumerWidget {
  const _UpdateRequests({required this.updateId});
  final String updateId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(requestsProvider((status: null, projectId: null, updateId: updateId)));
    final list = value.value?.requests ?? const <ClientRequest>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Requests on this update'),
        for (final r in list)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: RequestCard(request: r, forEngineer: true, onTap: () => showReplySheet(context, ref, r.id))),
      ],
    );
  }
}

/// Edit note, photos and people count of an existing update.
Future<void> showEditUpdateSheet(BuildContext context, WidgetRef ref, SiteUpdate u) {
  return showAppSheet<void>(context, title: 'Edit update', builder: (_) => _EditUpdate(update: u));
}

class _EditUpdate extends ConsumerStatefulWidget {
  const _EditUpdate({required this.update});
  final SiteUpdate update;
  @override
  ConsumerState<_EditUpdate> createState() => _EditUpdateState();
}

class _EditUpdateState extends ConsumerState<_EditUpdate> {
  late final _note = TextEditingController(text: widget.update.note);
  late List<String> _existing = [...widget.update.photos];
  List<String> _added = [];
  late int _people = widget.update.totalLaborers;
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref.read(repoProvider).editUpdate(
            widget.update.id,
            note: _note.text.trim(),
            newPhotos: _added,
            removePhotos: widget.update.photos.where((p) => !_existing.contains(p)).toList(),
            totalLaborers: _people != widget.update.totalLaborers ? _people : null,
          );
      if (!mounted) return;
      Navigator.pop(context);
      showSnack(context, 'Update saved');
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PhotoPickerBox(
          photos: _added,
          existing: _existing,
          onChanged: (p) => setState(() => _added = p),
          onRemoveExisting: (p) => setState(() => _existing = [..._existing]..remove(p)),
        ),
        const SizedBox(height: 20),
        AppTextField(label: 'Note', controller: _note, maxLines: 5, minLines: 3, textCapitalization: TextCapitalization.sentences),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: Text('People on site', style: TextStyle(fontSize: 16))),
            CircleIconButton(icon: Icons.remove, size: 36, onTap: _people > 0 ? () => setState(() => _people--) : null),
            SizedBox(width: 44, child: Text('$_people', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16))),
            CircleIconButton(icon: Icons.add, size: 36, onTap: () => setState(() => _people++)),
          ],
        ),
        const SizedBox(height: 24),
        AppButton(label: 'Save changes', loading: _busy, onPressed: _save),
      ],
    );
  }
}
