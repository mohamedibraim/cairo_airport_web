import 'package:flutter/material.dart';
import '../core/l10n/strings.dart';

enum NavGroup { operations, monitoring, system }

class NavDestination {
  final String path;
  final NavGroup group;
  final String labelEn;
  final String labelAr;
  final IconData icon;
  const NavDestination({
    required this.path,
    required this.group,
    required this.labelEn,
    required this.labelAr,
    required this.icon,
  });

  String label(AppStrings s) => s.tr(labelEn, labelAr);
}

abstract final class Routes {
  static const login = '/login';
  static const overview = '/ops/overview';
  static const flights = '/ops/flights';
  static const flow = '/ops/flow';
  static const baggage = '/ops/baggage';
  static const maintenance = '/ops/maintenance';
  static const twin = '/twin';
  static const incidents = '/ops/incidents';
  static const events = '/ops/events';
  static const predictions = '/ops/predictions';
  static const simulation = '/ops/simulation';
  static const reports = '/ops/reports';
  static const staff = '/system/staff';
  static const health = '/system/health';
  static const settings = '/system/settings';

  static const destinations = <NavDestination>[
    NavDestination(
      path: overview,
      group: NavGroup.operations,
      labelEn: 'Overview',
      labelAr: 'نظرة عامة',
      icon: Icons.dashboard_outlined,
    ),
    NavDestination(
      path: flights,
      group: NavGroup.operations,
      labelEn: 'Flights / Gates',
      labelAr: 'الرحلات / البوابات',
      icon: Icons.flight_takeoff_outlined,
    ),
    NavDestination(
      path: flow,
      group: NavGroup.operations,
      labelEn: 'Passenger Flow & Queues',
      labelAr: 'تدفق الركاب والطوابير',
      icon: Icons.groups_outlined,
    ),
    NavDestination(
      path: baggage,
      group: NavGroup.operations,
      labelEn: 'Smart Baggage',
      labelAr: 'الأمتعة الذكية',
      icon: Icons.luggage_outlined,
    ),
    NavDestination(
      path: maintenance,
      group: NavGroup.operations,
      labelEn: 'Equipment / Maintenance',
      labelAr: 'المعدات / الصيانة',
      icon: Icons.build_outlined,
    ),
    NavDestination(
      path: twin,
      group: NavGroup.monitoring,
      labelEn: 'Digital Twin',
      labelAr: 'التوأم الرقمي',
      icon: Icons.hub_outlined,
    ),
    NavDestination(
      path: incidents,
      group: NavGroup.monitoring,
      labelEn: 'Alerts / Incidents',
      labelAr: 'التنبيهات / الحوادث',
      icon: Icons.notification_important_outlined,
    ),
    NavDestination(
      path: events,
      group: NavGroup.monitoring,
      labelEn: 'Live Events / Automation',
      labelAr: 'الأحداث المباشرة / الأتمتة',
      icon: Icons.bolt_outlined,
    ),
    NavDestination(
      path: predictions,
      group: NavGroup.monitoring,
      labelEn: 'AI Predictions & Recommendations',
      labelAr: 'توقعات وتوصيات الذكاء',
      icon: Icons.auto_graph_outlined,
    ),
    NavDestination(
      path: simulation,
      group: NavGroup.monitoring,
      labelEn: 'Simulation & Replay',
      labelAr: 'المحاكاة وإعادة العرض',
      icon: Icons.science_outlined,
    ),
    NavDestination(
      path: reports,
      group: NavGroup.monitoring,
      labelEn: 'Historical Analytics / Reports',
      labelAr: 'التحليلات والتقارير',
      icon: Icons.assessment_outlined,
    ),
    NavDestination(
      path: staff,
      group: NavGroup.system,
      labelEn: 'Staff / Roles',
      labelAr: 'الموظفون / الأدوار',
      icon: Icons.badge_outlined,
    ),
    NavDestination(
      path: health,
      group: NavGroup.system,
      labelEn: 'System Health',
      labelAr: 'سلامة النظام',
      icon: Icons.monitor_heart_outlined,
    ),
    NavDestination(
      path: settings,
      group: NavGroup.system,
      labelEn: 'Settings',
      labelAr: 'الإعدادات',
      icon: Icons.settings_outlined,
    ),
  ];

  static String? titleForPath(String path, AppStrings s) {
    for (final d in destinations) {
      if (path == d.path || path.startsWith('${d.path}/')) return d.label(s);
    }
    return null;
  }
}

String groupLabel(NavGroup g, AppStrings s) => switch (g) {
  NavGroup.operations => s.tr('OPERATIONS', 'العمليات التشغيلية'),
  NavGroup.monitoring => s.tr('MONITORING & INTELLIGENCE', 'المراقبة والذكاء'),
  NavGroup.system => s.tr('SYSTEM', 'النظام'),
};
