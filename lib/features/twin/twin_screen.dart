import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/fixtures.dart';
import '../../core/data/repository.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/state/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/data_table.dart';
import '../../core/widgets/inspector.dart';
import '../../core/widgets/layer_selector.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/primitives.dart';
import '../../core/widgets/twin_schematic.dart';

class TwinScreen extends ConsumerStatefulWidget {
  const TwinScreen({super.key});

  @override
  ConsumerState<TwinScreen> createState() => _TwinScreenState();
}

class _TwinScreenState extends ConsumerState<TwinScreen> {
  String? _selectedId = 'T2-BHS';
  final Set<TwinLayer> _layers = {
    TwinLayer.flow,
    TwinLayer.baggage,
    TwinLayer.equipment,
    TwinLayer.incidents,
  };

  List<TwinEntity> _related(TwinEntity? zone, List<TwinEntity> all) {
    if (zone == null) return const [];
    if (!zone.isZone) return all.where((e) => e.isZone).take(2).toList();
    return all.where((e) {
      if (e.isZone) return false;
      final cx = e.x + e.w / 2;
      final cy = e.y + e.h / 2;
      return cx >= zone.x &&
          cx <= zone.x + zone.w &&
          cy >= zone.y &&
          cy <= zone.y + zone.h;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final repo = ref.watch(repositoryProvider);
    final entities = repo.twinEntities;
    TwinEntity? selected;
    for (final e in entities) {
      if (e.id == _selectedId) selected = e;
    }
    final zones = entities.where((e) => e.isZone).toList();
    final nodes = entities.where((e) => !e.isZone).toList();
    final visibleZones = zones.where((z) => _layers.contains(z.layer)).length;

    return PageBody(
      children: [
        PageIntro(
          eyebrow: s.tr('Monitoring & intelligence', 'المراقبة والذكاء'),
          title: s.tr(
            'Terminal 2 digital twin',
            'التوأم الرقمي لمبنى الركاب 2',
          ),
          subtitle: s.tr(
            'A live-shaped 2D schematic of T2: stable zone IDs, state, source, freshness and event history. All geometry and values are simulated fixtures.',
            'مخطط ثنائي الأبعاد لمبنى 2: معرفات مناطق ثابتة، والحالة، والمصدر، والحداثة، وسجل الأحداث. كل الأشكال والقيم بيانات محاكاة.',
          ),
          actions: [
            StatusPill(
              label: s.tr('Simulated scene', 'مشهد محاكى'),
              color: AppColors.info,
              icon: Icons.science_outlined,
            ),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _layers
                    ..clear()
                    ..addAll(TwinLayer.values);
                  _selectedId = 'T2-BHS';
                });
              },
              icon: const Icon(Icons.restart_alt, size: 16),
              label: Text(s.tr('Reset view', 'إعادة ضبط العرض')),
            ),
          ],
        ),
        AppCard(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.tr('Layers', 'الطبقات'),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  _CountChip(
                    label: s.tr('zones', 'مناطق'),
                    value: '$visibleZones/${zones.length}',
                  ),
                  const SizedBox(width: 6),
                  _CountChip(
                    label: s.tr('nodes', 'عقد'),
                    value:
                        '${nodes.where((n) => _layers.contains(n.layer)).length}/${nodes.length}',
                  ),
                  const SizedBox(width: 6),
                  StatusPill(
                    label: s.tr('T2 · CAI', 'T2 · CAI'),
                    color: AppColors.action,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              LayerSelector(
                active: _layers,
                s: s,
                onToggle: (layer) {
                  setState(() {
                    if (_layers.contains(layer)) {
                      _layers.remove(layer);
                    } else {
                      _layers.add(layer);
                    }
                  });
                },
              ),
            ],
          ),
        ),
        SplitPane(
          sideWidth: 396,
          breakpoint: 1040,
          main: AppCard(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schema_outlined,
                        size: 15,
                        color: AppColors.action,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        s.tr(
                          'Schematic · Terminal 2 (normalized layout)',
                          'المخطط · مبنى 2 (تخطيط معياري)',
                        ),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        s.tr('Tap a zone or node', 'اضغط على منطقة أو عقدة'),
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                LayoutBuilder(
                  builder: (context, c) {
                    final h = c.maxWidth < 700 ? 360.0 : 540.0;
                    return SizedBox(
                      height: h,
                      child: TwinSchematic(
                        entities: entities,
                        activeLayers: _layers,
                        selectedId: selected?.id,
                        onSelect: (e) => setState(() => _selectedId = e.id),
                        s: s,
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpace.sm),
                Row(
                  children: [
                    const Expanded(
                      child: CardNote(
                        'Stable IDs: T2-ARR, T2-CHK, T2-BHS, T2-SEC, T2-IMM, T2-GA, T2-GB, T2-CLAIM · asset IDs follow CAI-T2-<area>-<type>-<nnn>.',
                        icon: Icons.tag,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(
                      label: s.tr('CustomPainter', 'رسم برمجي'),
                      color: AppColors.muted,
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          side: EntityInspector(
            entity: selected,
            related: _related(selected, entities),
            s: s,
            onClose: () => setState(() => _selectedId = null),
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: s.tr('Zone directory', 'دليل المناطق'),
                subtitle: s.tr(
                  'Every zone exposes state, data origin, last update and event count.',
                  'كل منطقة تعرض الحالة ومصدر البيانات وآخر تحديث وعدد الأحداث.',
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              AppTable(
                minWidth: 900,
                columns: const [
                  AppTableColumn('Zone', flex: 3),
                  AppTableColumn('Layer', flex: 2),
                  AppTableColumn('State', flex: 2),
                  AppTableColumn('Source', flex: 3),
                  AppTableColumn('Last update', flex: 2),
                  AppTableColumn(
                    'Events',
                    flex: 1,
                    alignment: AlignmentDirectional.centerEnd,
                  ),
                ],
                rows: [
                  for (final z in zones)
                    AppTableRow(
                      selected: z.id == selected?.id,
                      onTap: () => setState(() => _selectedId = z.id),
                      cells: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.arabic ? z.nameAr : z.nameEn,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IdText(
                              z.id,
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              z.layer.icon,
                              size: 12,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                z.layer.label(s),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        StateBadge(state: z.state, s: s),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StatusPill(
                              label: z.source.mode.label(s),
                              color: z.source.mode.color,
                              compact: true,
                            ),
                            const SizedBox(height: 2),
                            IdText(
                              z.source.sourceId,
                              style: const TextStyle(
                                fontSize: 8.5,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                Fixtures.clock(z.source.observedAt),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            StatusPill(
                              label: z.source.freshness.label(s),
                              color: z.source.freshness.color,
                              compact: true,
                            ),
                          ],
                        ),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            '${z.history.length}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        InfoBanner(
          icon: Icons.integration_instructions_outlined,
          title: s.tr('API-ready contract', 'عقد جاهز للربط'),
          message: s.tr(
            'Zones and nodes are read through TwinRepository. Replace FixtureTwinRepository with an HTTP adapter for GET /v1/twin/zones, /v1/twin/zones/{id}/metrics and /v1/twin/events without changing this screen.',
            'تُقرأ المناطق والعقد عبر TwinRepository. استبدل FixtureTwinRepository بمهايئ HTTP لنقاط /v1/twin/zones و/v1/twin/zones/{id}/metrics و/v1/twin/events دون تغيير هذه الشاشة.',
          ),
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final String value;
  const _CountChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
