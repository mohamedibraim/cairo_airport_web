import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/navigation.dart';
import '../../core/data/fixtures.dart';
import '../../core/data/repository.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/l10n/strings.dart';
import '../../core/state/ops_state.dart';
import '../../core/state/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/primitives.dart';

class PredictionsScreen extends ConsumerWidget {
  const PredictionsScreen({super.key});

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final repo = ref.watch(repositoryProvider);
    final ops = ref.watch(opsProvider);
    final user = ref.watch(currentUserProvider);
    final canDecide =
        user != null &&
        Capability.allows(user.role, Capability.acknowledgeAlerts);

    final predictions = repo.predictions;
    final recommendations = repo.recommendations;
    final openRecommendations = recommendations
        .where(
          (r) => !{
            CaseStatus.resolved,
            CaseStatus.closed,
          }.contains(ops.recommendationDecision(r)),
        )
        .length;
    final highRecommendations = recommendations
        .where((r) => r.severity.index >= Severity.high.index)
        .length;
    final latestCutoff = predictions
        .map((p) => p.cutoff)
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);

    return PageBody(
      children: [
        PageIntro(
          eyebrow: s.tr('Monitoring & intelligence', 'المراقبة والذكاء'),
          title: s.tr(
            'AI predictions & recommendations',
            'توقعات وتوصيات الذكاء الاصطناعي',
          ),
          subtitle: s.tr(
            'Model outputs are quoted with their version, cutoff, horizon, evaluation domain and held-out metrics. No expected outcome is presented as an observed result.',
            'مخرجات النماذج معروضة مع إصدارها ووقت القطع والأفق ونطاق التقييم ومقاييس التحقق. لا يُعرض أي أثر متوقع كنتيجة مرصودة.',
          ),
          actions: [
            StatusPill(
              label: s.tr(
                'model output · not a measurement',
                'مخرج نموذج · ليس قياسًا',
              ),
              color: AppColors.info,
            ),
            OutlinedButton.icon(
              onPressed: () => context.go(Routes.simulation),
              icon: const Icon(Icons.science_outlined, size: 16),
              label: Text(
                s.tr('Compare in simulation', 'المقارنة في المحاكاة'),
              ),
            ),
          ],
        ),
        InfoBanner(
          icon: Icons.school_outlined,
          title: s.tr(
            'Evaluation domains do not transfer automatically',
            'نطاقات التقييم لا تنتقل تلقائيًا',
          ),
          message: s.tr(
            'Q1 was evaluated on held-out U.S. TSA checkpoints and M1 on seeded conveyor regimes. Both are domain proxies, not Cairo ground truth, and neither model is retrained in this demo.',
            'تم تقييم Q1 على نقاط تفتيش أمريكية مستبعدة، و M1 على أنظمة حزام مولّدة. كلاهما بديل نطاقي وليس قياسًا من القاهرة، ولا يُعاد تدريب أي نموذج في هذا العرض.',
          ),
          color: AppColors.info,
        ),
        ResponsiveGrid(
          desktop: 4,
          tablet: 2,
          mobile: 2,
          children: [
            _Metric(
              label: s.tr('Models in service', 'نماذج قيد الخدمة'),
              value: '${predictions.length}',
              unit: s.tr('models', 'نموذج'),
              hint: s.tr(
                'Q1 forecast · M1 anomaly score',
                'توقع Q1 · درجة شذوذ M1',
              ),
            ),
            _Metric(
              label: s.tr('Open recommendations', 'توصيات مفتوحة'),
              value: '$openRecommendations',
              unit: s.tr('items', 'بند'),
              hint: s.tr(
                'Not yet accepted or deferred',
                'لم تُقبل أو تُؤجل بعد',
              ),
              color: openRecommendations > 0
                  ? AppColors.warning
                  : AppColors.success,
            ),
            _Metric(
              label: s.tr('High-severity advisories', 'تنبيهات عالية الخطورة'),
              value: '$highRecommendations',
              unit: s.tr('items', 'بند'),
              hint: s.tr(
                'CON-003 repair and BG-2041 tracing',
                'إصلاح CON-003 وتتبع BG-2041',
              ),
              color: AppColors.danger,
            ),
            _Metric(
              label: s.tr('Latest cutoff', 'أحدث وقت قطع'),
              value: latestCutoff == null ? '—' : Fixtures.clock(latestCutoff),
              unit: 'UTC+2',
              hint: s.tr(
                'No inference has run since',
                'لا استدلال بعد هذا الوقت',
              ),
            ),
          ],
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: s.tr('Model outputs', 'مخرجات النماذج'),
                subtitle: s.tr(
                  'Point estimate, interval or threshold, and the evidence that qualifies it.',
                  'التقدير النقطي أو النطاق أو العتبة، والأدلة التي تؤهله.',
                ),
                trailing: StatusPill(
                  label: s.tr('no retraining', 'بدون إعادة تدريب'),
                  color: AppColors.muted,
                  compact: true,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              for (var i = 0; i < predictions.length; i++) ...[
                if (i != 0) const SizedBox(height: AppSpace.md),
                _ModelCard(
                  prediction: predictions[i],
                  s: s,
                  onSimulation: () => context.go(Routes.simulation),
                  onTwin: () => context.go(Routes.twin),
                ),
              ],
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: s.tr(
                  'Recommendations & decisions',
                  'التوصيات والقرارات',
                ),
                subtitle: s.tr(
                  'Each advisory links a problem, a proposed action and a measurement condition. Decisions are attributed and audit-logged.',
                  'كل توصية تربط المشكلة بالإجراء المقترح وشرط القياس. القرارات موثقة في سجل التدقيق.',
                ),
                trailing: StatusPill(
                  label: canDecide
                      ? s.tr('decision enabled', 'القرار متاح')
                      : s.tr('read-only role', 'دور للقراءة فقط'),
                  color: canDecide ? AppColors.success : AppColors.muted,
                  compact: true,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              if (recommendations.isEmpty)
                ViewStateMessage(
                  icon: Icons.task_alt,
                  title: s.tr('No open recommendations', 'لا توصيات مفتوحة'),
                  message: s.tr(
                    'The current fixture window contains no advisory items.',
                    'نافذة البيانات الحالية لا تحتوي بنود توصية.',
                  ),
                )
              else
                ResponsiveGrid(
                  desktop: 3,
                  tablet: 2,
                  mobile: 1,
                  children: [
                    for (final r in recommendations)
                      _RecommendationCard(
                        recommendation: r,
                        decision: ops.recommendationDecision(r),
                        canDecide: canDecide,
                        s: s,
                        onAccept: () {
                          ref
                              .read(opsProvider.notifier)
                              .decideRecommendation(
                                r,
                                CaseStatus.assigned,
                                user,
                              );
                          _toast(
                            context,
                            s.tr(
                              '${r.id} accepted and assigned in the demo session.',
                              'تم قبول ${r.id} وإسناده في جلسة العرض.',
                            ),
                          );
                        },
                        onDefer: () {
                          ref
                              .read(opsProvider.notifier)
                              .decideRecommendation(r, CaseStatus.open, user);
                          _toast(
                            context,
                            s.tr(
                              '${r.id} deferred; it stays open with no automatic action.',
                              'تم تأجيل ${r.id}؛ يبقى مفتوحًا دون إجراء تلقائي.',
                            ),
                          );
                        },
                      ),
                  ],
                ),
              const SizedBox(height: AppSpace.md),
              CardNote(
                s.tr(
                  'An accepted recommendation creates a demo decision only. It never dispatches staff, opens a purchase or changes a real asset.',
                  'قبول التوصية ينشئ قرارًا تجريبيًا فقط. لا يرسل موظفين ولا يفتح عملية شراء ولا يغيّر أصلًا حقيقيًا.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String hint;
  final Color? color;
  const _Metric({
    required this.label,
    required this.value,
    required this.unit,
    required this.hint,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: MiniStat(
        label: label,
        value: value,
        unit: unit,
        hint: hint,
        color: color,
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final Prediction prediction;
  final AppStrings s;
  final VoidCallback onSimulation;
  final VoidCallback onTwin;

  const _ModelCard({
    required this.prediction,
    required this.s,
    required this.onSimulation,
    required this.onTwin,
  });

  String _horizon(Duration d) {
    if (d.inHours >= 1) {
      final hours = d.inHours;
      return '$hours ${s.tr('h', 'ساعة')}';
    }
    return '${d.inMinutes} ${s.tr('min', 'دقيقة')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(AppRadius.nested),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.tealSoft,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: const Icon(
                  Icons.query_stats,
                  size: 18,
                  color: AppColors.action,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.arabic ? prediction.modelAr : prediction.modelEn,
                      style: t.titleSmall,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      s.arabic ? prediction.targetAr : prediction.targetEn,
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IdText(
                    prediction.version,
                    style: const TextStyle(fontSize: 9, color: AppColors.muted),
                  ),
                  const SizedBox(height: 2),
                  IdText(
                    prediction.id,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.action,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              LtrText(
                prediction.value,
                style: t.headlineSmall?.copyWith(
                  color: AppColors.navy,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  s.arabic ? prediction.unitAr : prediction.unitEn,
                  style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const Spacer(),
              Flexible(
                child: StatusPill(
                  label: prediction.interval,
                  color: AppColors.info,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          DetailRow(
            label: s.tr('Horizon', 'الأفق'),
            value: DetailValue(_horizon(prediction.horizon)),
          ),
          DetailRow(
            label: s.tr('Cutoff', 'وقت القطع'),
            value: DetailValue(
              '${Fixtures.clock(prediction.cutoff)} UTC+2 · ${Fixtures.date(prediction.cutoff)}',
              ltr: true,
            ),
          ),
          DetailRow(
            label: s.tr('Baseline', 'خط الأساس'),
            value: DetailValue(prediction.baseline),
          ),
          DetailRow(
            label: s.tr('Domain', 'النطاق'),
            value: Text(
              s.arabic ? prediction.domainAr : prediction.domainEn,
              style: t.bodySmall,
            ),
          ),
          DetailRow(
            label: s.tr('Evaluation', 'التقييم'),
            value: LtrText(
              prediction.metricSummary,
              style: t.bodySmall?.copyWith(color: AppColors.action),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          SourceBadge(meta: prediction.source, s: s, showStream: true),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              OutlinedButton.icon(
                onPressed: onSimulation,
                icon: const Icon(Icons.compare_arrows, size: 15),
                label: Text(s.tr('Scenario comparison', 'مقارنة السيناريو')),
              ),
              TextButton.icon(
                onPressed: onTwin,
                icon: const Icon(Icons.map_outlined, size: 15),
                label: Text(s.tr('Inspect on twin', 'الفحص على التوأم')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;
  final CaseStatus decision;
  final bool canDecide;
  final AppStrings s;
  final VoidCallback onAccept;
  final VoidCallback onDefer;

  const _RecommendationCard({
    required this.recommendation,
    required this.decision,
    required this.canDecide,
    required this.s,
    required this.onAccept,
    required this.onDefer,
  });

  bool get _decided =>
      decision == CaseStatus.assigned ||
      decision == CaseStatus.inProgress ||
      decision == CaseStatus.resolved ||
      decision == CaseStatus.closed;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SeverityBadge(severity: recommendation.severity, s: s),
              const Spacer(),
              IdText(
                recommendation.id,
                style: const TextStyle(fontSize: 9, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            s.arabic ? recommendation.titleAr : recommendation.titleEn,
            style: t.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            s.arabic ? recommendation.problemAr : recommendation.problemEn,
            style: t.bodySmall,
          ),
          const SizedBox(height: AppSpace.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpace.sm),
            decoration: BoxDecoration(
              color: AppColors.tealSoft,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.arrow_forward,
                  size: 13,
                  color: AppColors.action,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    s.arabic
                        ? recommendation.actionAr
                        : recommendation.actionEn,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.action,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.arabic ? recommendation.expectedAr : recommendation.expectedEn,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: 5,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusPill(
                label: decision.label(s),
                color: decision.color,
                compact: true,
              ),
              if (_decided)
                StatusPill(
                  label: s.tr('no real dispatch', 'بدون إرسال حقيقي'),
                  color: AppColors.muted,
                  compact: true,
                ),
              IdText(
                recommendation.entityId,
                style: const TextStyle(fontSize: 9, color: AppColors.action),
              ),
              IdText(
                recommendation.predictionId,
                style: const TextStyle(fontSize: 9, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: canDecide ? onAccept : null,
                  icon: const Icon(Icons.check, size: 15),
                  label: Text(
                    s.tr('Accept', 'قبول'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              OutlinedButton(
                onPressed: canDecide ? onDefer : null,
                child: Text(s.tr('Defer', 'تأجيل')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
