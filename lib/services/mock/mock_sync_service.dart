import 'package:summitmate/services/sync_service.dart';
import '../google_sheets_service.dart';

class MockSyncService extends SyncService {
  MockSyncService({
    required super.sheetsService,
    required super.tripRepo,
    required super.itineraryRepo,
    required super.messageRepo,
    required super.connectivity,
  });

  // Override to prevent real sync calls
  @override
  Future<SyncResult> syncAll({bool isAuto = false}) async {
    return SyncResult(isSuccess: true, syncedAt: DateTime.now());
  }

  @override
  Future<SyncResult> syncItinerary({bool isAuto = false}) async {
    return SyncResult(isSuccess: true, itinerarySynced: true, syncedAt: DateTime.now());
  }

  @override
  Future<SyncResult> syncMessages({bool isAuto = false}) async {
    return SyncResult(isSuccess: true, messagesSynced: true, syncedAt: DateTime.now());
  }

  @override
  Future<FetchTripsResult> fetchCloudTrips() async {
    return FetchTripsResult(isSuccess: true, trips: []);
  }

  @override
  Future<bool> checkItineraryConflict() async => false;

  @override
  Future<ApiResult> uploadItinerary() async => ApiResult(isSuccess: true);
}
