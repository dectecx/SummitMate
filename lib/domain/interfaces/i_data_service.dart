import '../../data/models/itinerary_item.dart';
import '../../data/models/message.dart';
import '../../data/models/trip.dart';
import '../../infrastructure/tools/log_service.dart';

/// 通用 API 結果
class ApiResult {
  final bool isSuccess;
  final String? errorMessage;
  final String? message;

  /// 建構子
  ///
  /// [isSuccess] 是否成功
  /// [errorMessage] 錯誤訊息
  /// [message] 一般訊息
  ApiResult({required this.isSuccess, this.errorMessage, this.message});

  /// 建立成功結果
  factory ApiResult.success({String? message}) => ApiResult(isSuccess: true, message: message);

  /// 建立失敗結果
  factory ApiResult.failure(String errorMessage) => ApiResult(isSuccess: false, errorMessage: errorMessage);
}

/// getAll 結果
class GetAllResult extends ApiResult {
  final List<ItineraryItem> itinerary;
  final List<Message> messages;

  GetAllResult({this.itinerary = const [], this.messages = const [], required super.isSuccess, super.errorMessage});
}

/// getTrips 結果
class GetTripsResult extends ApiResult {
  final List<Trip> trips;

  GetTripsResult({this.trips = const [], required super.isSuccess, super.errorMessage});
}

/// 資料服務介面 (API Gateway)
/// 提供行程、留言等資料的 CRUD 操作
abstract interface class IDataService {
  /// 取得所有資料 (行程 + 留言)
  ///
  /// [tripId] 指定的行程 ID
  Future<GetAllResult> getAll({String? tripId});

  /// 僅取得行程資料
  ///
  /// [tripId] 指定的行程 ID
  Future<GetAllResult> getItinerary({String? tripId});

  /// 僅取得留言資料
  ///
  /// [tripId] 指定的行程 ID
  Future<GetAllResult> getMessages({String? tripId});

  /// 新增留言
  ///
  /// [message] 欲新增的留言
  Future<ApiResult> addMessage(Message message);

  /// 刪除留言
  ///
  /// [uuid] 留言 UUID
  Future<ApiResult> deleteMessage(String uuid);

  /// 批次新增留言
  ///
  /// [messages] 欲新增的留言列表
  Future<ApiResult> batchAddMessages(List<Message> messages);

  /// 更新行程 (覆寫雲端)
  ///
  /// [items] 新的行程列表
  Future<ApiResult> updateItinerary(List<ItineraryItem> items);

  /// 取得雲端行程列表
  Future<GetTripsResult> getTrips();

  /// 上傳日誌
  ///
  /// [logs] 日誌列表
  /// [deviceName] 裝置名稱 (可選)
  Future<ApiResult> uploadLogs(List<LogEntry> logs, {String? deviceName});
}
