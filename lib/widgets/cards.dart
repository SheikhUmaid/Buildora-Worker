import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import 'common.dart';
import 'media.dart';

/// Big project card: cover, name, location, status, progress, last update.
class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.project, this.onTap, this.hero = true});
  final Project project;
  final VoidCallback? onTap;

  /// Fly the cover into the project screen (turn off if the card can appear twice on a screen).
  final bool hero;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: AppHero(tag: hero ? HeroTags.project(project.id) : null, child: NetImage(project.coverImage, radius: 18)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                if (project.location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  LocationText(project.location),
                ],
                const SizedBox(height: 12),
                StatusBadge(project.status, small: true),
                const SizedBox(height: 16),
                ProgressRow(progress: project.progress),
                const SizedBox(height: 14),
                Text(
                  project.lastUpdateAt == null ? 'No updates yet' : 'Last update: ${Fmt.dateShort(project.lastUpdateAt)}',
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

class LocationText extends StatelessWidget {
  const LocationText(this.text, {super.key, this.size = 13});
  final String text;
  final double size;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_outlined, size: size + 2, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: size, color: AppColors.textMuted))),
        ],
      );
}

/// One entry on a vertical timeline: dot + date label + content.
class TimelineEntry extends StatelessWidget {
  const TimelineEntry({super.key, required this.label, required this.child, this.highlight = false, this.isLast = false, this.sublabel});
  final String label;
  final String? sublabel;
  final Widget? child;
  final bool highlight;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(color: highlight ? AppColors.orange : AppColors.surfaceDark, shape: BoxShape.circle),
                ),
                if (!isLast) Expanded(child: Container(width: 1.5, color: AppColors.surfaceDark)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 13, color: highlight ? AppColors.text : AppColors.textMuted)),
                  if (sublabel != null) Text(sublabel!, style: AppText.small),
                  if (child != null) ...[const SizedBox(height: 10), child!],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card with up to two photos, the note and "5 photos · 18 laborers".
class UpdateCard extends StatelessWidget {
  const UpdateCard({super.key, required this.update, this.onTap, this.showProject = false, this.hero = true});
  final SiteUpdate update;

  /// Fly the first photo into the update detail screen.
  final bool hero;
  final VoidCallback? onTap;
  final bool showProject;

  @override
  Widget build(BuildContext context) {
    final photos = update.photos.take(2).toList();
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photos.isNotEmpty)
            SizedBox(
              height: 110,
              child: Row(
                children: [
                  for (var i = 0; i < photos.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (i == 0)
                            AppHero(tag: hero ? HeroTags.update(update.id) : null, child: NetImage(photos[i], radius: 14))
                          else
                            NetImage(photos[i], radius: 14),
                          if (i == 1 && update.photos.length > 2)
                            Container(
                              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(14)),
                              alignment: Alignment.center,
                              child: Text('+${update.photos.length - 2}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showProject && update.projectName.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(update.projectName, style: AppText.small)),
                Text(
                  update.note.isEmpty ? (update.voiceNoteUrl.isNotEmpty ? 'Voice note' : 'Site photos') : update.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: AppColors.text),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (update.photos.isNotEmpty) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.photo_library_outlined, size: 13, color: AppColors.textMuted)),
                    Expanded(
                      child: Text(
                        [
                          if (update.summary.isNotEmpty) update.summary,
                          if (update.byLaborer) 'by ${update.authorName}',
                        ].join(' · '),
                        style: AppText.small,
                      ),
                    ),
                    if (update.voiceNoteUrl.isNotEmpty) const Icon(Icons.mic_none, size: 15, color: AppColors.textMuted),
                    if (update.approvalCount > 0) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.thumb_up_alt_outlined, size: 14, color: AppColors.green)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Status line at the bottom of a request card.
class RequestStatusLine extends StatelessWidget {
  const RequestStatusLine({super.key, required this.request, this.forEngineer = false});
  final ClientRequest request;
  final bool forEngineer;

  @override
  Widget build(BuildContext context) {
    final (icon, text, color) = switch (request.status) {
      'done' => (Icons.check_circle_outline, 'Done · Resolved', AppColors.green),
      'in_progress' => (Icons.build_outlined, 'In progress', AppColors.orange),
      _ when forEngineer => (Icons.fiber_new_outlined, 'New', AppColors.text),
      _ when request.seenAt != null => (Icons.visibility_outlined, 'Seen by contractor', AppColors.text),
      _ => (Icons.schedule, 'Sent', AppColors.textMuted),
    };
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 14, color: color)),
      ],
    );
  }
}

/// Request card used by both apps.
class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.request, this.onTap, this.forEngineer = false});
  final ClientRequest request;
  final VoidCallback? onTap;
  final bool forEngineer;

  @override
  Widget build(BuildContext context) {
    final r = request;
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (forEngineer) ...[
                Avatar(name: r.client?.name ?? '?', size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.client?.name ?? 'Client', style: const TextStyle(fontSize: 16)),
                      Text(r.projectName, style: AppText.small),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
                  child: Text(Fmt.requestType(r.type), style: const TextStyle(fontSize: 13)),
                ),
                const Spacer(),
              ],
              if (r.urgent && r.isOpen) const StatusBadge('urgent', small: true),
              if (forEngineer && r.status == 'done') const Icon(Icons.check_circle_outline, color: AppColors.green),
              if (!forEngineer) Text(Fmt.time(r.createdAt), style: AppText.small),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  [
                    if (forEngineer) Fmt.requestType(r.type) else (r.updateId != null ? 'Update' : r.projectName),
                    if (r.updateDate != null) Fmt.day(r.updateDate) else Fmt.day(r.createdAt),
                  ].join(' · '),
                  style: AppText.small,
                ),
              ),
              if (forEngineer) Text(Fmt.time(r.createdAt), style: AppText.small),
            ],
          ),
          const SizedBox(height: 8),
          Text(r.message, style: const TextStyle(fontSize: 15, height: 1.4)),
          if (r.photos.isNotEmpty || r.voiceNoteUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (r.photos.isNotEmpty) ...[
                  const Icon(Icons.photo_outlined, size: 15, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(Fmt.plural(r.photos.length, 'photo'), style: AppText.small),
                  const SizedBox(width: 12),
                ],
                if (r.voiceNoteUrl.isNotEmpty) ...[
                  const Icon(Icons.mic_none, size: 15, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  const Text('Voice note', style: AppText.small),
                ],
              ],
            ),
          ],
          if (!forEngineer && r.replies.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final reply in r.replies.where((x) => x.authorRole == 'engineer').take(2)) ReplyQuote(reply: reply),
          ],
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
          Row(
            children: [
              Expanded(child: RequestStatusLine(request: r, forEngineer: forEngineer)),
              if (onTap != null) const Icon(Icons.chevron_right, color: AppColors.text),
            ],
          ),
        ],
      ),
    );
  }
}

class ReplyQuote extends StatelessWidget {
  const ReplyQuote({super.key, required this.reply});
  final Reply reply;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(left: 12),
      decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppColors.black, width: 2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reply.message, style: const TextStyle(fontSize: 15, height: 1.4)),
          const SizedBox(height: 4),
          Text('${reply.authorName} · ${Fmt.time(reply.createdAt)}', style: AppText.small),
        ],
      ),
    );
  }
}
