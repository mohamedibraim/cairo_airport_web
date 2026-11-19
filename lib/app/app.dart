import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/state/session.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class CairoTwinApp extends ConsumerWidget {
  const CairoTwinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: s.tr('Cairo Airport Digital Twin', 'التوأم الرقمي لمطار القاهرة'),
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(s),
      locale: s.locale,
      routerConfig: router,
      builder: (context, child) {
        return Directionality(
          textDirection: s.direction,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
