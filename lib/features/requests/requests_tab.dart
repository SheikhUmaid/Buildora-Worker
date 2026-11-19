import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import '../../widgets/thread.dart';
import 'reply_sheet.dart';

/// All client requests across the engineer's projects.
class RequestsTab extends ConsumerStatefulWidget {
  const RequestsTab({super.key});
  @override
  ConsumerState<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends ConsumerState<RequestsTab> {
  int _tab = 0;
  static const _statuses = [null, 'new', 'in_progress', 'done'];

  @override
  Widget build(BuildContext context) {
    final query = (status: _statuses[_tab], projectId: null, updateId: null);
    final value = ref.watch(requestsProvider(query));
    final counts = value.value?.counts ?? const {};
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text('Requests', style: AppText.h1), Text('Keep every client informed', style: AppText.muted)],
              ),
            ),
            const SizedBox(height: 16),
            ChipFilterBar(
              options: ['All', 'New${(counts['new'] ?? 0) > 0 ? ' (${counts['new']})' : ''}', 'In progress', 'Done'],
              selected: _tab,
              onSelected: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AsyncBody(
                value: value,
                onRetry: () => ref.invalidate(requestsProvider(query)),
                data: (res) => RefreshIndicator(
                  onRefresh: () => ref.refresh(requestsProvider(query).future),
                  child: res.requests.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 60),
                          EmptyState(icon: Icons.chat_bubble_outline, title: 'No requests here', message: 'Questions, change requests and approvals from clients appear here.'),
                        ])
                      : GroupedRequestList(
                          requests: res.requests,
                          forEngineer: true,
                          bottomPadding: 120,
                          onTap: (r) => showReplySheet(context, ref, r.id),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
