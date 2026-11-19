import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/fixtures.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../l10n/strings.dart';

const _en = AppStrings(arabic: false);
const _ar = AppStrings(arabic: true);

class AuditEntry {
  final String id;
  final DateTime at;
  final String actorEn;
  final String actorAr;
  final String actionEn;
  final String actionAr;
  final String target;
  const AuditEntry({
    required this.id,
    required this.at,
    required this.actorEn,
    required this.actorAr,
    required this.actionEn,
    required this.actionAr,
    required this.target,
  });
}

class OpsState {
  final Map<String, CaseStatus> recommendationDecisions;
  final Map<String, CaseStatus> alertStatuses;
  final Map<String, String> alertAssignees;
  final Map<String, CaseStatus> workOrderStatuses;
  final Map<String, String> workOrderAssignees;
  final Set<String> acknowledgedBags;
  final Set<String> restockRequests;
  final Set<String> disabledAutomation;
  final Set<String> pinnedReports;
  final List<AuditEntry> audit;

  const OpsState({
    this.recommendationDecisions = const {},
    this.alertStatuses = const {},
    this.alertAssignees = const {},
    this.workOrderStatuses = const {},
    this.workOrderAssignees = const {},
    this.acknowledgedBags = const {},
    this.restockRequests = const {},
    this.disabledAutomation = const {},
    this.pinnedReports = const {},
    this.audit = const [],
  });

  CaseStatus workOrderStatus(WorkOrder o) =>
      workOrderStatuses[o.id] ?? o.status;
  String workOrderAssignee(WorkOrder o) =>
      workOrderAssignees[o.id] ?? o.assigneeEn;
  CaseStatus alertStatus(OpsAlert a) => alertStatuses[a.id] ?? a.status;
  String? alertAssignee(OpsAlert a) => alertAssignees[a.id];
  CaseStatus recommendationDecision(Recommendation r) =>
      recommendationDecisions[r.id] ?? r.decision;
  bool bagAcknowledged(String id) => acknowledgedBags.contains(id);
  bool restockRequested(String id) => restockRequests.contains(id);
  bool automationEnabled(String id) => !disabledAutomation.contains(id);
  bool reportPinned(String id) => pinnedReports.contains(id);
}

class OpsNotifier extends StateNotifier<OpsState> {
  OpsNotifier() : super(const OpsState());

  void _audit({
    required DemoUser? user,
    required String actionEn,
    required String actionAr,
    required String target,
  }) {
    final entry = AuditEntry(
      id: 'AUD-${(state.audit.length + 1).toString().padLeft(3, '0')}',
      at: Fixtures.reference.add(Duration(minutes: state.audit.length + 1)),
      actorEn: user?.nameEn ?? 'Demo operator',
      actorAr: user?.nameAr ?? 'مشغّل تجريبي',
      actionEn: actionEn,
      actionAr: actionAr,
      target: target,
    );
    state = OpsState(
      recommendationDecisions: state.recommendationDecisions,
      alertStatuses: state.alertStatuses,
      alertAssignees: state.alertAssignees,
      workOrderStatuses: state.workOrderStatuses,
      workOrderAssignees: state.workOrderAssignees,
      acknowledgedBags: state.acknowledgedBags,
      restockRequests: state.restockRequests,
      disabledAutomation: state.disabledAutomation,
      pinnedReports: state.pinnedReports,
      audit: [entry, ...state.audit],
    );
  }

  void decideRecommendation(
    Recommendation r,
    CaseStatus decision,
    DemoUser? user,
  ) {
    state = OpsState(
      recommendationDecisions: {
        ...state.recommendationDecisions,
        r.id: decision,
      },
      alertStatuses: state.alertStatuses,
      alertAssignees: state.alertAssignees,
      workOrderStatuses: state.workOrderStatuses,
      workOrderAssignees: state.workOrderAssignees,
      acknowledgedBags: state.acknowledgedBags,
      restockRequests: state.restockRequests,
      disabledAutomation: state.disabledAutomation,
      pinnedReports: state.pinnedReports,
      audit: state.audit,
    );
    _audit(
      user: user,
      actionEn: 'Recommendation ${decision.label(_en)}',
      actionAr: 'قرار توصية: ${decision.label(_ar)}',
      target: r.id,
    );
  }

