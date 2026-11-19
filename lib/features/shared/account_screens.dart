import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/auth.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';

// ======================================================================= Forgot password

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = ref.read(repoProvider);
    try {
      if (!_codeSent) {
        final devCode = await repo.forgotPassword(_email.text);
        setState(() => _codeSent = true);
        if (!mounted) return;
        // Without an email provider the server returns the code in development builds.
        if (devCode != null) _code.text = devCode;
        showSnack(context, devCode != null ? 'Dev mode: code $devCode filled in' : 'If the email exists, a 6-digit code was sent');
      } else {
        await repo.resetPassword(_email.text, _code.text, _password.text);
        if (!mounted) return;
        showSnack(context, 'Password updated. Log in with your new password.');
        context.pop();
      }
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              const Align(alignment: Alignment.centerLeft, child: BackCircle()),
              const SizedBox(height: 32),
              const Text('Reset password', style: AppText.label),
              const SizedBox(height: 4),
              const Text('Forgot your password?', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500, letterSpacing: -0.6)),
              const SizedBox(height: 8),
              Text(_codeSent ? 'Enter the 6-digit code and choose a new password.' : 'We will send a reset code to your email.', style: AppText.muted),
              const SizedBox(height: 28),
              AppTextField(label: 'Email', controller: _email, keyboardType: TextInputType.emailAddress, validator: Validators.email, readOnly: _codeSent),
              if (_codeSent) ...[
                const SizedBox(height: 20),
                AppTextField(label: 'Reset code', controller: _code, keyboardType: TextInputType.number, maxLength: 6, validator: (v) => (v ?? '').trim().length == 6 ? null : 'Enter the 6-digit code'),
                const SizedBox(height: 20),
                AppTextField(label: 'New password', controller: _password, obscure: true, validator: Validators.password),
              ],
              const SizedBox(height: 32),
              AppButton(label: _codeSent ? 'Update password' : 'Send code', loading: _busy, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================================= Change password

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authProvider.notifier).changePassword(_current.text, _next.text);
      if (!mounted) return;
      showSnack(context, 'Password changed');
      context.pop();
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PageHeader(title: 'Change password'),
            Expanded(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    AppTextField(label: 'Current password', controller: _current, obscure: true, validator: (v) => Validators.required(v, 'Current password')),
                    const SizedBox(height: 20),
                    AppTextField(label: 'New password', controller: _next, obscure: true, validator: Validators.password),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'Confirm new password',
                      controller: _confirm,
                      obscure: true,
                      validator: (v) => v != _next.text ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 32),
                    AppButton(label: 'Save password', loading: _busy, onPressed: _save),
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

// ======================================================================= Delete account

Future<void> showDeleteAccountDialog(BuildContext context, WidgetRef ref, {required String warning}) async {
  final controller = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Delete account?', style: AppText.h3),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(warning, style: AppText.body),
          const SizedBox(height: 16),
          AppTextField(label: 'Enter your password to confirm', controller: controller, obscure: true),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppColors.text))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600))),
      ],
    ),
  );
  final password = controller.text;
  controller.dispose();
  if (confirmed != true || !context.mounted) return;
  try {
    await ref.read(authProvider.notifier).deleteAccount(password);
  } catch (e) {
    if (context.mounted) showSnack(context, errorText(e), error: true);
  }
}

// ======================================================================= Edit profile (simple)

/// Edit fields given as (key, label, initial, keyboard, maxLines).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.fields, this.title = 'Edit profile'});
  final List<(String, String, String, TextInputType, int)> fields;
  final String title;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _controllers = {for (final f in widget.fields) f.$1: TextEditingController(text: f.$3)};
  bool _busy = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final changes = <String, dynamic>{};
      for (final f in widget.fields) {
        final text = _controllers[f.$1]!.text.trim();
        changes[f.$1] = f.$1 == 'yearsExperience' ? int.tryParse(text) ?? 0 : text;
      }
      await ref.read(authProvider.notifier).updateProfile(changes);
      if (!mounted) return;
      showSnack(context, 'Profile updated');
      context.pop();
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: widget.title),
            Expanded(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    for (final f in widget.fields) ...[
                      AppTextField(
                        label: f.$2,
                        controller: _controllers[f.$1],
                        keyboardType: f.$4,
                        maxLines: f.$5,
                        textCapitalization: f.$4 == TextInputType.name ? TextCapitalization.words : TextCapitalization.sentences,
                        validator: f.$1 == 'name' ? (v) => (v ?? '').trim().length < 2 ? 'Enter your name' : null : null,
                      ),
                      const SizedBox(height: 20),
                    ],
                    const SizedBox(height: 12),
                    AppButton(label: 'Save', loading: _busy, onPressed: _save),
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

// ======================================================================= Notifications

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _icon(String type) => switch (type) {
        'update.new' => Icons.photo_library_outlined,
        'request.new' => Icons.chat_bubble_outline,
        'request.reply' => Icons.reply_outlined,
        'request.status' => Icons.task_alt,
        'project.status' => Icons.flag_outlined,
        'project.joined' => Icons.person_add_alt,
        'project.feedback' => Icons.star_outline,
        _ => Icons.notifications_none,
      };

  void _open(BuildContext context, WidgetRef ref, AppNotification n) {
    if (!n.read) ref.read(repoProvider).markRead(n.id);
    if (n.requestId != null) {
      context.push('/requests/${n.requestId}');
    } else if (n.updateId != null) {
      context.push('/updates/${n.updateId}');
    } else if (n.projectId != null) {
      context.push('/projects/${n.projectId}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(notificationsProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: 'Notifications',
              trailing: TextButton(
                onPressed: () => ref.read(repoProvider).markAllRead(),
                child: const Text('Read all', style: TextStyle(color: AppColors.text)),
              ),
            ),
            Expanded(
              child: AsyncBody(
                value: value,
                onRetry: () => ref.invalidate(notificationsProvider),
                data: (data) {
                  final items = data.$1;
                  if (items.isEmpty) {
                    return const EmptyState(icon: Icons.notifications_none, title: 'All caught up', message: 'New updates and replies will show up here.');
                  }
                  return RefreshIndicator(
                    onRefresh: () => ref.refresh(notificationsProvider.future),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final n = items[i];
                        return SurfaceCard(
                          color: n.read ? AppColors.white : AppColors.surface,
                          onTap: () => _open(context, ref, n),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(color: n.read ? AppColors.surface : AppColors.white, shape: BoxShape.circle),
                                child: Icon(_icon(n.type), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.title, style: TextStyle(fontSize: 15, fontWeight: n.read ? FontWeight.w400 : FontWeight.w600)),
                                    if (n.body.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.muted),
                                    ],
                                    const SizedBox(height: 6),
                                    Text(Fmt.relative(n.createdAt), style: AppText.small),
                                  ],
                                ),
                              ),
                              if (!n.read) const Padding(padding: EdgeInsets.only(top: 6), child: CircleAvatar(radius: 4, backgroundColor: AppColors.orange)),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bell icon with unread badge that opens the notifications screen.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    return Badge(
      isLabelVisible: unread > 0,
      label: Text('$unread'),
      backgroundColor: AppColors.orange,
      child: CircleIconButton(icon: Icons.notifications_none, tooltip: 'Notifications', onTap: () => context.push('/notifications')),
    );
  }
}
