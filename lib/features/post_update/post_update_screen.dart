import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import '../../widgets/media.dart';

/// Three-step "post today's update": photos -> details -> review.
class PostUpdateScreen extends ConsumerStatefulWidget {
  const PostUpdateScreen({super.key, this.projectId});
  final String? projectId;

  @override
  ConsumerState<PostUpdateScreen> createState() => _PostUpdateScreenState();
}

class _PostUpdateScreenState extends ConsumerState<PostUpdateScreen> {
  int _step = 0;
  List<String> _photos = [];
  late String? _projectId = widget.projectId;
  DateTime _date = DateTime.now();
  final Set<String> _work = {};
  final _note = TextEditingController();
  String? _voice;
  final Map<String, int> _laborers = {'Laborers on site': 0};
  int? _progress; // null until the project loads
  bool _busy = false;
  double _upload = 0;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  int get _totalLaborers => _laborers.values.fold(0, (a, b) => a + b);

  Future<void> _addTrade(List<String> trades) async {
    final remaining = trades.where((t) => !_laborers.containsKey(t)).toList();
    final trade = await showAppSheet<String>(
      context,
      title: 'Add trade',
      builder: (ctx) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final t in remaining) AppChip(label: t, onTap: () => Navigator.pop(ctx, t))],
      ),
    );
    if (trade != null) setState(() => _laborers[trade] = 1);
  }

  bool _validStep() {
    if (_step == 0 && _photos.isEmpty) {
      showSnack(context, 'Add at least one site photo', error: true);
      return false;
    }
    if (_step == 1) {
      if (_projectId == null) {
        showSnack(context, 'Choose a project', error: true);
        return false;
      }
    }
    return true;
  }

  Future<void> _post() async {
    setState(() {
      _busy = true;
      _upload = 0;
    });
    try {
      await ref.read(repoProvider).postUpdate(
            _projectId!,
            photos: _photos,
            note: _note.text.trim(),
            voicePath: _voice,
            date: _date,
            workTypes: _work.toList(),
            laborers: [
              for (final e in _laborers.entries)
                if (e.value > 0) LaborerCount(e.key == 'Laborers on site' ? 'General' : e.key, e.value),
            ],
            totalLaborers: _totalLaborers,
            progress: _progress,
            onProgress: (p) => setState(() => _upload = p),
          );
      if (!mounted) return;
      showSnack(context, 'Update posted. Your client has been notified.');
      context.pop();
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = (ref.watch(projectsProvider).value ?? const <Project>[]).where((p) => !p.isCompleted).toList();
    final meta = ref.watch(metaProvider).value;
    final project = projects.where((p) => p.id == _projectId).firstOrNull;
    _progress ??= project?.progress;

    return PopScope(
      canPop: _step == 0 && !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0 && !_busy) setState(() => _step--);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    CircleIconButton(icon: Icons.close, tooltip: 'Cancel', onTap: () => context.pop()),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Post update', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                        Text('Step ${_step + 1} of 3', style: AppText.small),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                          decoration: BoxDecoration(color: i <= _step ? AppColors.black : AppColors.surfaceDark, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: switch (_step) {
                  0 => _photosStep(),
                  1 => _detailsStep(projects, project, meta),
                  _ => _reviewStep(project),
                },
              ),
              if (_busy && _upload > 0 && _upload < 1)
                Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: LinearProgressIndicator(value: _upload, color: AppColors.orange)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    if (_step > 0) ...[
                      AppButton(label: 'Back', style: AppButtonStyle.outline, expand: false, onPressed: _busy ? null : () => setState(() => _step--)),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: _step < 2
                          ? AppButton(label: 'Next', alignStart: true, trailingArrow: true, onPressed: () => _validStep() ? setState(() => _step++) : null)
                          : AppButton(label: 'Post Update', style: AppButtonStyle.orange, alignStart: true, trailingArrow: true, loading: _busy, onPressed: _post),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photosStep() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          const Text("Today's site photos", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.8)),
          const SizedBox(height: 24),
          PhotoPickerBox(photos: _photos, onChanged: (p) => setState(() => _photos = p)),
        ],
      );

  Widget _detailsStep(List<Project> projects, Project? project, Map<String, List<String>>? meta) {
    final workTypes = meta?['workTypes'] ?? const ['Excavation', 'Foundation', 'Shuttering', 'Rebar', 'Concrete pour', 'Brickwork', 'Plastering', 'Electrical', 'Plumbing', 'Flooring', 'Painting', 'Finishing', 'Other'];
    final trades = meta?['trades'] ?? const ['Carpenter', 'Electrician', 'Plumber', 'Mason', 'Painter', 'Helper', 'Other'];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        const Text('A quick site update', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.8)),
        const SizedBox(height: 24),
        const Text('Project', style: AppText.label),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: projects.any((p) => p.id == _projectId) ? _projectId : null,
          isExpanded: true,
          hint: const Text('Choose a project'),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          items: [for (final p in projects) DropdownMenuItem(value: p.id, child: Text(p.name))],
          onChanged: (v) => setState(() {
            _projectId = v;
            _progress = projects.firstWhere((p) => p.id == v).progress;
          }),
        ),
        const SizedBox(height: 20),
        const Text('Update date', style: AppText.label),
        const SizedBox(height: 8),
        SurfaceCard(
          radius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime.now());
            if (d != null) setState(() => _date = d);
          },
          child: Row(children: [Expanded(child: Text(Fmt.date(_date))), const Icon(Icons.calendar_today_outlined, size: 18)]),
        ),
        const SizedBox(height: 20),
        const Text('Work done today', style: AppText.label),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final w in workTypes)
              AppChip(label: w, selected: _work.contains(w), onTap: () => setState(() => _work.contains(w) ? _work.remove(w) : _work.add(w))),
          ],
        ),
        const SizedBox(height: 20),
        AppTextField(label: 'Work note', controller: _note, maxLines: 4, minLines: 3, maxLength: 2000, textCapitalization: TextCapitalization.sentences),
        const SizedBox(height: 12),
        const Text('Voice note (optional)', style: AppText.label),
        const SizedBox(height: 8),
        Center(child: VoiceRecorder(path: _voice, onRecorded: (p) => setState(() => _voice = p))),
        const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
        Row(
          children: [
            const Expanded(child: Text('Laborers', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500))),
            Text('Total $_totalLaborers', style: AppText.muted),
          ],
        ),
        const SizedBox(height: 12),
        for (final e in _laborers.entries.toList())
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(child: Text(e.key, style: const TextStyle(fontSize: 17))),
                CircleIconButton(
                  icon: Icons.remove,
                  size: 36,
                  tooltip: 'Fewer',
                  onTap: () => setState(() {
                    if (e.value > 0) {
                      _laborers[e.key] = e.value - 1;
                    } else if (e.key != 'Laborers on site') {
                      _laborers.remove(e.key);
                    }
                  }),
                ),
                SizedBox(width: 44, child: Text('${e.value}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17))),
                CircleIconButton(icon: Icons.add, size: 36, tooltip: 'More', onTap: () => setState(() => _laborers[e.key] = e.value + 1)),
              ],
            ),
          ),
        const SizedBox(height: 12),
        AppButton(label: 'Add trade', style: AppButtonStyle.outline, onPressed: () => _addTrade(trades)),
        const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
        Row(
          children: [
            const Expanded(child: Text('Project progress', style: TextStyle(fontSize: 20))),
            Text('${_progress ?? 0}%', style: const TextStyle(fontSize: 20)),
          ],
        ),
        Slider(
          value: (_progress ?? 0).toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          onChanged: (v) {
            if (v ~/ 10 != (_progress ?? 0) ~/ 10) Haptics.selection();
            setState(() => _progress = v.round());
          },
        ),
      ],
    );
  }

  Widget _reviewStep(Project? project) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          Row(
            children: [
              const Expanded(child: Text('Review update', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.8))),
              TextButton(onPressed: () => setState(() => _step = 0), child: const Text('Edit photos', style: TextStyle(color: AppColors.textMuted))),
            ],
          ),
          const SizedBox(height: 8),
          Text('${project?.name ?? ''} · ${Fmt.dayShort(_date)}', style: AppText.muted),
          const SizedBox(height: 14),
          PhotoCarousel(photos: _photos, height: 260),
          const SizedBox(height: 20),
          SurfaceCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Contractor note', style: AppText.muted)),
                    Tappable(onTap: () => setState(() => _step = 1), child: const Text('Edit details', style: TextStyle(fontWeight: FontWeight.w600))),
                  ],
                ),
                const SizedBox(height: 10),
                Text(_note.text.trim().isEmpty ? 'No note added' : _note.text.trim(), style: const TextStyle(fontSize: 16, height: 1.5)),
                if (_voice != null) ...[const SizedBox(height: 10), VoiceNotePlayer(source: _voice!)],
                if (_work.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 6, runSpacing: 6, children: [for (final w in _work) AppChip(label: w, dense: true)]),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Text('$_totalLaborers laborers on site', style: AppText.muted),
                    const Spacer(),
                    Text('Progress ${_progress ?? 0}%', style: AppText.muted),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
}
