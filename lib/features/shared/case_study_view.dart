import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/media.dart';

/// Read-only parts of a portfolio case study: header, stats, story, highlights, feedback.
class CaseStudyHeader extends StatelessWidget {
  const CaseStudyHeader({super.key, required this.study});
  final CaseStudy study;

  @override
  Widget build(BuildContext context) {
    final s = study;
    final subtitle = [
      if (s.location.isNotEmpty) s.location,
      if (s.completedAt != null) 'Completed ${Fmt.date(s.completedAt)}' else Fmt.statusLabel(s.status),
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
        if (s.clientName != null && s.clientName!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text('Client: ${s.clientName}', style: AppText.small),
        ],
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            StatTile(boxed: true, value: Fmt.plural(s.durationMonths, 'month'), label: 'Duration'),
            StatTile(boxed: true, value: '${s.updates}', label: 'Updates'),
            StatTile(boxed: true, value: '${s.photos}', label: 'Photos'),
            StatTile(boxed: true, value: '${s.peakLaborers}', label: 'Peak laborers'),
            StatTile(boxed: true, value: '${s.progress}%', label: 'Progress'),
          ],
        ),
      ],
    );
  }
}

class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.rating, this.size = 20, this.onChanged});
  final int rating;
  final double size;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Tappable(
            scale: 0.8,
            haptic: true,
            onTap: onChanged == null ? null : () => onChanged!(i),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(i <= rating ? Icons.star_rounded : Icons.star_outline_rounded, size: size, color: i <= rating ? const Color(0xFFF5B90F) : AppColors.textFaint),
            ),
          ),
      ],
    );
  }
}

class FeedbackCard extends StatelessWidget {
  const FeedbackCard({super.key, required this.feedback, this.trailing});
  final ProjectFeedback feedback;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StarRow(rating: feedback.rating),
          if (feedback.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('"${feedback.text}"', style: const TextStyle(fontSize: 15, height: 1.4)),
          ],
          const SizedBox(height: 8),
          Text('- ${feedback.authorName}', style: AppText.muted),
          ?trailing,
        ],
      ),
    );
  }
}

/// Full read-only case study page body (used by the client app).
class CaseStudyBody extends StatelessWidget {
  const CaseStudyBody({super.key, required this.study});
  final CaseStudy study;

  @override
  Widget build(BuildContext context) {
    final s = study;
    final photos = s.highlights.isNotEmpty ? s.highlights : [if (s.coverImage.isNotEmpty) s.coverImage];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        PhotoCarousel(photos: photos, height: 240),
        const SizedBox(height: 20),
        CaseStudyHeader(study: s),
        if (s.story.isNotEmpty) ...[
          const SectionTitle('The story'),
          Text(s.story, style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.textMuted)),
        ],
        if (s.highlights.length > 1) ...[
          const SectionTitle('Highlights'),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (var i = 0; i < s.highlights.length; i++)
                PhotoThumb(photos: s.highlights, index: i, scope: 'highlight'),
            ],
          ),
        ],
        if (s.feedback.isNotEmpty) ...[
          const SectionTitle('Client feedback'),
          for (final f in s.feedback) Padding(padding: const EdgeInsets.only(bottom: 10), child: FeedbackCard(feedback: f)),
        ],
        if (s.location.isNotEmpty) ...[
          const SizedBox(height: 16),
          LocationText(s.location, size: 14),
        ],
      ],
    );
  }
}
