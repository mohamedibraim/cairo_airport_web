import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../theme/tokens.dart';

enum WebRole {
  dutyOperator,
  maintenanceInventory,
  securityReviewer,
  analystPresenter,
  admin;

  String label(AppStrings s) => switch (this) {
    WebRole.dutyOperator => s.tr('Duty Operator', 'مشغّل الخدمة'),
    WebRole.maintenanceInventory => s.tr(
      'Maintenance / Inventory',
      'الصيانة / المخزون',
    ),
    WebRole.securityReviewer => s.tr('Security Reviewer', 'مراجع الأمن'),
    WebRole.analystPresenter => s.tr('Analyst / Presenter', 'محلل / مقدّم عرض'),
    WebRole.admin => s.tr('Admin', 'مدير النظام'),
  };

  String get code => switch (this) {
    WebRole.dutyOperator => 'DUTY',
    WebRole.maintenanceInventory => 'MAINT',
    WebRole.securityReviewer => 'SEC',
    WebRole.analystPresenter => 'ANALYST',
    WebRole.admin => 'ADMIN',
  };
}

enum SourceKind { device, staff, external, simulator }

extension SourceKindX on SourceKind {
  String label(AppStrings s) => switch (this) {
    SourceKind.device => s.tr('device', 'جهاز'),
    SourceKind.staff => s.tr('staff', 'موظف'),
    SourceKind.external => s.tr('external', 'خارجي'),
    SourceKind.simulator => s.tr('simulator', 'محاكٍ'),
  };
}

enum SourceMode { observed, simulated, replay, unknown }

extension SourceModeX on SourceMode {
  String label(AppStrings s) => switch (this) {
    SourceMode.observed => s.tr('Observed', 'مُرصد'),
    SourceMode.simulated => s.tr('Simulated', 'محاكى'),
    SourceMode.replay => s.tr('Replay', 'إعادة عرض'),
    SourceMode.unknown => s.tr('Unknown', 'غير معروف'),
  };

  Color get color => switch (this) {
    SourceMode.observed => AppColors.success,
    SourceMode.simulated => AppColors.info,
    SourceMode.replay => AppColors.warning,
    SourceMode.unknown => AppColors.unknown,
  };
}

enum Freshness { fresh, stale, unknown, pending }

extension FreshnessX on Freshness {
  String label(AppStrings s) => switch (this) {
    Freshness.fresh => s.tr('Fresh', 'حديث'),
    Freshness.stale => s.tr('Stale', 'قديم'),
    Freshness.unknown => s.tr('Unknown', 'غير معروف'),
    Freshness.pending => s.tr('Pending', 'قيد الانتظار'),
  };

  Color get color => switch (this) {
    Freshness.fresh => AppColors.success,
    Freshness.stale => AppColors.warning,
    Freshness.unknown => AppColors.unknown,
    Freshness.pending => AppColors.info,
  };
}

enum EntityState {
  operational,
  warning,
  fault,
  maintenance,
  unknown,
  pending,
  closed,
}

extension EntityStateX on EntityState {
  String label(AppStrings s) => switch (this) {
    EntityState.operational => s.tr('Operational', 'تشغيلي'),
    EntityState.warning => s.tr('Warning', 'تحذير'),
    EntityState.fault => s.tr('Fault', 'عطل'),
    EntityState.maintenance => s.tr('Under maintenance', 'تحت الصيانة'),
    EntityState.unknown => s.tr('Unknown', 'غير معروف'),
    EntityState.pending => s.tr('Pending', 'قيد الانتظار'),
    EntityState.closed => s.tr('Closed', 'مغلق'),
  };

  Color get color => switch (this) {
    EntityState.operational => AppColors.success,
    EntityState.warning => AppColors.warning,
    EntityState.fault => AppColors.danger,
    EntityState.maintenance => AppColors.info,
    EntityState.unknown => AppColors.unknown,
    EntityState.pending => AppColors.info,
    EntityState.closed => AppColors.muted,
  };
}

enum Severity { low, medium, high, critical }

extension SeverityX on Severity {
  String label(AppStrings s) => switch (this) {
    Severity.low => s.tr('Low', 'منخفضة'),
    Severity.medium => s.tr('Medium', 'متوسطة'),
    Severity.high => s.tr('High', 'عالية'),
    Severity.critical => s.tr('Critical', 'حرجة'),
  };

