import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../providers/auth.dart';
import '../../providers/data.dart';
import '../../widgets/cards.dart';
import '../../widgets/branding.dart';
import '../../widgets/common.dart';
import '../../widgets/media.dart';
import '../shared/account_screens.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final projects = ref.watch(projectsProvider).value ?? const [];
    if (user == null) return const Scaffold(body: LoadingView());
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          children: [
            const PageHeader(title: 'Profile', showBack: false, trailing: NotificationBell()),
            const SizedBox(height: 8),
            Center(child: Avatar(name: user.name, size: 104)),
            const SizedBox(height: 16),
            Text(user.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            if (user.subtitle.isNotEmpty) Text(user.subtitle, textAlign: TextAlign.center, style: AppText.muted),
            if (user.company.isNotEmpty) Text(user.company, textAlign: TextAlign.center, style: AppText.small),
            if (user.bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(user.bio, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.4)),
            ],
            const SizedBox(height: 24),
            ActionTile(icon: Icons.edit_outlined, label: 'Edit profile', onTap: () => context.push('/profile/edit')),
            ActionTile(icon: Icons.key_outlined, label: 'Change password', onTap: () => context.push('/profile/password')),
            ActionTile(
              icon: Icons.notifications_none,
              label: 'Notifications',
              onTap: () => context.push('/notifications'),
              trailing: Switch(
                value: user.notificationsEnabled,
                onChanged: (v) => ref.read(authProvider.notifier).updateProfile({'notificationsEnabled': v}),
              ),
            ),
            ActionTile(icon: Icons.groups_outlined, label: 'Manage Labour', onTap: () => context.push('/laborers')),
            ActionTile(
              icon: Icons.logout,
              label: 'Logout',
              onTap: () async {
                if (await confirmDialog(context, title: 'Log out?', message: 'You can log back in any time.', confirmLabel: 'Log out')) {
                  await ref.read(authProvider.notifier).logout();
                }
              },
            ),
            if (projects.isNotEmpty) ...[
              SectionTitle('Recent projects', trailing: TextButton(onPressed: () => context.go('/portfolio'), child: const Text('Edit', style: TextStyle(color: AppColors.text)))),
              SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: projects.length.clamp(0, 6),
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final p = projects[i];
                    return SizedBox(
                      width: 170,
                      child: SurfaceCard(
                        padding: const EdgeInsets.all(8),
                        onTap: () => context.push('/projects/${p.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 100, width: double.infinity, child: NetImage(p.coverImage, radius: 12)),
                            const SizedBox(height: 8),
                            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                            if (p.location.isNotEmpty) LocationText(p.location, size: 11),
                            const SizedBox(height: 6),
                            StatusBadge(p.status, small: true),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 32),
            ActionTile(
              icon: Icons.delete_outline,
              label: 'Delete account',
              danger: true,
              onTap: () => showDeleteAccountDialog(
                context,
                ref,
                warning: 'This permanently deletes your account, all your projects, updates, photos, requests and laborer logins.',
              ),
            ),
            const SizedBox(height: 24),
            const Center(child: AppVersionText()),
          ],
        ),
      ),
    );
  }
}

class EngineerEditProfileScreen extends ConsumerWidget {
  const EngineerEditProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(authProvider).value;
    return EditProfileScreen(fields: [
      ('name', 'Full name', u?.name ?? '', TextInputType.name, 1),
      ('title', 'Title (e.g. Civil Engineer)', u?.title ?? '', TextInputType.text, 1),
      ('company', 'Company', u?.company ?? '', TextInputType.text, 1),
      ('phone', 'Phone', u?.phone ?? '', TextInputType.phone, 1),
      ('location', 'City', u?.location ?? '', TextInputType.text, 1),
      ('yearsExperience', 'Years of experience', '${u?.yearsExperience ?? 0}', TextInputType.number, 1),
      ('bio', 'About you (shown to clients)', u?.bio ?? '', TextInputType.multiline, 4),
    ]);
  }
}