  void setAlertStatus(OpsAlert a, CaseStatus status, DemoUser? user) {
    state = OpsState(
      recommendationDecisions: state.recommendationDecisions,
      alertStatuses: {...state.alertStatuses, a.id: status},
      alertAssignees: state.alertAssignees,
      workOrderStatuses: state.workOrderStatuses,
      workOrderAssignees: state.workOrderAssignees,
      acknowledgedBags: state.acknowledgedBags,
      restockRequests: state.restockRequests,
      disabledAutomation: state.disabledAutomation,
      pinnedReports: state.pinnedReports,
      audit: state.audit,
    );
    _audit(
      user: user,
      actionEn: 'Alert status set to ${status.label(_en)}',
      actionAr: 'تحديث حالة التنبيه إلى ${status.label(_ar)}',
      target: a.id,
    );
  }

  void assignAlert(
    OpsAlert a,
    String assigneeEn,
    String assigneeAr,
    DemoUser? user,
  ) {
    state = OpsState(
      recommendationDecisions: state.recommendationDecisions,
      alertStatuses: {...state.alertStatuses, a.id: CaseStatus.assigned},
      alertAssignees: {...state.alertAssignees, a.id: assigneeEn},
      workOrderStatuses: state.workOrderStatuses,
      workOrderAssignees: state.workOrderAssignees,
      acknowledgedBags: state.acknowledgedBags,
      restockRequests: state.restockRequests,
      disabledAutomation: state.disabledAutomation,
      pinnedReports: state.pinnedReports,
      audit: state.audit,
    );
    _audit(
      user: user,
      actionEn: 'Alert assigned to $assigneeEn',
      actionAr: 'إسناد التنبيه إلى $assigneeAr',
      target: a.id,
    );
  }

  void setWorkOrderStatus(WorkOrder o, CaseStatus status, DemoUser? user) {
    state = OpsState(
      recommendationDecisions: state.recommendationDecisions,
      alertStatuses: state.alertStatuses,
      alertAssignees: state.alertAssignees,
      workOrderStatuses: {...state.workOrderStatuses, o.id: status},
      workOrderAssignees: state.workOrderAssignees,
      acknowledgedBags: state.acknowledgedBags,
      restockRequests: state.restockRequests,
      disabledAutomation: state.disabledAutomation,
      pinnedReports: state.pinnedReports,
      audit: state.audit,
    );
    _audit(
      user: user,
      actionEn: 'Work order moved to ${status.label(_en)}',
      actionAr: 'نقل أمر العمل إلى ${status.label(_ar)}',
      target: o.id,
    );
  }

  void assignWorkOrder(
    WorkOrder o,
    String assigneeEn,
    String assigneeAr,
    DemoUser? user,
  ) {
    state = OpsState(
      recommendationDecisions: state.recommendationDecisions,
      alertStatuses: state.alertStatuses,
      alertAssignees: state.alertAssignees,
      workOrderStatuses: {
        ...state.workOrderStatuses,
        o.id: CaseStatus.assigned,
      },
      workOrderAssignees: {...state.workOrderAssignees, o.id: assigneeEn},
      acknowledgedBags: state.acknowledgedBags,
      restockRequests: state.restockRequests,
      disabledAutomation: state.disabledAutomation,
      pinnedReports: state.pinnedReports,
      audit: state.audit,
    );
    _audit(
      user: user,
      actionEn: 'Work order assigned to $assigneeEn',
      actionAr: 'إسناد أمر العمل إلى $assigneeAr',
      target: o.id,
    );
  }

  void acknowledgeBag(BagCase bag, DemoUser? user) {
    state = OpsState(
      recommendationDecisions: state.recommendationDecisions,
      alertStatuses: state.alertStatuses,
      alertAssignees: state.alertAssignees,
      workOrderStatuses: state.workOrderStatuses,
      workOrderAssignees: state.workOrderAssignees,
      acknowledgedBags: {...state.acknowledgedBags, bag.id},
      restockRequests: state.restockRequests,
      disabledAutomation: state.disabledAutomation,
      pinnedReports: state.pinnedReports,
      audit: state.audit,
    );
    _audit(
      user: user,
      actionEn: 'Bag tracing acknowledged',
      actionAr: 'الإقرار بتتبع الحقيبة',
      target: bag.id,
    );
  }

