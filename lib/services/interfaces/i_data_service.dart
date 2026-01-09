import '../../data/models/itinerary_item.dart';
import '../../data/models/message.dart';
import '../../data/models/trip.dart';
import '../log_service.dart';

/// 通用 API 結果
class ApiResult {
  final bool isSuccess;
  final String? errorMessage;
  final String? message;

  ApiResult({required this.isSuccess, this.errorMessage, this.message});
}

/// getAll 結果
class FetchAllResult extends ApiResult {
  final List<ItineraryItem> itinerary;
  final List<Message> messages;

  FetchAllResult({this.itinerary = const [], this.messages = const [], required super.isSuccess, super.errorMessage});
}

/// getTrips 結果
class FetchTripsResult extends ApiResult {
  final List<Trip> trips;

  FetchTripsResult({this.trips = const [], required super.isSuccess, super.errorMessage});
}

/// 資料服務介面 (API Gateway)
/// 提供行程、留言等資料的 CRUD 操作
abstract interface class IDataService {
  /// 取得所有資料 (行程 + 留言)
  Future<FetchAllResult> getAll({String? tripId});

  /// 僅取得行程資料
  Future<FetchAllResult> getItinerary({String? tripId});

  /// 僅取得留言資料
  Future<FetchAllResult> getMessages({String? tripId});

  /// 新增留言
  Future<ApiResult> addMessage(Message message);

  /// 刪除留言
  Future<ApiResult> deleteMessage(String uuid);

  /// 批次新增留言
  Future<ApiResult> batchAddMessages(List<Message> messages);

  /// 更新行程 (覆寫雲端)
  Future<ApiResult> updateItinerary(List<ItineraryItem> items);

  /// 取得雲端行程列表
  Future<FetchTripsResult> getTrips();

  /// 上傳日誌
  Future<ApiResult> uploadLogs(List<LogEntry> logs, {String? deviceName});
}
