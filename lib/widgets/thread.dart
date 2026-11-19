import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import 'cards.dart';
import 'common.dart';
import 'media.dart';

/// Requests grouped under date headings ("Sun, 18 Oct").
class GroupedRequestList extends StatelessWidget {
  const GroupedRequestList({super.key, required this.requests, required this.onTap, this.forEngineer = false, this.bottomPadding = 32});
  final List<ClientRequest> requests;
  final ValueChanged<ClientRequest> onTap;
  final bool forEngineer;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    DateTime? lastDay;
    for (final r in requests) {
      final d = r.createdAt ?? DateTime.now();
      if (lastDay == null || !Fmt.sameDay(lastDay, d)) {
        children.add(Padding(padding: const EdgeInsets.fromLTRB(4, 16, 0, 10), child: Text(Fmt.day(d), style: AppText.muted)));
        lastDay = d;
      }
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: RequestCard(request: r, forEngineer: forEngineer, onTap: () => onTap(r)),
      ));
    }
    return ListView(padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding), children: children);
  }
}

class ReplyBubble extends StatelessWidget {
  const ReplyBubble({super.key, required this.reply, required this.mine});
  final Reply reply;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: mine ? AppColors.black : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reply.message, style: TextStyle(fontSize: 15, height: 1.4, color: mine ? Colors.white : AppColors.text)),
            const SizedBox(height: 4),
            Text('${reply.authorName} · ${Fmt.time(reply.createdAt)}', style: TextStyle(fontSize: 11, color: mine ? Colors.white70 : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class ReplyComposer extends StatelessWidget {
  const ReplyComposer({super.key, required this.controller, required this.busy, required this.onSend, this.hint = 'Reply…'});
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSend;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          busy
              ? const SizedBox(width: 44, height: 44, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
              : CircleIconButton(icon: Icons.arrow_upward, dark: true, size: 44, tooltip: 'Send', onTap: onSend),
        ],
      ),
    );
  }
}

/// "Contractor note" card: note, work chips, laborers, voice note.
class UpdateNoteCard extends StatelessWidget {
  const UpdateNoteCard({super.key, required this.update});
  final SiteUpdate update;

  @override
  Widget build(BuildContext context) {
    final u = update;
    return SurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(u.byLaborer ? 'Note from ${u.authorName}${u.authorTrade.isNotEmpty ? ' · ${u.authorTrade}' : ''}' : 'Contractor note', style: AppText.muted),
          const SizedBox(height: 10),
          if (u.note.isNotEmpty) Text(u.note, style: const TextStyle(fontSize: 16, height: 1.55)),
          if (u.voiceNoteUrl.isNotEmpty) ...[const SizedBox(height: 12), VoiceNotePlayer(source: u.voiceNoteUrl)],
          if (u.workTypes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final w in u.workTypes) AppChip(label: w, dense: true)]),
          ],
          if (u.totalLaborers > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 18, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text('${u.totalLaborers} laborers on site', style: AppText.muted),
              ],
            ),
            if (u.laborers.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(u.laborers.map((l) => '${l.trade} ${l.count}').join(' · '), style: AppText.small),
            ],
          ],
        ],
      ),
    );
  }
}
