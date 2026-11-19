import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/repository.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/l10n/strings.dart';
import '../../core/state/ops_state.dart';
import '../../core/state/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/data_table.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/primitives.dart';

class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  String _role = 'all';
  String _availability = 'all';
  String _query = '';
  String? _selectedId = 'U-DUTY-01';
  final List<StaffMember> _extra = [];

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  bool _matches(StaffMember m) {
    final roleOk = _role == 'all' || m.role.name == _role;
    final availOk = switch (_availability) {
      'available' => m.available,
      'unavailable' => !m.available,
      _ => true,
    };
    final q = _query.trim().toLowerCase();
    final queryOk =
        q.isEmpty ||
        m.id.toLowerCase().contains(q) ||
        m.nameEn.toLowerCase().contains(q) ||
        m.nameAr.contains(q) ||
        m.role.code.toLowerCase().contains(q) ||
        (m.skills?.toLowerCase().contains(q) ?? false);
    return roleOk && availOk && queryOk;
  }

  Future<void> _openInvite(AppStrings s) async {
    final name = TextEditingController();
    final terminal = TextEditingController(text: 'T2');
    var role = WebRole.dutyOperator;
    var error = '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(s.tr('Invite staff member', 'دعوة موظف')),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: name,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          labelText: s.tr('Full name', 'الاسم الكامل'),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      TextField(
                        controller: terminal,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          labelText: s.tr('Terminal scope', 'نطاق المبنى'),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      Text(
                        s.tr('Role', 'الدور'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ChoiceChips<WebRole>(
                        selected: role,
                        onChanged: (v) => setDialogState(() => role = v),
                        options: [
                          for (final r in WebRole.values) (r, r.label(s)),
                        ],
                      ),
                      if (error.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.sm),
                        Text(
                          error,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpace.md),
                      CardNote(
                        s.tr(
                          'The invitation is a local demo record only. No email, identity provider or access grant is created.',
                          'الدعوة سجل تجريبي محلي فقط. لا يُنشأ بريد أو مزوّد هوية أو منح وصول.',
                        ),
                        icon: Icons.mail_outline,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(s.tr('Cancel', 'إلغاء')),
                ),
                FilledButton(
                  onPressed: () {
                    final trimmed = name.text.trim();
                    if (trimmed.isEmpty) {
                      setDialogState(
                        () =>
                            error = s.tr('A name is required.', 'الاسم مطلوب.'),
                      );
                      return;
                    }
                    final id =
                        'U-LOC-${(_extra.length + 1).toString().padLeft(2, '0')}';
                    setState(() {
                      _extra.add(
                        StaffMember(
                          id: id,
                          nameEn: trimmed,
                          nameAr: trimmed,
                          role: role,
                          terminal: terminal.text.trim().isEmpty
                              ? 'T2'
                              : terminal.text.trim(),
                          shiftEn: '09:00–17:00',
                          shiftAr: '09:00–17:00',
                          available: true,
                        ),
                      );
                      _selectedId = id;
                    });
                    Navigator.of(dialogContext).pop();
                    _toast(
                      s.tr(
                        '$id added to the demo roster only. No account exists.',
                        'أُضيف $id إلى كشف العرض فقط. لا يوجد حساب فعلي.',
                      ),
                    );
                  },
                  child: Text(
                    s.tr('Add to demo roster', 'إضافة إلى كشف العرض'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    name.dispose();
    terminal.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final repo = ref.watch(repositoryProvider);
    final user = ref.watch(currentUserProvider);
    final canManageUsers =
        user != null && Capability.allows(user.role, Capability.manageUsers);

    final all = [...repo.staff, ..._extra];
    final filtered = all.where(_matches).toList();
    StaffMember? selected;
    for (final m in all) {
      if (m.id == _selectedId) selected = m;
    }
    selected ??= filtered.isEmpty ? null : filtered.first;

    final available = all.where((m) => m.available).length;
    final coveredRoles = all.map((m) => m.role).toSet().length;

    return PageBody(
      children: [
        PageIntro(
          eyebrow: s.tr('System', 'النظام'),
          title: s.tr('Staff & roles', 'الموظفون والأدوار'),
          subtitle: s.tr(
            'Roster, shift coverage and the web capability matrix. Enforcement here is presentation-only and never a security boundary.',
            'الكشف والتغطية ومصفوفة صلاحيات الويب. التطبيق هنا للعرض فقط وليس حدًا أمنيًا.',
          ),
          actions: [
            StatusPill(
              label: s.tr('${all.length} members', '${all.length} عضوًا'),
              color: AppColors.info,
              compact: true,
            ),
            OutlinedButton.icon(
              onPressed: canManageUsers
                  ? () => _openInvite(s)
                  : () {
                      _toast(
                        s.tr(
                          'Only an Admin can invite staff in this demo.',
                          'المدير فقط يستطيع دعوة الموظفين في هذا العرض.',
                        ),
                      );
                    },
              icon: Icon(
                canManageUsers ? Icons.person_add_alt : Icons.lock_outline,
                size: 16,
              ),
              label: Text(s.tr('Invite member', 'دعوة عضو')),
            ),
          ],
        ),
        ResponsiveGrid(
          desktop: 4,
          tablet: 2,
          mobile: 2,
          children: [
            _Metric(
              label: s.tr('Roster size', 'حجم الكشف'),
              value: '${all.length}',
              unit: s.tr('people', 'شخص'),
              hint: s.tr(
                '${_extra.length} added in this session',
                '${_extra.length} أُضيفوا في هذه الجلسة',
              ),
            ),
            _Metric(
              label: s.tr('Available now', 'متاح الآن'),
              value: '$available',
              unit: s.tr('people', 'شخص'),
              hint: s.tr(
                '${all.length - available} off shift or unavailable',
                '${all.length - available} خارج الوردية أو غير متاح',
              ),
              color: AppColors.success,
            ),
            _Metric(
              label: s.tr('Roles covered', 'أدوار مغطاة'),
              value: '$coveredRoles',
              unit: s.tr('of 5', 'من 5'),
              hint: s.tr(
                'Duty, maintenance, security, analyst, admin',
                'خدمة، صيانة، أمن، محلل، مدير',
              ),
            ),
            _Metric(
              label: s.tr('Session identity', 'هوية الجلسة'),
              value: user?.role.code ?? '—',
              unit: '',
              hint: user == null
                  ? s.tr('Not signed in', 'غير مسجل')
                  : (s.arabic ? user.nameAr : user.nameEn),
              color: AppColors.action,
            ),
          ],
        ),
        AppCard(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ChoiceChips<String>(
                selected: _role,
                onChanged: (v) => setState(() => _role = v),
                options: [
                  ('all', s.tr('Any role', 'أي دور')),
                  for (final r in WebRole.values) (r.name, r.label(s)),
                ],
              ),
              ChoiceChips<String>(
                selected: _availability,
                onChanged: (v) => setState(() => _availability = v),
                options: [
                  ('all', s.tr('Any availability', 'أي توفر')),
                  ('available', s.tr('Available', 'متاح')),
                  ('unavailable', s.tr('Unavailable', 'غير متاح')),
                ],
              ),
              SearchField(
                hint: s.tr('Name, ID, skill', 'اسم، معرف، مهارة'),
                width: 220,
                onChanged: (v) => setState(() => _query = v),
              ),
            ],
          ),
        ),
        SplitPane(
          sideWidth: 380,
          breakpoint: 1040,
          main: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: s.tr('Roster', 'كشف الموظفين'),
                  subtitle: s.tr(
                    '${filtered.length} of ${all.length} members match · tap a row to inspect',
                    '${filtered.length} من ${all.length} عضوًا مطابق · اضغط صفًا للفحص',
                  ),
                  trailing: StatusPill(
                    label: s.tr('demo roster', 'كشف تجريبي'),
                    color: AppColors.muted,
                    compact: true,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                AppTable(
                  minWidth: 660,
                  emptyMessage: s.tr(
                    'No staff match these filters.',
                    'لا موظفين مطابقين لهذه العوامل.',
                  ),
                  columns: [
                    AppTableColumn(s.tr('Member', 'العضو'), flex: 4),
                    AppTableColumn(s.tr('Role', 'الدور'), flex: 3),
                    AppTableColumn(
                      s.tr('Terminal', 'المبنى'),
                      flex: 2,
                      numeric: true,
                    ),
                    AppTableColumn(
                      s.tr('Shift', 'الوردية'),
                      flex: 2,
                      numeric: true,
                    ),
                    AppTableColumn(s.tr('Availability', 'التوفر'), flex: 2),
                  ],
                  rows: [
                    for (final m in filtered)
                      AppTableRow(
                        selected: m.id == selected?.id,
                        onTap: () => setState(() => _selectedId = m.id),
                        cells: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.arabic ? m.nameAr : m.nameEn,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              IdText(
                                m.id,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            m.role.label(s),
                            style: const TextStyle(fontSize: 10.5),
                          ),
                          IdText(
                            m.terminal,
                            style: const TextStyle(fontSize: 10.5),
                          ),
                          LtrText(
                            m.shiftEn,
                            style: const TextStyle(fontSize: 10.5),
                          ),
                          StatusPill(
                            label: m.available
                                ? s.tr('Available', 'متاح')
                                : s.tr('Unavailable', 'غير متاح'),
                            color: m.available
                                ? AppColors.success
                                : AppColors.muted,
                            compact: true,
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                CardNote(
                  s.tr(
                    'Shift ranges are fixture strings in UTC+2. The roster is not connected to an HR or identity system.',
                    'فترات الوردية نصوص ثابتة بتوقيت UTC+2. الكشف غير مرتبط بنظام موارد بشرية أو هوية.',
                  ),
                  icon: Icons.badge_outlined,
                ),
              ],
            ),
          ),
          side: selected == null
              ? AppCard(
                  child: SizedBox(
                    height: 220,
                    child: ViewStateMessage(
                      icon: Icons.groups_outlined,
                      title: s.tr('No member selected', 'لا عضو محدد'),
                      message: s.tr(
                        'Clear the filters or pick a row to inspect role capabilities.',
                        'امسح عوامل التصفية أو اختر صفًا لفحص صلاحيات الدور.',
                      ),
                    ),
                  ),
                )
              : _StaffDetail(
                  member: selected,
                  s: s,
                  isCurrent: user?.id == selected.id,
                  onSwitch: () {
                    ref
                        .read(sessionProvider.notifier)
                        .switchRole(selected!.role);
                    _toast(
                      s.tr(
                        'Demo session switched to ${selected.role.label(s)}. This changes available actions across every screen.',
                        'تم تحويل جلسة العرض إلى ${selected.role.label(s)}. يتغير ما هو متاح في كل الشاشات.',
                      ),
                    );
                  },
                ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: s.tr(
                  'Role ↔ capability matrix',
                  'مصفوفة الدور ↔ الصلاحية',
                ),
                subtitle: s.tr(
                  'Which web actions each role may attempt. Write actions in other screens read from this same matrix.',
                  'الإجراءات المتاحة لكل دور. إجراءات الكتابة في بقية الشاشات تقرأ من هذه المصفوفة نفسها.',
                ),
                trailing: StatusPill(
                  label: s.tr('presentation only', 'للعرض فقط'),
                  color: AppColors.warning,
                  compact: true,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              AppTable(
                minWidth: 740,
                columns: [
                  AppTableColumn(s.tr('Capability', 'الصلاحية'), flex: 4),
                  for (final r in WebRole.values)
                    AppTableColumn(
                      r.code,
                      flex: 2,
                      numeric: true,
                      alignment: AlignmentDirectional.center,
                    ),
                ],
                rows: [
                  for (final cap in Capability.all)
                    AppTableRow(
                      cells: [
                        Text(
                          Capability.label(cap, s.arabic),
                          style: const TextStyle(fontSize: 10.5),
                        ),
                        for (final r in WebRole.values)
                          Icon(
                            Capability.allows(r, cap)
                                ? Icons.check_circle
                                : Icons.remove_circle_outline,
                            size: 15,
                            color: Capability.allows(r, cap)
                                ? AppColors.success
                                : AppColors.muted.withValues(alpha: 0.55),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: 10,
                runSpacing: 4,
                children: [
                  for (final r in WebRole.values)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IdText(
                          r.code,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.action,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          r.label(s),
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              CardNote(
                s.tr(
                  'This matrix hides or disables buttons in the demo. A real deployment must enforce authorization on the server for every endpoint.',
                  'هذه المصفوفة تخفي أو تعطل الأزرار في العرض. النشر الحقيقي يجب أن يفرض التخويل على الخادم لكل واجهة.',
                ),
                icon: Icons.security,
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

class _StaffDetail extends StatelessWidget {
  final StaffMember member;
  final AppStrings s;
  final bool isCurrent;
  final VoidCallback onSwitch;
  const _StaffDetail({
    required this.member,
    required this.s,
    required this.isCurrent,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final allowed = Capability.all
        .where((c) => Capability.allows(member.role, c))
        .toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: s.tr('Member detail', 'تفاصيل العضو'),
            trailing: StatusPill(
              label: member.role.code,
              color: AppColors.action,
              compact: true,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(s.arabic ? member.nameAr : member.nameEn, style: t.titleMedium),
          const SizedBox(height: 2),
          IdText(
            member.id,
            style: const TextStyle(fontSize: 10, color: AppColors.muted),
          ),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusPill(
                label: member.role.label(s),
                color: AppColors.info,
                compact: true,
              ),
              StatusPill(
                label: member.available
                    ? s.tr('available', 'متاح')
                    : s.tr('unavailable', 'غير متاح'),
                color: member.available ? AppColors.success : AppColors.muted,
                compact: true,
              ),
              if (isCurrent)
                StatusPill(
                  label: s.tr('this session', 'هذه الجلسة'),
                  color: AppColors.action,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          DetailRow(
            label: s.tr('Terminal', 'المبنى'),
            value: DetailValue(member.terminal, ltr: true),
          ),
          DetailRow(
            label: s.tr('Shift', 'الوردية'),
            value: DetailValue('${member.shiftEn} UTC+2', ltr: true),
          ),
          DetailRow(
            label: s.tr('Skills', 'المهارات'),
            value: DetailValue(
              member.skills ?? s.tr('Not recorded', 'غير مسجلة'),
              ltr: member.skills != null,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            s.tr('Allowed capabilities', 'الصلاحيات المسموحة'),
            style: t.titleSmall,
          ),
          const SizedBox(height: 4),
          for (final cap in Capability.all)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    allowed.contains(cap) ? Icons.check : Icons.close,
                    size: 13,
                    color: allowed.contains(cap)
                        ? AppColors.success
                        : AppColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      Capability.label(cap, s.arabic),
                      style: TextStyle(
                        fontSize: 10,
                        color: allowed.contains(cap)
                            ? AppColors.text
                            : AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpace.md),
          FilledButton.icon(
            onPressed: onSwitch,
            icon: const Icon(Icons.switch_account, size: 16),
            label: Text(
              s.tr('Use this role in the demo', 'استخدم هذا الدور في العرض'),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          CardNote(
            s.tr(
              'Switching changes which buttons are enabled immediately. It does not sign in a real identity.',
              'التبديل يغيّر الأزرار المتاحة فورًا. لا يسجل دخول هوية حقيقية.',
            ),
            icon: Icons.sync_alt,
          ),
        ],
      ),
    );
  }
}
