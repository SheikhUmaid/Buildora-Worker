import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import '../../widgets/media.dart';
import 'invite_sheet.dart';

/// Create or edit a project.
class ProjectFormScreen extends ConsumerStatefulWidget {
  const ProjectFormScreen({super.key, this.projectId});
  final String? projectId;

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _address = TextEditingController();
  final _description = TextEditingController();
  final _budget = TextEditingController();
  DateTime _start = DateTime.now();
  DateTime? _finish;
  bool _budgetVisible = true;
  String? _cover; // local path
  String _existingCover = '';
  bool _loaded = false;
  bool _busy = false;

  bool get _editing => widget.projectId != null;

  @override
  void dispose() {
    for (final c in [_name, _location, _address, _description, _budget]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(Project p) {
    if (_loaded) return;
    _loaded = true;
    _name.text = p.name;
    _location.text = p.location;
    _address.text = p.address;
    _description.text = p.description;
    _budget.text = p.budget == null || p.budget == 0 ? '' : p.budget!.toStringAsFixed(0);
    _start = p.startDate ?? DateTime.now();
    _finish = p.expectedFinish;
    _budgetVisible = p.budgetVisible;
    _existingCover = p.coverImage;
  }

  Future<void> _pickDate(bool start) async {
    final initial = start ? _start : (_finish ?? _start.add(const Duration(days: 180)));
    final d = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (d != null) setState(() => start ? _start = d : _finish = d);
  }

  Future<void> _pickCover() async {
    final picked = await pickPhotos(context, camera: false, max: 1);
    if (picked.isNotEmpty) setState(() => _cover = picked.first);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final fields = {
      'name': _name.text.trim(),
      'location': _location.text.trim(),
      'address': _address.text.trim(),
      'description': _description.text.trim(),
      'startDate': _start.toIso8601String(),
      'expectedFinish': _finish?.toIso8601String() ?? '',
      'budget': _budget.text.trim().isEmpty ? '0' : _budget.text.trim().replaceAll(',', ''),
      'budgetVisible': _budgetVisible,
    };
    try {
      final repo = ref.read(repoProvider);
      if (_editing) {
        await repo.editProject(widget.projectId!, fields, coverPath: _cover);
        if (!mounted) return;
        showSnack(context, 'Project updated');
        context.pop();
      } else {
        final project = await repo.createProject(fields, coverPath: _cover);
        if (!mounted) return;
        context.pushReplacement('/projects/${project.id}');
        await showInviteSheet(context, project);
      }
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      final detail = ref.watch(projectDetailProvider(widget.projectId!));
      if (detail.value == null) {
        return Scaffold(body: SafeArea(child: Column(children: [const PageHeader(title: 'Edit project'), Expanded(child: AsyncBody(value: detail, data: (_) => const SizedBox()))])));
      }
      _fill(detail.value!.project);
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: _editing ? 'Edit project' : 'New project'),
            Expanded(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    GestureDetector(
                      onTap: _pickCover,
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_cover != null)
                              AnyImage(_cover!, radius: 20)
                            else if (_existingCover.isNotEmpty)
                              NetImage(_existingCover, radius: 20)
                            else
                              Container(
                                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [Icon(Icons.add_photo_alternate_outlined, size: 32), SizedBox(height: 8), Text('Add cover photo', style: AppText.muted)],
                                ),
                              ),
                            if (_cover != null || _existingCover.isNotEmpty)
                              const Positioned(right: 12, bottom: 12, child: CircleIconButton(icon: Icons.edit_outlined, size: 36)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppTextField(label: 'Project name', controller: _name, textCapitalization: TextCapitalization.words, validator: (v) => (v ?? '').trim().length < 2 ? 'Enter a project name' : null),
                    const SizedBox(height: 20),
                    AppTextField(label: 'Area, city', hint: 'Whitefield, Bengaluru', controller: _location, textCapitalization: TextCapitalization.words),
                    const SizedBox(height: 20),
                    AppTextField(label: 'Full address (optional)', controller: _address, maxLines: 2),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _DateField(label: 'Start date', value: Fmt.date(_start), onTap: () => _pickDate(true))),
                        const SizedBox(width: 12),
                        Expanded(child: _DateField(label: 'Expected finish', value: _finish == null ? 'Select' : Fmt.date(_finish), onTap: () => _pickDate(false))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AppTextField(label: 'Budget in ₹ (optional)', hint: '12000000', controller: _budget, keyboardType: TextInputType.number),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show budget to client'),
                      value: _budgetVisible,
                      onChanged: (v) => setState(() => _budgetVisible = v),
                    ),
                    const SizedBox(height: 8),
                    AppTextField(label: 'Description (optional)', controller: _description, maxLines: 3),
                    const SizedBox(height: 32),
                    AppButton(label: _editing ? 'Save changes' : 'Create project', orangeArrow: !_editing, loading: _busy, onPressed: _save),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        const SizedBox(height: 8),
        SurfaceCard(
          onTap: onTap,
          radius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          child: Row(children: [Expanded(child: Text(value, style: const TextStyle(fontSize: 15))), const Icon(Icons.calendar_today_outlined, size: 18)]),
        ),
      ],
    );
  }
}
