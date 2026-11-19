import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import '../../widgets/contact.dart';
import '../../widgets/media.dart';
import '../../widgets/thread.dart';

/// "Question from Abhinav" sheet: read the request, set status, reply, call or WhatsApp.
Future<void> showReplySheet(BuildContext context, WidgetRef ref, String requestId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.92),
        child: _ReplySheet(requestId: requestId),
      ),
    ),
  );
}

/// Full-page version used when opening a request from a notification.
class RequestReplyScreen extends StatelessWidget {
  const RequestReplyScreen({super.key, required this.requestId});
  final String requestId;
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: _ReplySheet(requestId: requestId, asPage: true)));
}

class _ReplySheet extends ConsumerStatefulWidget {
  const _ReplySheet({required this.requestId, this.asPage = false});
  final String requestId;
  final bool asPage;
  @override
  ConsumerState<_ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends ConsumerState<_ReplySheet> {
  final _reply = TextEditingController();
  String? _status; // selected, defaults to current
  bool _busy = false;

  static const _quick = ['Noted, will do', "We'll check today", 'Will call you shortly', "Done, see today's update", 'Other'];

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send(ClientRequest r) async {
    final text = _reply.text.trim();
    final status = _status ?? r.status;
    if (text.isEmpty && status == r.status) return showSnack(context, 'Write a reply or change the status', error: true);
    setState(() => _busy = true);
    try {
      final repo = ref.read(repoProvider);
      if (text.isEmpty) {
        await repo.setRequestStatus(r.id, status);
      } else {
        await repo.reply(r.id, text, status: status);
      }
      if (!mounted) return;
      _reply.clear();
      showSnack(context, text.isEmpty ? 'Status updated' : 'Reply sent');
      if (!widget.asPage) Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(requestDetailProvider(widget.requestId));
    return value.when(
      loading: () => const SizedBox(height: 300, child: LoadingView()),
      error: (e, _) => SizedBox(height: 300, child: ErrorView(error: e, onRetry: () => ref.invalidate(requestDetailProvider(widget.requestId)))),
      data: (r) {
        final status = _status ?? r.status;
        final clientName = r.client?.name ?? 'Client';
        final title = switch (r.type) {
          'change' => 'Change request from ${clientName.split(' ').first}',
          'approval' => '${clientName.split(' ').first} approved',
          'call' => '${clientName.split(' ').first} wants a call',
          _ => 'Question from ${clientName.split(' ').first}',
        };
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 4),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500))),
                  if (r.urgent) const Padding(padding: EdgeInsets.only(right: 8), child: StatusBadge('urgent', small: true)),
                  CircleIconButton(icon: widget.asPage ? Icons.arrow_back : Icons.close, tooltip: 'Close', onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  Text('${r.projectName} · ${Fmt.day(r.createdAt)} · ${Fmt.time(r.createdAt)}', style: AppText.small),
                  const SizedBox(height: 6),
                  Text(r.message, style: const TextStyle(fontSize: 20, height: 1.35)),
                  if (r.photos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (var i = 0; i < r.photos.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(onTap: () => openPhotoViewer(context, r.photos, i), child: SizedBox(width: 80, child: NetImage(r.photos[i], radius: 12))),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (r.voiceNoteUrl.isNotEmpty) ...[const SizedBox(height: 12), VoiceNotePlayer(source: r.voiceNoteUrl)],
                  if (r.updateId != null) ...[
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'View related update',
                      style: AppButtonStyle.outline,
                      onPressed: () {
                        if (!widget.asPage) Navigator.pop(context);
                        context.push('/updates/${r.updateId}');
                      },
                    ),
                  ],
                  if (r.replies.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    for (final reply in r.replies) ReplyBubble(reply: reply, mine: reply.authorRole == 'engineer'),
                  ],
                  if (r.type != 'approval') ...[
                    const SizedBox(height: 20),
                    PillTabs(
                      tabs: const ['New', 'In progress', 'Done'],
                      index: const ['new', 'in_progress', 'done'].indexOf(status),
                      onChanged: (i) => setState(() => _status = const ['new', 'in_progress', 'done'][i]),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final q in _quick)
                          AppChip(
                            label: q,
                            onTap: () => setState(() {
                              _reply.text = q == 'Other' ? '' : q;
                              if (q == "Done, see today's update") _status = 'done';
                              if (q == 'Noted, will do' || q == "We'll check today") _status = 'in_progress';
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(label: 'Reply', controller: _reply, maxLines: 4, minLines: 3, textCapitalization: TextCapitalization.sentences),
                    const SizedBox(height: 16),
                    AppButton(label: 'Send reply', orangeArrow: true, loading: _busy, onPressed: () => _send(r)),
                  ],
                  if (r.client?.phone.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    ContactButtons(phone: r.client!.phone, whatsappMessage: 'Hi ${clientName.split(' ').first}, about your ${Fmt.requestType(r.type).toLowerCase()}: '),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
