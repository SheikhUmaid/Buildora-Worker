import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import '../../widgets/contact.dart';

String inviteMessage(Project p, String code) =>
    'Follow the daily progress of ${p.name} on Buildora. Download the Buildora app, sign up and join with invite code: $code';

/// Shows the project's invite code with copy / share / regenerate.
Future<void> showInviteSheet(BuildContext context, Project project) {
  return showAppSheet<void>(context, title: 'Invite your client', builder: (_) => _InviteBody(project: project));
}

class _InviteBody extends ConsumerStatefulWidget {
  const _InviteBody({required this.project});
  final Project project;
  @override
  ConsumerState<_InviteBody> createState() => _InviteBodyState();
}

class _InviteBodyState extends ConsumerState<_InviteBody> {
  late String _code = widget.project.inviteCode ?? '';
  bool _busy = false;

  Future<void> _regenerate() async {
    final ok = await confirmDialog(context,
        title: 'New invite code?', message: 'The old code will stop working. Clients who already joined stay connected.', confirmLabel: 'Generate');
    if (!ok) return;
    setState(() => _busy = true);
    try {
      final code = await ref.read(repoProvider).regenerateInviteCode(widget.project.id);
      setState(() => _code = code);
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
        Text('Share this code with your client. They enter it in the Buildora client app to follow ${widget.project.name}.', style: AppText.muted),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              SelectableText(_code, style: const TextStyle(fontSize: 36, letterSpacing: 10, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Invite code', style: AppText.small),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: AppButton(label: 'Copy', icon: Icons.copy, style: AppButtonStyle.outline, height: 50, onPressed: () => copyText(context, _code, label: 'Code copied'))),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Share',
                icon: Icons.share_outlined,
                height: 50,
                onPressed: () => SharePlus.instance.share(ShareParams(text: inviteMessage(widget.project, _code))),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : _regenerate,
          child: Text(_busy ? 'Generating…' : 'Generate a new code', style: const TextStyle(color: AppColors.textMuted)),
        ),
      ],
    );
  }
}
