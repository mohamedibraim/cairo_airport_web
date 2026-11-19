import 'enums.dart';

/// Provenance attached to every displayed value (blueprint §8, §18).
class SourceMeta {
  final String sourceId;
  final SourceKind kind;
  final SourceMode mode;
  final DateTime observedAt;
  final Freshness freshness;
  final String streamId;
  final String? correlationId;
  final int? version;

  const SourceMeta({
    required this.sourceId,
    this.kind = SourceKind.simulator,
    this.mode = SourceMode.simulated,
    required this.observedAt,
    this.freshness = Freshness.fresh,
    this.streamId = 'demo-main',
    this.correlationId,
    this.version,
  });

  bool get simulated => mode == SourceMode.simulated;
}

class MetricValue {
  final String labelEn;
  final String labelAr;
  final String value;
  final String unitEn;
  final String unitAr;
  final DateTime asOf;
  final SourceMeta source;

  const MetricValue({
    required this.labelEn,
    required this.labelAr,
    required this.value,
    this.unitEn = '',
    this.unitAr = '',
    required this.asOf,
    required this.source,
  });
}

class EventRecord {
  final String eventId;
  final String type;
  final String entityId;
  final String entityType;
  final String summaryEn;
  final String summaryAr;
  final DateTime observedAt;
  final DateTime? receivedAt;
  final SourceMeta source;
  final EventStatus status;
  final Severity severity;
  final String? correlationId;
  final String? causationId;
  final String? actor;
  final String? outcomeEn;
  final String? outcomeAr;

  const EventRecord({
    required this.eventId,
    required this.type,
    required this.entityId,
    required this.entityType,
    required this.summaryEn,
    required this.summaryAr,
    required this.observedAt,
    this.receivedAt,
    required this.source,
    this.status = EventStatus.committed,
    this.severity = Severity.low,
    this.correlationId,
    this.causationId,
    this.actor,
    this.outcomeEn,
    this.outcomeAr,
  });
}

/// A selectable object on the 2D schematic: a zone, queue, asset or bag node.
class TwinEntity {
  final String id;
  final String typeEn;
  final String typeAr;
  final String nameEn;
  final String nameAr;
  final TwinLayer layer;
  final bool isZone;
  final double x;
  final double y;
  final double w;
  final double h;
  final EntityState state;
  final String statusEn;
  final String statusAr;
  final SourceMeta source;
  final String? latestEventEn;
  final String? latestEventAr;
  final List<MetricValue> metrics;
  final List<EventRecord> history;

  const TwinEntity({
    required this.id,
    required this.typeEn,
    required this.typeAr,
    required this.nameEn,
    required this.nameAr,
    required this.layer,
    this.isZone = false,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.state,
    required this.statusEn,
    required this.statusAr,
    required this.source,
    this.latestEventEn,
    this.latestEventAr,
    this.metrics = const [],
    this.history = const [],
  });
}

class FlightLeg {
  final String id;
  final String flightNo;
  final String carrierEn;
  final String carrierAr;
  final String origin;
  final String destination;
  final String originCityEn;
  final String originCityAr;
  final String destinationCityEn;
  final String destinationCityAr;
  final Movement movement;
  final DateTime serviceDate;
  final DateTime? scheduled;
  final DateTime? estimated;
  final DateTime? actual;
  final FlightStatus status;
  final String terminal;
  final String gate;
  final bool gateConflict;
  final int gateOccupancyPct;
  final int checkedIn;
  final int expectedPax;
  final SourceMeta source;
  final String zoneId;
  final List<EventRecord> timeline;

  const FlightLeg({
    required this.id,
    required this.flightNo,
    required this.carrierEn,
    required this.carrierAr,
    required this.origin,
    required this.destination,
    required this.originCityEn,
    required this.originCityAr,
    required this.destinationCityEn,
    required this.destinationCityAr,
    required this.movement,
    required this.serviceDate,
    this.scheduled,
    this.estimated,
    this.actual,
    required this.status,
    required this.terminal,
    required this.gate,
    this.gateConflict = false,
    required this.gateOccupancyPct,
    required this.checkedIn,
    required this.expectedPax,
    required this.source,
    required this.zoneId,
    this.timeline = const [],
  });
}

class SeriesPoint {
  final double x;
  final double y;
  const SeriesPoint(this.x, this.y);
}

class FlowSeries {
  final String labelEn;
  final String labelAr;
  final List<SeriesPoint> points;
  final bool dashed;
  final bool band;

  const FlowSeries({
    required this.labelEn,
    required this.labelAr,
    required this.points,
    this.dashed = false,
    this.band = false,
  });
}

class QueueStation {
  final String id;
  final String nameEn;
  final String nameAr;
  final String zoneId;
  final int count;
  final int lanes;
  final int throughputPerHour;
  final int waitLow;
  final int waitHigh;
  final SourceMeta source;
  final DateTime forecastCutoff;
  final String domainEn;
  final String domainAr;
  final List<FlowSeries> throughputSeries;
  final List<FlowSeries> waitSeries;
  final List<EventRecord> evidence;