  void requestRestock(PartStock part, DemoUser? user) {
    state = OpsState(
      recommendationDecisions: state.recommendationDecisions,
      alertStatuses: state.alertStatuses,
      alertAssignees: state.alertAssignees,
      workOrderStatuses: state.workOrderStatuses,
      workOrderAssignees: state.workOrderAssignees,
      acknowledgedBags: state.acknowledgedBags,
      restockRequests: {...state.restockRequests, part.id},
      disabledAutomation: state.disabledAutomation,
      pinnedReports: state.pinnedReports,
      audit: state.audit,
    );
    _audit(
      user: user,
      actionEn: 'Restock request queued (no purchase)',
      actionAr: 'إدراج طلب إعادة تخزين (بدون شراء)',
      target: part.id,
    );
  }

  void assignSecurityIncident(
    SecurityIncident incident,
    String assigneeEn,
    String assigneeAr,
    DemoUser? user,
  ) {
    state = OpsState(
      recommendationDecisions: state.recommendationDecisions,
      alertStatuses: {...state.alertStatuses, incident.id: CaseStatus.assigned},
      alertAssignees: {...state.alertAssignees, incident.id: assigneeEn},
      workOrderStatuses: state.workOrderStatuses,
      workOrderAssignees: state.workOrderAssignees,
      acknowledgedBags: state.acknowledgedBags,
      restockRequests: state.restockRequests,
      disabledAutomation: state.disabledAutomation,
      pinnedReports: state.pinnedReports,
      audit: state.audit,
    );
    _audit(
      user: user,
      actionEn: 'Security incident assigned to $assigneeEn',
      actionAr: 'إسناد الحادث الأمني إلى $assigneeAr',
      target: incident.id,
    );
  }

  void setSecurityStatus(
    SecurityIncident incident,
    CaseStatus status,
    DemoUser? user,
  ) {
    state = OpsState(
      recommendationDecisions: state.recommendationDecisions,
      alertStatuses: {...state.alertStatuses, incident.id: status},
      alertAssignees: state.alertAssignees,
      workOrderStatuses: state.workOrderStatuses,
      workOrderAssignees: state.workOrderAssignees,
      acknowledgedBags: state.acknowledgedBags,
      restockRequests: state.restockRequests,
      disabledAutomation: state.disabledAutomation,
      pinnedReports: state.pinnedReports,
      audit: state.audit,
    );
    _audit(
      user: user,
      actionEn: 'Security incident set to ${status.label(_en)}',
      actionAr: 'تحديث الحادث الأمني إلى ${status.label(_ar)}',
      target: incident.id,
    );
  }

  void toggleAutomation(String id, bool enabled, DemoUser? user) {
    state = OpsState(
      recommendationDecisions: state.recommendationDecisions,
      alertStatuses: state.alertStatuses,
      alertAssignees: state.alertAssignees,
      workOrderStatuses: state.workOrderStatuses,
      workOrderAssignees: state.workOrderAssignees,
      acknowledgedBags: state.acknowledgedBags,
      restockRequests: state.restockRequests,
      disabledAutomation: enabled
          ? (state.disabledAutomation.where((e) => e != id).toSet())
          : {...state.disabledAutomation, id},
      pinnedReports: state.pinnedReports,
      audit: state.audit,
    );
    _audit(
      user: user,
      actionEn: enabled ? 'Automation enabled' : 'Automation disabled',
      actionAr: enabled ? 'تم تمكين الأتمتة' : 'تم تعطيل الأتمتة',
      target: id,
    );
  }

  /// Clears all demo-only decisions and restarts the audit trail. Used by the
  /// Settings screen; it never touches real data because none is connected.
  void resetAll(DemoUser? user) {
    state = const OpsState();
    _audit(
      user: user,
      actionEn: 'Demo decisions reset',
      actionAr: 'إعادة تعيين قرارات العرض',
      target: 'SESSION',
    );
  }