  Color get color => switch (this) {
    Severity.low => AppColors.success,
    Severity.medium => AppColors.warning,
    Severity.high => AppColors.danger,
    Severity.critical => AppColors.error,
  };
}

enum CaseStatus {
  open,
  assigned,
  inProgress,
  pendingVerification,
  resolved,
  closed,
}

extension CaseStatusX on CaseStatus {
  String label(AppStrings s) => switch (this) {
    CaseStatus.open => s.tr('Open', 'مفتوح'),
    CaseStatus.assigned => s.tr('Assigned', 'مُسند'),
    CaseStatus.inProgress => s.tr('In progress', 'قيد التنفيذ'),
    CaseStatus.pendingVerification => s.tr(
      'Pending verification',
      'بانتظار التحقق',
    ),
    CaseStatus.resolved => s.tr('Resolved', 'تم الحل'),
    CaseStatus.closed => s.tr('Closed', 'مغلق'),
  };

  Color get color => switch (this) {
    CaseStatus.open => AppColors.danger,
    CaseStatus.assigned => AppColors.info,
    CaseStatus.inProgress => AppColors.warning,
    CaseStatus.pendingVerification => AppColors.warning,
    CaseStatus.resolved => AppColors.success,
    CaseStatus.closed => AppColors.muted,
  };
}

enum TwinLayer { flow, baggage, equipment, incidents }

extension TwinLayerX on TwinLayer {
  String label(AppStrings s) => switch (this) {
    TwinLayer.flow => s.tr('Passenger Flow', 'تدفق الركاب'),
    TwinLayer.baggage => s.tr('Baggage', 'الأمتعة'),
    TwinLayer.equipment => s.tr('Equipment', 'المعدات'),
    TwinLayer.incidents => s.tr('Incidents', 'الحوادث'),
  };

  IconData get icon => switch (this) {
    TwinLayer.flow => Icons.people_alt_outlined,
    TwinLayer.baggage => Icons.luggage_outlined,
    TwinLayer.equipment => Icons.precision_manufacturing_outlined,
    TwinLayer.incidents => Icons.warning_amber_rounded,
  };
}

enum Movement { arrival, departure }

extension MovementX on Movement {
  String label(AppStrings s) => switch (this) {
    Movement.arrival => s.tr('Arrival', 'وصول'),
    Movement.departure => s.tr('Departure', 'مغادرة'),
  };
}

enum FlightStatus {
  scheduled,
  boarding,
  delayed,
  departed,
  arrived,
  cancelled,
  unknown,
}

extension FlightStatusX on FlightStatus {
  String label(AppStrings s) => switch (this) {
    FlightStatus.scheduled => s.tr('Scheduled', 'مجدولة'),
    FlightStatus.boarding => s.tr('Boarding', 'جارٍ الصعود'),
    FlightStatus.delayed => s.tr('Delayed', 'متأخرة'),
    FlightStatus.departed => s.tr('Departed', 'غادرت'),
    FlightStatus.arrived => s.tr('Arrived', 'وصلت'),
    FlightStatus.cancelled => s.tr('Cancelled', 'ملغية'),
    FlightStatus.unknown => s.tr('Unknown', 'غير معروفة'),
  };

  Color get color => switch (this) {
    FlightStatus.scheduled => AppColors.info,
    FlightStatus.boarding => AppColors.success,
    FlightStatus.delayed => AppColors.warning,
    FlightStatus.departed => AppColors.muted,
    FlightStatus.arrived => AppColors.success,
    FlightStatus.cancelled => AppColors.danger,
    FlightStatus.unknown => AppColors.unknown,
  };
}

enum EventStatus { committed, rejected, duplicate, retried, suppressed }

extension EventStatusX on EventStatus {
  String label(AppStrings s) => switch (this) {
    EventStatus.committed => s.tr('Committed', 'مُثبّت'),
    EventStatus.rejected => s.tr('Rejected', 'مرفوض'),
    EventStatus.duplicate => s.tr('Duplicate', 'مكرر'),
    EventStatus.retried => s.tr('Retried', 'أُعيد المحاولة'),
    EventStatus.suppressed => s.tr('Suppressed', 'مكبوت'),
  };

  Color get color => switch (this) {
    EventStatus.committed => AppColors.success,
    EventStatus.rejected => AppColors.danger,
    EventStatus.duplicate => AppColors.info,
    EventStatus.retried => AppColors.warning,
    EventStatus.suppressed => AppColors.muted,
  };
}
