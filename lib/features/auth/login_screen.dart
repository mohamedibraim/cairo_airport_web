import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/navigation.dart';
import '../../core/data/fixtures.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/l10n/strings.dart';
import '../../core/state/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  WebRole _role = WebRole.dutyOperator;
  final _email = TextEditingController(text: 'layla.hassan@cairo-airport.demo');
  final _password = TextEditingController(text: 'demo1234');
  bool _obscure = true;
  bool _remember = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  DemoUser _userFor(WebRole role) {
    for (final u in Fixtures.demoUsers) {
      if (u.role == role) return u;
    }
    return Fixtures.demoUsers.first;
  }

  void _submit(AppStrings s) {
    final email = _email.text.trim();
    final password = _password.text;
    if (!email.contains('@') || password.length < 6) {
      setState(() {
        _error = s.tr(
          'Enter a valid email and a password of at least 6 characters.',
          'أدخل بريدًا صحيحًا وكلمة مرور من 6 أحرف على الأقل.',
        );
      });
      return;
    }
    setState(() => _error = null);
    ref.read(sessionProvider.notifier).login(_userFor(_role));
    context.go(Routes.overview);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final form = _LoginForm(
      s: s,
      role: _role,
      onRole: (r) {
        setState(() {
          _role = r;
          final u = _userFor(r);
          _email.text =
              '${u.nameEn.toLowerCase().replaceAll(' ', '.')}@cairo-airport.demo';
        });
      },
      email: _email,
      password: _password,
      obscure: _obscure,
      onToggleObscure: () => setState(() => _obscure = !_obscure),
      remember: _remember,
      onRemember: (v) => setState(() => _remember = v),
      error: _error,
      onSubmit: () => _submit(s),
      user: _userFor(_role),
    );

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(flex: 5, child: _BrandPanel()),
                  Expanded(flex: 4, child: Center(child: form)),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  children: [
                    const _CompactBrand(),
                    const SizedBox(height: AppSpace.lg),
                    form,
                    const SizedBox(height: AppSpace.lg),
                    _DemoNotice(s: s),
                  ],
                ),
              ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final AppStrings s;
  final WebRole role;
  final ValueChanged<WebRole> onRole;
  final TextEditingController email;
  final TextEditingController password;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool remember;
  final ValueChanged<bool> onRemember;
  final String? error;
  final VoidCallback onSubmit;
  final DemoUser user;

  const _LoginForm({
    required this.s,
    required this.role,
    required this.onRole,
    required this.email,
    required this.password,
    required this.obscure,
    required this.onToggleObscure,
    required this.remember,
    required this.onRemember,
    required this.error,
    required this.onSubmit,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (MediaQuery.sizeOf(context).width >= 980)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _LangButtons(s: s),
            ),
          const SizedBox(height: AppSpace.md),
          Text(
            s.tr(
              'Sign in to the command center',
              'تسجيل الدخول إلى مركز القيادة',
            ),
            style: t.headlineSmall?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            s.tr(
              'Select a demo role to explore the role-based web workspace.',
              'اختر دورًا تجريبيًا لاستكشاف مساحة العمل حسب الصلاحيات.',
            ),
            style: t.bodySmall?.copyWith(height: 1.5),
          ),
          const SizedBox(height: AppSpace.xl),
          Text(s.tr('Demo role', 'الدور التجريبي'), style: t.labelMedium),
          const SizedBox(height: 6),
          DropdownButtonFormField<WebRole>(
            initialValue: role,
            isDense: true,
            items: [
              for (final r in WebRole.values)
                DropdownMenuItem(value: r, child: Text(r.label(s))),
            ],
            onChanged: (v) {
              if (v != null) onRole(v);
            },
          ),
          const SizedBox(height: AppSpace.sm),
          Container(
            padding: const EdgeInsets.all(AppSpace.sm),
            decoration: BoxDecoration(
              color: AppColors.soft,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.action.withValues(alpha: 0.12),
                  child: Text(
                    user.nameEn.split(' ').map((e) => e[0]).take(2).join(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.action,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.arabic ? user.nameAr : user.nameEn,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${user.id} · ${s.tr('Terminal', 'مبنى')} ${user.terminal}',
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IdText(
                  user.role.code,
                  style: const TextStyle(fontSize: 9, color: AppColors.action),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(s.tr('Work email', 'البريد الإلكتروني'), style: t.labelMedium),
          const SizedBox(height: 6),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              hintText: 'name@cairo-airport.demo',
              prefixIcon: Icon(
                Icons.alternate_email,
                size: 16,
                color: AppColors.muted,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(s.tr('Password', 'كلمة المرور'), style: t.labelMedium),
          const SizedBox(height: 6),
          TextField(
            controller: password,
            obscureText: obscure,
            style: const TextStyle(fontSize: 12),
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(
                Icons.lock_outline,
                size: 16,
                color: AppColors.muted,
              ),
              suffixIcon: IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              Checkbox(
                value: remember,
                onChanged: (v) => onRemember(v ?? false),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 2),
              Text(
                s.tr('Keep me signed in', 'إبقاء الجلسة مفتوحة'),
                style: t.bodySmall,
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpace.sm),
            InfoBanner(
              icon: Icons.error_outline,
              title: s.tr('Check your credentials', 'راجع بيانات الدخول'),
              message: error!,
              color: AppColors.danger,
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          FilledButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.login, size: 17),
            label: Text(s.tr('Sign in to demo', 'دخول البيئة التجريبية')),
          ),
          const SizedBox(height: AppSpace.md),
          _DemoNotice(s: s),
        ],
      ),
    );
  }
}

class _DemoNotice extends StatelessWidget {
  final AppStrings s;
  const _DemoNotice({required this.s});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 13, color: AppColors.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            s.tr(
              'Frontend demonstration only. No real authentication, no live Cairo Airport feed, and every value is simulated fixture data.',
              'عرض واجهة فقط. لا توجد مصادقة حقيقية ولا بث حي من مطار القاهرة، وكل القيم بيانات محاكاة ثابتة.',
            ),
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.muted,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _LangButtons extends ConsumerWidget {
  final AppStrings s;
  const _LangButtons({required this.s});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final ar in [true, false])
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4),
            child: InkWell(
              onTap: () => ref.read(sessionProvider.notifier).setArabic(ar),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: s.arabic == ar ? AppColors.action : AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: s.arabic == ar ? AppColors.action : AppColors.border,
                  ),
                ),
                child: Text(
                  ar ? 'العربية' : 'English',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: s.arabic == ar ? Colors.white : AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpace.md),
      padding: const EdgeInsets.all(AppSpace.xxl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.sidebarTop, AppColors.navy],
        ),
        borderRadius: BorderRadius.circular(AppRadius.major),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandMark(),
          const Spacer(),
          const _BrandCopy(),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.nested),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: _BrandStat(
                    value: '154',
                    labelEn: 'Flights today',
                    labelAr: 'رحلات اليوم',
                  ),
                ),
                _BrandDivider(),
                Expanded(
                  child: _BrandStat(
                    value: 'T2',
                    labelEn: 'Terminal scope',
                    labelAr: 'نطاق المبنى',
                  ),
                ),
                _BrandDivider(),
                Expanded(
                  child: _BrandStat(
                    value: '5',
                    labelEn: 'Role profiles',
                    labelAr: 'ملفات الأدوار',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          const Text(
            'CAI · HECA · Cairo, Egypt · UTC+2',
            style: TextStyle(color: AppColors.onSidebarMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: const Icon(
            Icons.flight_takeoff,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpace.md),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CAIRO AIRPORT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'DIGITAL TWIN · WEB',
              style: TextStyle(
                color: AppColors.onSidebarMuted,
                fontSize: 8.5,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BrandCopy extends StatelessWidget {
  const _BrandCopy();
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مركز العمليات التشغيلية',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Digital twin command center for Terminal 2 operations: flights, passenger flow, baggage, equipment and incidents in one operational picture.',
          style: TextStyle(
            color: AppColors.onSidebar,
            fontSize: 12,
            height: 1.7,
          ),
        ),
        SizedBox(height: 20),
        _BrandBullet(
          icon: Icons.hub_outlined,
          en: 'Interactive 2D terminal schematic with stable zone IDs',
          ar: 'مخطط تفاعلي ثنائي الأبعاد بمعرفات مناطق ثابتة',
        ),
        SizedBox(height: 10),
        _BrandBullet(
          icon: Icons.verified_outlined,
          en: 'Every value carries source mode, as-of time and freshness',
          ar: 'كل قيمة تحمل مصدرها ووقتها وحداثتها',
        ),
        SizedBox(height: 10),
        _BrandBullet(
          icon: Icons.shield_outlined,
          en: 'Role-based views with an explicit audit trail',
          ar: 'عروض حسب الدور مع سجل تدقيق واضح',
        ),
      ],
    );
  }
}

class _BrandBullet extends StatelessWidget {
  final IconData icon;
  final String en;
  final String ar;
  const _BrandBullet({required this.icon, required this.en, required this.ar});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$ar · $en',
            style: const TextStyle(
              color: AppColors.onSidebar,
              fontSize: 10.5,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandStat extends StatelessWidget {
  final String value;
  final String labelEn;
  final String labelAr;
  const _BrandStat({
    required this.value,
    required this.labelEn,
    required this.labelAr,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '$labelAr · $labelEn',
          style: const TextStyle(
            color: AppColors.onSidebarMuted,
            fontSize: 8.5,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _BrandDivider extends StatelessWidget {
  const _BrandDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withValues(alpha: 0.12),
    );
  }
}

class _CompactBrand extends StatelessWidget {
  const _CompactBrand();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.sidebarTop, AppColors.navy],
        ),
        borderRadius: BorderRadius.circular(AppRadius.major),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BrandMark(),
          SizedBox(height: AppSpace.lg),
          Text(
            'مركز العمليات التشغيلية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Cairo International Airport · Terminal 2 digital twin (demo)',
            style: TextStyle(
              color: AppColors.onSidebar,
              fontSize: 10.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