  const QueueStation({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.zoneId,
    required this.count,
    required this.lanes,
    required this.throughputPerHour,
    required this.waitLow,
    required this.waitHigh,
    required this.source,
    required this.forecastCutoff,
    required this.domainEn,
    required this.domainAr,
    required this.throughputSeries,
    required this.waitSeries,
    this.evidence = const [],
  });

  String get waitBand => '$waitLow–$waitHigh';
}

class BagStage {
  final String stageEn;
  final String stageAr;
  final String readerEn;
  final String readerAr;
  final DateTime? at;
  final bool confirmed;
  final bool expected;

  const BagStage({
    required this.stageEn,
    required this.stageAr,
    required this.readerEn,
    required this.readerAr,
    this.at,
    this.confirmed = false,
    this.expected = false,
  });
}

class BagCase {
  final String id;
  final String tagRef;
  final String flightNo;
  final String caseRef;
  final String stageEn;
  final String stageAr;
  final DateTime lastScanAt;
  final CaseStatus status;
  final Severity severity;
  final String ownerEn;
  final String ownerAr;
  final String zoneId;
  final SourceMeta source;
  final String? reasonEn;
  final String? reasonAr;
  final List<BagStage> stages;
  final List<EventRecord> timeline;

  const BagCase({
    required this.id,
    required this.tagRef,
    required this.flightNo,
    required this.caseRef,
    required this.stageEn,
    required this.stageAr,
    required this.lastScanAt,
    required this.status,
    required this.severity,
    required this.ownerEn,
    required this.ownerAr,
    required this.zoneId,
    required this.source,
    this.reasonEn,
    this.reasonAr,
    this.stages = const [],
    this.timeline = const [],
  });
}

class AssetRecord {
  final String id;
  final String nameEn;
  final String nameAr;
  final String typeEn;
  final String typeAr;
  final String zoneId;
  final String serial;
  final String? replacesId;
  final List<String> sensorIds;
  final EntityState state;
  final int healthScore;
  final SourceMeta source;
  final List<MetricValue> readings;
  final List<EventRecord> history;
  final String? activeOrderId;

  const AssetRecord({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.typeEn,
    required this.typeAr,
    required this.zoneId,
    required this.serial,
    this.replacesId,
    required this.sensorIds,
    required this.state,
    required this.healthScore,
    required this.source,
    this.readings = const [],
    this.history = const [],
    this.activeOrderId,
  });
}

class WorkOrder {
  final String id;
  final String assetId;
  final String titleEn;
  final String titleAr;
  final CaseStatus status;
  final Severity severity;
  final String assigneeEn;
  final String assigneeAr;
  final DateTime createdAt;
  final int version;
  final SourceMeta source;
  final List<EventRecord> timeline;

  const WorkOrder({
    required this.id,
    required this.assetId,
    required this.titleEn,
    required this.titleAr,
    required this.status,
    required this.severity,
    required this.assigneeEn,
    required this.assigneeAr,
    required this.createdAt,
    required this.version,
    required this.source,
    this.timeline = const [],
  });
}

class PartStock {
  final String id;
  final String nameEn;
  final String nameAr;
  final String unit;
  final int balance;
  final int reorderPoint;
  final String location;
  final SourceMeta source;

  const PartStock({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.unit,
    required this.balance,
    required this.reorderPoint,
    required this.location,
    required this.source,
  });
}

class OpsAlert {
  final String id;
  final String moduleEn;
  final String moduleAr;
  final String titleEn;
  final String titleAr;
  final String detailEn;
  final String detailAr;
  final Severity severity;
  final CaseStatus status;
  final DateTime createdAt;
  final String entityId;
  final SourceMeta source;

  const OpsAlert({
    required this.id,
    required this.moduleEn,
    required this.moduleAr,
    required this.titleEn,
    required this.titleAr,
    required this.detailEn,
    required this.detailAr,
    required this.severity,
    required this.status,
    required this.createdAt,
    required this.entityId,
    required this.source,
  });
}

class SecurityIncident {
  final String id;
  final String summaryEn;
  final String summaryAr;
  final String zoneId;
  final Severity severity;
  final String classificationEn;
  final String classificationAr;
  final CaseStatus status;
  final String assigneeEn;
  final String assigneeAr;
  final DateTime detectedAt;
  final SourceMeta source;
  final List<EventRecord> timeline;

  const SecurityIncident({
    required this.id,
    required this.summaryEn,
    required this.summaryAr,
    required this.zoneId,
    required this.severity,
    required this.classificationEn,
    required this.classificationAr,
    required this.status,
    required this.assigneeEn,
    required this.assigneeAr,
    required this.detectedAt,
    required this.source,
    this.timeline = const [],
  });
}

