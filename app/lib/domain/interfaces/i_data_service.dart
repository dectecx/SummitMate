import '../../data/models/itinerary_item.dart';
import '../../data/models/message.dart';
import '../../data/models/trip.dart';
import '../../infrastructure/tools/log_service.dart';
import '../../core/error/result.dart';
import '../dto/data_service_result.dart';

/// 資料服務介面 (API Gateway)
/// 提供行程、留言等資料的 CRUD 操作
abstract interface class IDataService {
  /// 取得所有資料 (行程 + 留言)
  ///
  /// [tripId] 指定的行程 ID
  Future<Result<DataServiceResult, Exception>> getAll({String? tripId});

  /// 僅取得行程資料
  ///
  /// [tripId] 指定的行程 ID
  Future<Result<List<ItineraryItem>, Exception>> getItinerary({String? tripId});

  /// 僅取得留言資料
  ///
  /// [tripId] 指定的行程 ID
  Future<Result<List<Message>, Exception>> getMessages({String? tripId});

  /// 新增留言
  ///
  /// [message] 欲新增的留言
  Future<Result<void, Exception>> addMessage(Message message);

  /// 刪除留言
  ///
  /// [uuid] 留言 UUID
  Future<Result<void, Exception>> deleteMessage(String uuid);

  /// 批次新增留言
  ///
  /// [messages] 欲新增的留言列表
  Future<Result<void, Exception>> batchAddMessages(List<Message> messages);

  /// 更新行程 (覆寫雲端)
  ///
  /// [items] 新的行程列表
  Future<Result<void, Exception>> updateItinerary(List<ItineraryItem> items);

  /// 取得雲端行程列表
  Future<Result<List<Trip>, Exception>> getTrips();

  /// 上傳日誌
  ///
  /// [logs] 日誌列表
  /// [deviceName] 裝置名稱 (可選)
  Future<Result<String, Exception>> uploadLogs(List<LogEntry> logs, {String? deviceName});
}
