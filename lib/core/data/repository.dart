import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models.dart';
import 'fixtures.dart';

/// Frontend contract mirroring the Blueprint API groups A1–A8 (§10).
///
/// The current implementation is [FixtureTwinRepository]. A future
/// `HttpTwinRepository` can implement the same methods against FastAPI `/v1`
/// without changing a single widget: every screen reads through these methods
/// and every record already carries source mode, as-of time and freshness.
abstract class TwinRepository {
  // A1 · Session
  List<DemoUser> get demoUsers;
  // A2 · Flights and gates
  List<FlightLeg> get flights;
  // A3 · Baggage
  List<BagCase> get bagCases;
  // A4 · Twin, flow and maps
  List<TwinEntity> get twinEntities;
  List<QueueStation> get stations;
  // A5 · Maintenance
  List<AssetRecord> get assets;
  List<WorkOrder> get workOrders;
  List<PartStock> get parts;
  // A6 · Ingestion and history
  List<EventRecord> get events;
  // A7 · Decisions and scenarios
  List<OpsAlert> get incidents;
  List<SecurityIncident> get securityIncidents;
  List<Prediction> get predictions;
  List<Recommendation> get recommendations;
  List<AutomationRun> get automationRuns;
  List<ScenarioRun> get scenarios;
  // A8 · Delivery and admin
  List<StaffMember> get staff;
  List<HealthCheck> get health;
  List<KpiTile> get overviewKpis;
}

/// Fixture-backed implementation. All values are fictional and explicitly
/// labelled in the UI as observed, simulated, replay or unknown.
class FixtureTwinRepository implements TwinRepository {
  const FixtureTwinRepository();

  @override
  List<DemoUser> get demoUsers => Fixtures.demoUsers;
  @override
  List<FlightLeg> get flights => Fixtures.flights;
  @override
  List<BagCase> get bagCases => Fixtures.bagCases;
  @override
  List<TwinEntity> get twinEntities => Fixtures.twinEntities;
  @override
  List<QueueStation> get stations => Fixtures.stations;
  @override
  List<AssetRecord> get assets => Fixtures.assets;
  @override
  List<WorkOrder> get workOrders => Fixtures.workOrders;
  @override
  List<PartStock> get parts => Fixtures.parts;
  @override
  List<EventRecord> get events => Fixtures.events;
  @override
  List<OpsAlert> get incidents => Fixtures.alerts;
  @override
  List<SecurityIncident> get securityIncidents => Fixtures.securityIncidents;
  @override
  List<Prediction> get predictions => Fixtures.predictions;
  @override
  List<Recommendation> get recommendations => Fixtures.recommendations;
  @override
  List<AutomationRun> get automationRuns => Fixtures.automationRuns;
  @override
  List<ScenarioRun> get scenarios => Fixtures.scenarios;
  @override
  List<StaffMember> get staff => Fixtures.staff;
  @override
  List<HealthCheck> get health => Fixtures.health;
  @override
  List<KpiTile> get overviewKpis => Fixtures.overviewKpis;
}

final repositoryProvider = Provider<TwinRepository>((ref) {
  // Swap this single line for an HTTP implementation when FastAPI is ready.
  return const FixtureTwinRepository();
});