  void toggleReportPin(String id, DemoUser? user) {
    final pinned = state.pinnedReports.contains(id);
    state = OpsState(
      recommendationDecisions: state.recommendationDecisions,
      alertStatuses: state.alertStatuses,
      alertAssignees: state.alertAssignees,
      workOrderStatuses: state.workOrderStatuses,
      workOrderAssignees: state.workOrderAssignees,
      acknowledgedBags: state.acknowledgedBags,
      restockRequests: state.restockRequests,
      disabledAutomation: state.disabledAutomation,
      pinnedReports: pinned
          ? (state.pinnedReports.where((e) => e != id).toSet())
          : {...state.pinnedReports, id},
      audit: state.audit,
    );
    _audit(
      user: user,
      actionEn: pinned ? 'Report unpinned' : 'Report pinned',
      actionAr: pinned ? 'إلغاء تثبيت التقرير' : 'تثبيت التقرير',
      target: id,
    );
  }
}

final opsProvider = StateNotifierProvider<OpsNotifier, OpsState>(
  (ref) => OpsNotifier(),
);

/// Role capability matrix used by Staff/Roles and to gate write actions in the
/// demo. This is presentation-only enforcement, not a security boundary.
abstract final class Capability {
  static const viewOps = 'ops.view';
  static const acknowledgeAlerts = 'alerts.ack';
  static const assignWorkOrders = 'orders.assign';
  static const manageBaggage = 'baggage.manage';
  static const manageInventory = 'inventory.manage';
  static const reviewIncidents = 'security.review';
  static const runScenarios = 'scenarios.run';
  static const exportReports = 'reports.export';
  static const manageUsers = 'users.manage';
  static const manageSettings = 'settings.manage';
  static const viewSensitive = 'security.view';

  static const all = <String>[
    viewOps,
    acknowledgeAlerts,
    assignWorkOrders,
    manageBaggage,
    manageInventory,
    reviewIncidents,
    runScenarios,
    exportReports,
    manageUsers,
    manageSettings,
    viewSensitive,
  ];

  static bool allows(WebRole role, String capability) {
    return switch (role) {
      WebRole.dutyOperator => {
        viewOps,
        acknowledgeAlerts,
        manageBaggage,
        assignWorkOrders,
        exportReports,
      }.contains(capability),
      WebRole.maintenanceInventory => {
        viewOps,
        assignWorkOrders,
        manageInventory,
        acknowledgeAlerts,
        exportReports,
      }.contains(capability),
      WebRole.securityReviewer => {
        viewOps,
        acknowledgeAlerts,
        reviewIncidents,
        viewSensitive,
        exportReports,
      }.contains(capability),
      WebRole.analystPresenter => {
        viewOps,
        runScenarios,
        exportReports,
        acknowledgeAlerts,
      }.contains(capability),
      WebRole.admin => true,
    };
  }

  static String label(String capability, bool arabic) {
    return switch (capability) {
      viewOps => arabic ? 'عرض العمليات' : 'View operations',
      acknowledgeAlerts => arabic ? 'الإقرار بالتنبيهات' : 'Acknowledge alerts',
      assignWorkOrders => arabic ? 'إسناد أوامر العمل' : 'Assign work orders',
      manageBaggage => arabic ? 'إدارة الأمتعة' : 'Manage baggage cases',
      manageInventory => arabic ? 'إدارة المخزون' : 'Manage inventory',
      reviewIncidents =>
        arabic ? 'مراجعة الحوادث الأمنية' : 'Review security incidents',
      runScenarios => arabic ? 'تشغيل المحاكاة' : 'Run scenarios',
      exportReports => arabic ? 'تصدير التقارير' : 'Export reports',
      manageUsers => arabic ? 'إدارة المستخدمين' : 'Manage users',
      manageSettings => arabic ? 'إدارة الإعدادات' : 'Manage settings',
      viewSensitive => arabic ? 'عرض البيانات الحساسة' : 'View sensitive data',
      _ => capability,
    };
  }
}