class Prediction {
  final String id;
  final String modelEn;
  final String modelAr;
  final String version;
  final String targetEn;
  final String targetAr;
  final String value;
  final String unitEn;
  final String unitAr;
  final String interval;
  final String baseline;
  final DateTime cutoff;
  final Duration horizon;
  final String domainEn;
  final String domainAr;
  final String metricSummary;
  final SourceMeta source;

  const Prediction({
    required this.id,
    required this.modelEn,
    required this.modelAr,
    required this.version,
    required this.targetEn,
    required this.targetAr,
    required this.value,
    required this.unitEn,
    required this.unitAr,
    required this.interval,
    required this.baseline,
    required this.cutoff,
    required this.horizon,
    required this.domainEn,
    required this.domainAr,
    required this.metricSummary,
    required this.source,
  });
}

class Recommendation {
  final String id;
  final String titleEn;
  final String titleAr;
  final String problemEn;
  final String problemAr;
  final String actionEn;
  final String actionAr;
  final String expectedEn;
  final String expectedAr;
  final Severity severity;
  final String predictionId;
  final String entityId;
  final DateTime createdAt;
  final CaseStatus decision;

  const Recommendation({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.problemEn,
    required this.problemAr,
    required this.actionEn,
    required this.actionAr,
    required this.expectedEn,
    required this.expectedAr,
    required this.severity,
    required this.predictionId,
    required this.entityId,
    required this.createdAt,
    this.decision = CaseStatus.open,
  });
}

class AutomationRun {
  final String id;
  final String ruleEn;
  final String ruleAr;
  final String triggerEn;
  final String triggerAr;
  final String statusEn;
  final String statusAr;
  final DateTime at;
  final String actor;
  final String? correlationId;

  const AutomationRun({
    required this.id,
    required this.ruleEn,
    required this.ruleAr,
    required this.triggerEn,
    required this.triggerAr,
    required this.statusEn,
    required this.statusAr,
    required this.at,
    required this.actor,
    this.correlationId,
  });
}

class ScenarioMetric {
  final String nameEn;
  final String nameAr;
  final String baseline;
  final String alternative;
  final String delta;
  final String unitEn;
  final String unitAr;

  const ScenarioMetric({
    required this.nameEn,
    required this.nameAr,
    required this.baseline,
    required this.alternative,
    required this.delta,
    required this.unitEn,
    required this.unitAr,
  });
}

class ScenarioRun {
  final String id;
  final String nameEn;
  final String nameAr;
  final String baselineId;
  final String alternativeId;
  final String seed;
  final String simulatorVersion;
  final DateTime forkAt;
  final String statusEn;
  final String statusAr;
  final List<ScenarioMetric> metrics;
  final List<FlowSeries> comparison;

  const ScenarioRun({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.baselineId,
    required this.alternativeId,
    required this.seed,
    required this.simulatorVersion,
    required this.forkAt,
    required this.statusEn,
    required this.statusAr,
    required this.metrics,
    required this.comparison,
  });
}

class HealthCheck {
  final String id;
  final String nameEn;
  final String nameAr;
  final String kindEn;
  final String kindAr;
  final String statusEn;
  final String statusAr;
  final int? lagSeconds;
  final int? rejectCount;
  final DateTime lastSuccess;
  final Freshness freshness;

  const HealthCheck({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.kindEn,
    required this.kindAr,
    required this.statusEn,
    required this.statusAr,
    this.lagSeconds,
    this.rejectCount,
    required this.lastSuccess,
    required this.freshness,
  });
}

class StaffMember {
  final String id;
  final String nameEn;
  final String nameAr;
  final WebRole role;
  final String terminal;
  final String shiftEn;
  final String shiftAr;
  final bool available;
  final String? skills;

  const StaffMember({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.role,
    required this.terminal,
    required this.shiftEn,
    required this.shiftAr,
    required this.available,
    this.skills,
  });
}

/// A KPI tile with value, unit, as-of, source mode, freshness and a drill-down.
class KpiTile {
  final String id;
  final String labelEn;
  final String labelAr;
  final String value;
  final String unitEn;
  final String unitAr;
  final String? contextEn;
  final String? contextAr;
  final DateTime asOf;
  final SourceMeta source;
  final String destination;
  final Map<String, String> query;

  const KpiTile({
    required this.id,
    required this.labelEn,
    required this.labelAr,
    required this.value,
    this.unitEn = '',
    this.unitAr = '',
    this.contextEn,
    this.contextAr,
    required this.asOf,
    required this.source,
    required this.destination,
    this.query = const {},
  });
}

class DemoUser {
  final String id;
  final String nameEn;
  final String nameAr;
  final WebRole role;
  final String terminal;

  const DemoUser({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.role,
    required this.terminal,
  });
}
