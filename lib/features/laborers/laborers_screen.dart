import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import '../../widgets/contact.dart';

/// Manage laborer logins: PIN, trade, assigned projects, active toggle.
class LaborersScreen extends ConsumerWidget {
  const LaborersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(laborersProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PageHeader(title: 'Manage laborers'),
            Expanded(
              child: AsyncBody(
                value: value,
                onRetry: () => ref.invalidate(laborersProvider),
                data: (list) => list.isEmpty
                    ? const EmptyState(
                        icon: Icons.groups_outlined,
                        title: 'No laborers yet',
                        message: 'Add your site team. Each person gets a phone + PIN login to post photos from site.',
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.refresh(laborersProvider.future),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _LaborerCard(laborer: list[i]),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: AppButton(label: 'Add Laborer', icon: Icons.add_circle_outline, onPressed: () => showLaborerSheet(context, ref)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LaborerCard extends ConsumerWidget {
  const _LaborerCard({required this.laborer});
  final Laborer laborer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = laborer;
    final projectNames = l.projects.map((p) => p.name).where((n) => n.isNotEmpty).join(', ');
    return Opacity(
      opacity: l.active ? 1 : 0.6,
      child: SurfaceCard(
        padding: const EdgeInsets.all(18),
        radius: 24,
        onTap: () => showLaborerSheet(context, ref, existing: l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar(name: l.name, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.name, style: const TextStyle(fontSize: 17)),
                      Text(projectNames.isEmpty ? 'No project assigned' : projectNames, style: AppText.small, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('PIN : ${l.pin}', style: const TextStyle(fontSize: 18, letterSpacing: 1)),
            const SizedBox(height: 6),
            Text('${l.trade} · ${l.phone}', style: AppText.muted),
            if (l.lastLoginAt != null) Text('Last login ${Fmt.relative(l.lastLoginAt)}', style: AppText.small),
            const SizedBox(height: 14),
            AppButton(label: 'Login details', style: AppButtonStyle.outline, height: 50, onPressed: () => showLoginDetails(context, ref, l)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('Active ${l.name}', style: const TextStyle(fontSize: 16))),
                Switch(
                  value: l.active,
                  onChanged: (v) async {
                    try {
                      await ref.read(repoProvider).editLaborer(l.id, {'active': v});
                    } catch (e) {
                      if (context.mounted) showSnack(context, errorText(e), error: true);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _loginMessage(Laborer l) =>
    'Hi ${l.name.split(' ').first}, your Buildora site login:\nPhone: ${l.phone}\nPIN: ${l.pin}\nOpen the Buildora Contractor app and tap "I work on site — Laborer login".';

Future<void> showLoginDetails(BuildContext context, WidgetRef ref, Laborer l) {
  return showAppSheet<void>(
    context,
    title: 'Login details',
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${l.name} logs in from the contractor app using "Laborer login".', style: AppText.muted),
        const SizedBox(height: 16),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Phone', style: AppText.small),
              SelectableText(l.phone, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              const Text('PIN', style: AppText.small),
              SelectableText(l.pin, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 8)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: AppButton(label: 'Copy', icon: Icons.copy, style: AppButtonStyle.outline, height: 50, onPressed: () => copyText(ctx, _loginMessage(l), label: 'Login details copied'))),
            const SizedBox(width: 12),
            Expanded(child: AppButton(label: 'WhatsApp', icon: Icons.chat_outlined, style: AppButtonStyle.whatsapp, height: 50, onPressed: () => openWhatsApp(ctx, l.phone, message: _loginMessage(l)))),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: () => SharePlus.instance.share(ShareParams(text: _loginMessage(l))), child: const Text('Share another way', style: TextStyle(color: AppColors.text))),
        TextButton(
          onPressed: () async {
            final ok = await confirmDialog(ctx, title: 'Reset PIN?', message: 'A new 4-digit PIN will be generated. The old one stops working.', confirmLabel: 'Reset');
            if (!ok) return;
            try {
              final updated = await ref.read(repoProvider).resetPin(l.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                showSnack(context, 'New PIN for ${updated.name}: ${updated.pin}');
              }
            } catch (e) {
              if (ctx.mounted) showSnack(ctx, errorText(e), error: true);
            }
          },
          child: const Text('Reset PIN', style: TextStyle(color: AppColors.orange)),
        ),
      ],
    ),
  );
}

/// Add or edit a laborer.
Future<void> showLaborerSheet(BuildContext context, WidgetRef ref, {Laborer? existing}) {
  return showAppSheet<void>(context, title: existing == null ? 'Add laborer' : 'Edit laborer', builder: (_) => _LaborerForm(existing: existing));
}

class _LaborerForm extends ConsumerStatefulWidget {
  const _LaborerForm({this.existing});
  final Laborer? existing;
  @override
  ConsumerState<_LaborerForm> createState() => _LaborerFormState();
}

class _LaborerFormState extends ConsumerState<_LaborerForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _phone = TextEditingController(text: widget.existing?.phone ?? '');
  final _pin = TextEditingController();
  late String _trade = widget.existing?.trade ?? 'Helper';
  late final Set<String> _projects = {...?widget.existing?.projects.map((p) => p.id)};
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final body = {
      'name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'trade': _trade,
      'projects': _projects.toList(),
      if (widget.existing == null && _pin.text.trim().isNotEmpty) 'pin': _pin.text.trim(),
    };
    try {
      final repo = ref.read(repoProvider);
      if (widget.existing == null) {
        final l = await repo.addLaborer(body);
        if (!mounted) return;
        Navigator.pop(context);
        await showLoginDetails(context, ref, l);
      } else {
        await repo.editLaborer(widget.existing!.id, body);
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final l = widget.existing!;
    final ok = await confirmDialog(context, title: 'Remove ${l.name}?', message: 'Their login is deleted. Posts they made stay on the project.', confirmLabel: 'Remove', destructive: true);
    if (!ok) return;
    try {
      await ref.read(repoProvider).deleteLaborer(l.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = (ref.watch(projectsProvider).value ?? const <Project>[]).where((p) => !p.isCompleted || _projects.contains(p.id)).toList();
    final trades = ref.watch(metaProvider).value?['trades'] ?? const ['Carpenter', 'Electrician', 'Plumber', 'Mason', 'Painter', 'Helper', 'Other'];
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(label: 'Name', controller: _name, textCapitalization: TextCapitalization.words, validator: (v) => (v ?? '').trim().length < 2 ? 'Enter a name' : null),
          const SizedBox(height: 16),
          AppTextField(label: 'Phone', controller: _phone, keyboardType: TextInputType.phone, validator: Validators.phone),
          if (widget.existing == null) ...[
            const SizedBox(height: 16),
            AppTextField(
              label: 'PIN (leave empty to auto-generate)',
              controller: _pin,
              keyboardType: TextInputType.number,
              maxLength: 4,
              validator: (v) => (v ?? '').isEmpty ? null : Validators.pin(v),
            ),
          ],
          const SizedBox(height: 16),
          const Text('Trade', style: AppText.label),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final t in trades) AppChip(label: t, selected: _trade == t, onTap: () => setState(() => _trade = t))]),
          const SizedBox(height: 20),
          const Text('Assign projects', style: AppText.label),
          if (projects.isEmpty) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Create a project first.', style: AppText.muted)),
          for (final p in projects)
            Row(
              children: [
                Expanded(child: Text(p.name, style: const TextStyle(fontSize: 16))),
                Switch(value: _projects.contains(p.id), onChanged: (v) => setState(() => v ? _projects.add(p.id) : _projects.remove(p.id))),
              ],
            ),
          const SizedBox(height: 20),
          AppButton(label: widget.existing == null ? 'Add Laborer' : 'Save', orangeArrow: widget.existing == null, loading: _busy, onPressed: _save),
          if (widget.existing != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: _delete, child: const Text('Remove laborer', style: TextStyle(color: AppColors.red))),
          ],
        ],
      ),
    );
  }
}
