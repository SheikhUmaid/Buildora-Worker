import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/auth.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import '../../widgets/media.dart';
import '../updates/update_detail_screen.dart';

/// Manager home: "Site posts" with New post / My posts.
class SitePostsScreen extends ConsumerStatefulWidget {
  const SitePostsScreen({super.key});
  @override
  ConsumerState<SitePostsScreen> createState() => _SitePostsScreenState();
}

class _SitePostsScreenState extends ConsumerState<SitePostsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    if (user == null) return const Scaffold(body: LoadingView());
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Avatar(name: user.engineer?.name ?? user.name, size: 44, square: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Site posts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                        Text('${user.name}${user.trade.isNotEmpty ? ' · ${user.trade}' : ''}', style: AppText.muted),
                      ],
                    ),
                  ),
                  CircleIconButton(
                    icon: Icons.logout,
                    tooltip: 'Log out',
                    onTap: () async {
                      if (await confirmDialog(context, title: 'Log out?', message: 'You will need your phone and PIN to log in again.', confirmLabel: 'Log out')) {
                        await ref.read(authProvider.notifier).logout();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PillTabs(tabs: const ['New post', 'My posts'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
            ),
            Expanded(
              child: user.projects.isEmpty
                  ? const EmptyState(icon: Icons.construction_outlined, title: 'No site assigned', message: 'Ask your contractor to assign you to a project.')
                  : _tab == 0
                      ? _NewPost(user: user, onPosted: () => setState(() => _tab = 1))
                      : const _MyPosts(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewPost extends ConsumerStatefulWidget {
  const _NewPost({required this.user, required this.onPosted});
  final AppUser user;
  final VoidCallback onPosted;
  @override
  ConsumerState<_NewPost> createState() => _NewPostState();
}

class _NewPostState extends ConsumerState<_NewPost> {
  late String _projectId = widget.user.projects.first.id;
  List<String> _photos = [];
  String? _voice;
  final _note = TextEditingController();
  bool _showNote = false;
  int _people = 1;
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (_photos.isEmpty && _note.text.trim().isEmpty && _voice == null) {
      return showSnack(context, 'Add a photo, a note or a voice note', error: true);
    }
    setState(() => _busy = true);
    try {
      await ref.read(repoProvider).postUpdate(
            _projectId,
            photos: _photos,
            note: _note.text.trim(),
            voicePath: _voice,
            totalLaborers: _people,
            laborers: [LaborerCount(widget.user.trade.isEmpty ? 'General' : widget.user.trade, _people)],
          );
      if (!mounted) return;
      setState(() {
        _photos = [];
        _voice = null;
        _note.clear();
        _showNote = false;
      });
      showSnack(context, 'Posted! Your contractor can see it now.');
      widget.onPosted();
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = widget.user.projects;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            children: [
              if (projects.length == 1)
                Text(projects.first.name, style: const TextStyle(fontSize: 18))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final p in projects) AppChip(label: p.name, selected: _projectId == p.id, onTap: () => setState(() => _projectId = p.id))],
                ),
              const SizedBox(height: 16),
              PhotoPickerBox(photos: _photos, onChanged: (p) => setState(() => _photos = p)),
              const SizedBox(height: 16),
              SurfaceCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Voice note', style: TextStyle(fontSize: 18)),
                    const Text('Speak instead of typing. Up to 2 minutes.', style: AppText.small),
                    const SizedBox(height: 16),
                    Center(child: VoiceRecorder(path: _voice, onRecorded: (p) => setState(() => _voice = p))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_showNote)
                AppTextField(label: 'Note', controller: _note, maxLines: 4, minLines: 3, autofocus: true, textCapitalization: TextCapitalization.sentences)
              else
                AppButton(label: 'Add a note', icon: Icons.keyboard_outlined, style: AppButtonStyle.outline, onPressed: () => setState(() => _showNote = true)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Text('People working today', style: TextStyle(fontSize: 16))),
                  CircleIconButton(icon: Icons.remove, size: 36, onTap: _people > 0 ? () => setState(() => _people--) : null),
                  SizedBox(width: 44, child: Text('$_people', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16))),
                  CircleIconButton(icon: Icons.add, size: 36, onTap: () => setState(() => _people++)),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: AppButton(label: 'Post Update', style: AppButtonStyle.orange, alignStart: true, trailingArrow: true, loading: _busy, onPressed: _post),
        ),
      ],
    );
  }
}

class _MyPosts extends ConsumerWidget {
  const _MyPosts();
  static const _query = (projectId: null, month: null, workType: null, q: null, mine: true);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(updatesFeedProvider(_query));
    final me = ref.watch(authProvider).value;
    return AsyncBody(loading: Skeleton.updates(), 
      value: value,
      onRetry: () => ref.invalidate(updatesFeedProvider(_query)),
      data: (posts) => RefreshIndicator(
        onRefresh: () => ref.refresh(updatesFeedProvider(_query).future),
        child: posts.isEmpty
            ? ListView(children: const [SizedBox(height: 60), EmptyState(icon: Icons.photo_camera_outlined, title: 'No posts yet', message: 'Your site photos will show up here.')])
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                itemCount: posts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (_, i) {
                  final u = posts[i];
                  return SurfaceCard(
                    padding: EdgeInsets.zero,
                    radius: 24,
                    onTap: () => context.push('/updates/${u.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (u.photos.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            child: AspectRatio(aspectRatio: 1.6, child: NetImage(u.photos.first)),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 12, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(me?.name ?? u.authorName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                                        Text('${Fmt.dayShort(u.date)} · ${Fmt.time(u.createdAt)} · ${u.projectName}', style: AppText.small),
                                      ],
                                    ),
                                  ),
                                  CircleIconButton(icon: Icons.edit_outlined, tooltip: 'Edit', size: 40, onTap: () => showEditUpdateSheet(context, ref, u)),
                                  const SizedBox(width: 8),
                                  CircleIconButton(
                                    icon: Icons.delete_outline,
                                    tooltip: 'Delete',
                                    size: 40,
                                    onTap: () async {
                                      final ok = await confirmDialog(context, title: 'Delete post?', message: 'This removes the photos and note.', confirmLabel: 'Delete', destructive: true);
                                      if (!ok) return;
                                      try {
                                        await ref.read(repoProvider).deleteUpdate(u.id);
                                      } catch (e) {
                                        if (context.mounted) showSnack(context, errorText(e), error: true);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              if (u.note.isNotEmpty) ...[const SizedBox(height: 10), Text(u.note, style: const TextStyle(fontSize: 15))],
                              if (u.voiceNoteUrl.isNotEmpty) ...[const SizedBox(height: 10), VoiceNotePlayer(source: u.voiceNoteUrl)],
                              const SizedBox(height: 10),
                              Text('${Fmt.plural(u.photos.length, 'photo')} · ${Fmt.plural(u.totalLaborers, 'person', 'people')}', style: AppText.muted),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
