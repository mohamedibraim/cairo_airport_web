import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/navigation.dart';
import '../../core/data/fixtures.dart';
import '../../core/l10n/strings.dart';
import '../../core/state/ops_state.dart';
import '../../core/state/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/data_table.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/primitives.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _baseUrl = TextEditingController(
    text: 'https://api.cairo-twin.local/v1',
  );
  final _streamId = TextEditingController(text: 'demo-main');
  final _vibration = TextEditingController(text: '5.0');
  final _waitLow = TextEditingController(text: '8');
  final _waitHigh = TextEditingController(text: '12');
  final Map<String, String> _errors = {};

  bool _autoRefresh = true;
  bool _showSimulated = true;

  @override
  void dispose() {
    _baseUrl.dispose();
    _streamId.dispose();
    _vibration.dispose();
    _waitLow.dispose();
    _waitHigh.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String? _error(String key) {
    final value = _errors[key];
    return value == null || value.isEmpty ? null : value;
  }

  void _saveThresholds(AppStrings s) {
    final vibration = double.tryParse(_vibration.text.replaceAll(',', '.'));
    final low = int.tryParse(_waitLow.text);
    final high = int.tryParse(_waitHigh.text);
    final errors = <String, String>{};

    if (vibration == null || vibration <= 0) {
      errors['vibration'] = s.tr(
        'Enter a positive number.',
        'أدخل رقمًا موجبًا.',
      );
    }
    if (low == null || low <= 0) {
      errors['waitLow'] = s.tr(
        'Enter a positive number.',
        'أدخل رقمًا موجبًا.',
      );
    }
    if (high == null || high <= 0) {
      errors['waitHigh'] = s.tr(
        'Enter a positive number.',
        'أدخل رقمًا موجبًا.',
      );
    }
    if (low != null && high != null && low >= high) {
      errors['waitHigh'] = s.tr(
        'Upper band must exceed lower band.',
        'الحد الأعلى يجب أن يكبر الأدنى.',
      );
    }

    setState(
      () => _errors
        ..clear()
        ..addAll(errors),
    );
    if (errors.isNotEmpty) return;

    _toast(
      s.tr(
        'Thresholds validated locally: vibration ${_vibration.text}, wait ${_waitLow.text}–${_waitHigh.text}. No rule engine was updated.',
        'تم التحقق محليًا: الاهتزاز ${_vibration.text}، الانتظار ${_waitLow.text}–${_waitHigh.text}. لم يُحدّث محرك القواعد.',
      ),
    );
  }

  void _saveEndpoints(AppStrings s) {
    final url = _baseUrl.text.trim();
    final stream = _streamId.text.trim();
    final errors = <String, String>{};
    if (!url.startsWith('https://') && !url.startsWith('http://')) {
      errors['baseUrl'] = s.tr(
        'URL must start with http:// or https://',
        'يجب أن يبدأ الرابط بـ http:// أو https://',
      );
    }
    if (url.contains(' ')) {
      errors['baseUrl'] = s.tr(
        'URL cannot contain spaces.',
        'لا يمكن أن يحتوي الرابط على مسافات.',
      );
    }
    if (stream.isEmpty) {
      errors['streamId'] = s.tr('Stream ID is required.', 'معرف البث مطلوب.');
    }
    setState(
      () => _errors
        ..clear()
        ..addAll(errors),
    );
    if (errors.isNotEmpty) return;

    _toast(
      s.tr(
        'Endpoint string validated locally. No connection was attempted and nothing was persisted.',
        'تم التحقق من الرابط محليًا. لم تُجرَ أي اتصال ولم يُحفظ شيء.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final session = ref.watch(sessionProvider);
    final user = ref.watch(currentUserProvider);
    final ops = ref.watch(opsProvider);
    final canManage =
        user != null && Capability.allows(user.role, Capability.manageSettings);

    return PageBody(
      children: [
        PageIntro(
          eyebrow: s.tr('System', 'النظام'),
          title: s.tr('Settings', 'الإعدادات'),
          subtitle: s.tr(
            'Language, data mode, threshold entry, endpoint strings and demo-session controls. Nothing on this page persists beyond the running browser session.',
            'اللغة ونمط البيانات وإدخال الحدود ونصوص نقاط الواجهة والتحكم بجلسة العرض. لا يُحفظ شيء من هذه الصفحة بعد إغلاق جلسة المتصفح.',
          ),
          actions: [
            StatusPill(
              label: s.tr('local demo state', 'حالة عرض محلية'),
              color: AppColors.warning,
              compact: true,
            ),
            OutlinedButton.icon(
              onPressed: () => context.go(Routes.health),
              icon: const Icon(Icons.monitor_heart_outlined, size: 16),
              label: Text(s.tr('System health', 'صحة النظام')),
            ),
          ],
        ),
        ResponsiveGrid(
          desktop: 4,
          tablet: 2,
          mobile: 2,
          children: [
            _Metric(
              label: s.tr('Language', 'اللغة'),
              value: session.arabic ? 'العربية' : 'English',
              unit: session.arabic ? 'RTL' : 'LTR',
              hint: s.tr(
                'Applies to every screen immediately',
                'تُطبق على كل الشاشات فورًا',
              ),
            ),
            _Metric(
              label: s.tr('Data mode', 'نمط البيانات'),
              value: session.dataMode,
              unit: '',
              hint: s.tr(
                'Label only · fixtures remain unchanged',
                'تسمية فقط · البيانات دون تغيير',
              ),
              color: AppColors.info,
            ),
            _Metric(
              label: s.tr('Session role', 'دور الجلسة'),
              value: user?.role.code ?? '—',
              unit: '',
              hint: user == null ? '—' : user.role.label(s),
              color: AppColors.action,
            ),
            _Metric(
              label: s.tr('Audit entries', 'إدخالات التدقيق'),
              value: '${ops.audit.length}',
              unit: s.tr('actions', 'إجراء'),
              hint: s.tr(
                'Demo decisions recorded this session',
                'قرارات العرض المسجلة في هذه الجلسة',
              ),
              color: ops.audit.isEmpty ? AppColors.muted : AppColors.success,
            ),
          ],
        ),
        SplitPane(
          sideWidth: 420,
          breakpoint: 1060,
          main: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(
                      title: s.tr(
                        'Appearance & data mode',
                        'المظهر ونمط البيانات',
                      ),
                      subtitle: s.tr(
                        'Arabic is right-to-left with a dark right sidebar; English mirrors the layout.',
                        'العربية من اليمين إلى اليسار مع شريط جانبي داكن على اليمين؛ الإنجليزية تعكس التخطيط.',
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    _SettingBlock(
                      label: s.tr('Interface language', 'لغة الواجهة'),
                      child: ChoiceChips<bool>(
                        selected: session.arabic,
                        onChanged: (v) =>
                            ref.read(sessionProvider.notifier).setArabic(v),
                        options: const [(true, 'العربية'), (false, 'English')],
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    _SettingBlock(
                      label: s.tr('Data mode label', 'تسمية نمط البيانات'),
                      child: ChoiceChips<String>(
                        selected: session.dataMode,
                        onChanged: (v) =>
                            ref.read(sessionProvider.notifier).setDataMode(v),
                        options: [
                          ('demo', s.tr('Demo', 'تجريبي')),
                          ('replay', s.tr('Replay', 'إعادة عرض')),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    _SettingBlock(
                      label: s.tr('Display preferences', 'تفضيلات العرض'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SwitchListTile(
                            value: _autoRefresh,
                            onChanged: (v) => setState(() => _autoRefresh = v),
                            title: Text(
                              s.tr(
                                'Auto-refresh clock chip',
                                'تحديث ساعة الشريط تلقائيًا',
                              ),
                              style: const TextStyle(fontSize: 11),
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          SwitchListTile(
                            value: _showSimulated,
                            onChanged: (v) =>
                                setState(() => _showSimulated = v),
                            title: Text(
                              s.tr(
                                'Show simulated-source badges',
                                'إظهار شارات المصدر المحاكى',
                              ),
                              style: const TextStyle(fontSize: 11),
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    CardNote(
                      s.tr(
                        'The two switches are presentation placeholders: the clock is driven by the demo clock provider and source badges are required provenance, so neither can currently be disabled.',
                        'المفتاحان عنصرا عرض فقط: الساعة مدفوعة بمزوّد الساعة التجريبي وشارات المصدر مصدر إلزامي، لذلك لا يمكن تعطيل أي منهما حاليًا.',
                      ),
                      icon: Icons.tune,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(
                      title: s.tr('Operational thresholds', 'الحدود التشغيلية'),
                      subtitle: s.tr(
                        'Values are validated before display. The rule engine that would consume them is not part of this frontend-only delivery.',
                        'تُتحقق القيم قبل العرض. محرك القواعد الذي قد يستهلكها ليس جزءًا من هذا التسليم الواجهاتي.',
                      ),
                      trailing: StatusPill(
                        label: canManage
                            ? s.tr('save enabled', 'الحفظ متاح')
                            : s.tr('read-only', 'للقراءة فقط'),
                        color: canManage ? AppColors.success : AppColors.muted,
                        compact: true,
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    LayoutBuilder(
                      builder: (context, c) {
                        final narrow = c.maxWidth < 620;
                        final fields = [
                          TextField(
                            controller: _vibration,
                            enabled: canManage,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              labelText: s.tr(
                                'Vibration threshold',
                                'حد الاهتزاز',
                              ),
                              hintText: '5.0 mm/s',
                              errorText: _error('vibration'),
                              isDense: true,
                            ),
                          ),
                          TextField(
                            controller: _waitLow,
                            enabled: canManage,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              labelText: s.tr(
                                'Wait band lower (min)',
                                'الحد الأدنى للانتظار (د)',
                              ),
                              errorText: _error('waitLow'),
                              isDense: true,
                            ),
                          ),
                          TextField(
                            controller: _waitHigh,
                            enabled: canManage,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              labelText: s.tr(
                                'Wait band upper (min)',
                                'الحد الأعلى للانتظار (د)',
                              ),
                              errorText: _error('waitHigh'),
                              isDense: true,
                            ),
                          ),
                        ];
                        if (narrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final f in fields) ...[
                                f,
                                const SizedBox(height: AppSpace.md),
                              ],
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < fields.length; i++) ...[
                              if (i != 0) const SizedBox(width: AppSpace.md),
                              Expanded(child: fields[i]),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpace.md),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FilledButton.icon(
                        onPressed: canManage ? () => _saveThresholds(s) : null,
                        icon: const Icon(Icons.save_outlined, size: 16),
                        label: Text(s.tr('Validate values', 'التحقق من القيم')),
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    CardNote(
                      s.tr(
                        'Fixture alerts quote a 5.0 mm/s vibration rule and an 8–12 minute wait band. Changing these fields does not recalculate any alert.',
                        'تنبيهات البيانات الثابتة تشير إلى قاعدة 5.0 ملم/ث ونطاق انتظار 8–12 دقيقة. تغيير هذه الحقول لا يعيد حساب أي تنبيه.',
                      ),
                      icon: Icons.rule_folder_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(
                      title: s.tr('API connection', 'الاتصال بواجهة البرمجة'),
                      subtitle: s.tr(
                        'Intended shape for a future FastAPI backend. Entering a URL here does not create a client or attempt a request.',
                        'الشكل المقصود لواجهة خلفية FastAPI مستقبلية. إدخال رابط هنا لا ينشئ عميلًا ولا يحاول إرسال طلب.',
                      ),
                      trailing: const StatusPill(
                        label: 'HTTP · off',
                        color: AppColors.muted,
                        compact: true,
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    TextField(
                      controller: _baseUrl,
                      enabled: canManage,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        labelText: s.tr('Base URL', 'الرابط الأساسي'),
                        hintText: 'https://api.example/v1',
                        errorText: _error('baseUrl'),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    TextField(
                      controller: _streamId,
                      enabled: canManage,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        labelText: s.tr('Stream ID', 'معرف البث'),
                        hintText: 'demo-main',
                        errorText: _error('streamId'),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.sm,
                      children: [
                        FilledButton.icon(
                          onPressed: canManage ? () => _saveEndpoints(s) : null,
                          icon: const Icon(Icons.link_outlined, size: 16),
                          label: Text(s.tr('Validate URL', 'التحقق من الرابط')),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.go(Routes.health),
                          icon: const Icon(Icons.api, size: 16),
                          label: Text(
                            s.tr('View API contract', 'عرض عقد الواجهة'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          side: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(
                      title: s.tr('Demo session', 'جلسة العرض'),
                      subtitle: s.tr(
                        'Controls affect only local decisions in this browser tab.',
                        'تؤثر هذه العناصر على القرارات المحلية في تبويب المتصفح فقط.',
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    DetailRow(
                      label: s.tr('Signed in as', 'مسجل الدخول كـ'),
                      value: Text(
                        user == null
                            ? '—'
                            : (s.arabic ? user.nameAr : user.nameEn),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DetailRow(
                      label: s.tr('Role', 'الدور'),
                      value: user == null
                          ? const DetailValue('—')
                          : StatusPill(
                              label: user.role.label(s),
                              color: AppColors.action,
                              compact: true,
                            ),
                    ),
                    DetailRow(
                      label: s.tr('Terminal', 'المبنى'),
                      value: DetailValue(user?.terminal ?? '—', ltr: true),
                    ),
                    DetailRow(
                      label: s.tr('Reference clock', 'الساعة المرجعية'),
                      value: DetailValue(
                        '${Fixtures.date(Fixtures.reference)} ${Fixtures.clock(Fixtures.reference)} UTC+2',
                        ltr: true,
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    OutlinedButton.icon(
                      onPressed: canManage
                          ? () {
                              ref.read(opsProvider.notifier).resetAll(user);
                              _toast(
                                s.tr(
                                  'Demo decisions, pins and automation toggles were reset. The audit trail restarted.',
                                  'أُعيد تعيين قرارات العرض والتثبيتات ومفاتيح الأتمتة. أُعيد تشغيل سجل التدقيق.',
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.restore, size: 16),
                      label: Text(
                        s.tr(
                          'Reset demo decisions',
                          'إعادة تعيين قرارات العرض',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    FilledButton.icon(
                      onPressed: () {
                        ref.read(sessionProvider.notifier).logout();
                        context.go(Routes.login);
                      },
                      icon: const Icon(Icons.logout, size: 16),
                      label: Text(s.tr('Sign out', 'تسجيل الخروج')),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    if (!canManage)
                      CardNote(
                        s.tr(
                          'Only an Admin can reset demo decisions or validate settings. Switch role from the top bar or Staff & roles.',
                          'المدير فقط يستطيع إعادة تعيين قرارات العرض أو التحقق من الإعدادات. بدّل الدور من الشريط العلوي أو شاشة الموظفين والأدوار.',
                        ),
                        icon: Icons.lock_outline,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(
                      title: s.tr('Audit trail', 'سجل التدقيق'),
                      subtitle: s.tr(
                        'Local decisions only · newest first',
                        'قرارات محلية فقط · الأحدث أولًا',
                      ),
                      trailing: StatusPill(
                        label: '${ops.audit.length}',
                        color: AppColors.muted,
                        compact: true,
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    if (ops.audit.isEmpty)
                      ViewStateMessage(
                        icon: Icons.history_toggle_off,
                        title: s.tr('No decisions recorded', 'لا قرارات مسجلة'),
                        message: s.tr(
                          'Acknowledgements, assignments, pins and simulation decisions will appear here.',
                          'الإقرارات والإسنادات والتثبيتات وقرارات المحاكاة ستظهر هنا.',
                        ),
                      )
                    else
                      AppTable(
                        minWidth: 480,
                        columns: [
                          AppTableColumn(
                            s.tr('Time', 'الوقت'),
                            flex: 2,
                            numeric: true,
                          ),
                          AppTableColumn(s.tr('Action', 'الإجراء'), flex: 4),
                          AppTableColumn(
                            s.tr('Target', 'الهدف'),
                            flex: 2,
                            numeric: true,
                          ),
                        ],
                        rows: [
                          for (final a in ops.audit.take(8))
                            AppTableRow(
                              cells: [
                                LtrText(
                                  Fixtures.clock(a.at),
                                  style: const TextStyle(fontSize: 10),
                                ),
                                Text(
                                  s.arabic ? a.actionAr : a.actionEn,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    height: 1.35,
                                  ),
                                ),
                                IdText(
                                  a.target,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.action,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    const SizedBox(height: AppSpace.sm),
                    if (ops.audit.isNotEmpty)
                      CardNote(
                        s.tr(
                          'Audit entries live in memory and disappear on reload. They are not a compliance log.',
                          'إدخالات التدقيق مخزّنة في الذاكرة وتختفي عند إعادة التحميل. ليست سجل امتثال.',
                        ),
                        icon: Icons.info_outline,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        InfoBanner(
          icon: Icons.storage_outlined,
          title: s.tr('Frontend-only boundary', 'حدود الواجهة فقط'),
          message: s.tr(
            'There is no backend, database, authentication server, model training, real simulation engine or deployment step in this project. All writes update in-memory demo state and all values originate from labelled fixtures.',
            'لا يوجد في هذا المشروع خادم أو قاعدة بيانات أو مصادقة أو تدريب نماذج أو محاكاة حقيقية أو نشر. كل تعديل يغيّر حالة عرض في الذاكرة وكل القيم من بيانات ثابتة موصوفة.',
          ),
          color: AppColors.info,
        ),
      ],
    );
  }
}

class _SettingBlock extends StatelessWidget {
  final String label;
  final Widget child;
  const _SettingBlock({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 4),
        child,
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
